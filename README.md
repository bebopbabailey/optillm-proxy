# OptiLLM Proxy — Overview & Usage

## What this service is

**OptiLLM** is an **OpenAI API-compatible optimizing inference proxy**. It sits in front of an OpenAI-compatible upstream (in this homelab, upstream is **LiteLLM**) and applies **inference-time strategies** (e.g., Mixture-of-Agents, planning/search, best-of-n) to improve reasoning and coding outputs.

This service behaves like “just another OpenAI-compatible provider” from LiteLLM’s point of view.

---

## Placement in the homelab

**Local-only proxy. No direct client access.**

Client(s) → LiteLLM (gateway) → OptiLLM (localhost-only) → LiteLLM (upstream) → Real backends

OptiLLM must bind to `127.0.0.1` only. External binding is intentionally out of scope.

---

## API compatibility

OptiLLM exposes standard OpenAI-style endpoints under `/v1`.

Required endpoints:
- `POST /v1/chat/completions`
- `GET /v1/models` (used for health/verification if `/health` is unavailable)

Any OpenAI-compatible client (including LiteLLM) can talk to OptiLLM by pointing `base_url` at its `/v1` endpoint.

---

## How optimization strategies are selected

OptiLLM supports multiple mechanisms. For this repo, **model-name prefixing is the primary method**.

### Model-name prefix convention

Format:
```
<approach>-<base_model>
```

Example:
```
moa-<base-model>
```

Meaning:
- `moa` → Mixture-of-Agents strategy
- `<base-model>` → base model used upstream

OptiLLM strips the prefix internally before calling upstream.

Clients should never see or select these prefixed names directly.

---

## Authentication model

There are **two separate authentication concerns**.

### 1) OptiLLM proxy authentication
- Protects access *to OptiLLM itself*
- **Use `--optillm-api-key`** (recommended)
- Requests must include:
```
Authorization: Bearer <OPTILLM_API_KEY>
```

### 2) Upstream authentication
- Used when OptiLLM calls LiteLLM
- Usually provided via `OPENAI_API_KEY` (or equivalent LiteLLM config)
- This is unrelated to `OPTILLM_API_KEY`

Important: setting `OPTILLM_API_KEY` in the environment triggers OptiLLM's
**local inference mode**. Do not set it when using a remote upstream (LiteLLM).
Use the `--optillm-api-key` flag instead.

## Proxy provider config (required)
OptiLLM's proxy plugin reads its provider list from:
```
~/.optillm/proxy_config.yaml
```

For this homelab, it must point **only** to LiteLLM:
```yaml
providers:
  - name: litellm
    base_url: http://127.0.0.1:4000/v1
    api_key: dummy
```

---

## Install and run (uv-only)

This repo does not allow Docker installs. Use `uv` to install a pinned OptiLLM
version and run it as a local service.

```bash
cd /home/christopherbailey/homelab-llm/layer-gateway/optillm-proxy
uv venv .venv
uv pip install optillm==0.3.12
```

Run manually (for quick verification):

```bash
OPENAI_API_KEY="<litellm-proxy-or-upstream-key>" \
uv run optillm \
  --host 127.0.0.1 \
  --port 4020 \
  --base-url http://127.0.0.1:4000/v1 \
  --approach proxy \
  --model <base-model> \
  --optillm-api-key "<optillm-proxy-key>"
```

Notes:
- `OPENAI_API_KEY` is used by OptiLLM when calling the LiteLLM upstream.
- `--optillm-api-key` protects the OptiLLM proxy itself.
- `--base-url` must point at the LiteLLM gateway.
- OptiLLM local (Studio) uses `/Users/thestudio/models/hf/hub` and pins
  `transformers<5` for router compatibility (see `layer-gateway/optillm-local`).

## Warm start (router model)
- Systemd uses a warmup request after startup to load the router classifier:
  - Unit: `/etc/systemd/system/optillm-proxy.service` (`ExecStartPost`)
  - Payload: `/etc/optillm-proxy/warmup.json`
- This triggers `router-<base>` once so the router model is loaded into memory.
- Router model cache (proxy): `~/.cache/huggingface/hub` for the OptiLLM service user.

## Loop-avoidance rule (critical)

Because OptiLLM calls back into LiteLLM, routing must avoid infinite loops.

Required invariant:
- LiteLLM → OptiLLM: **prefixed model name** (e.g., `moa-<base-model>`)
- OptiLLM → LiteLLM (upstream): **base model only** (e.g., `<base-model>`)

LiteLLM must never route the base model back to OptiLLM.

---

## Router model (internal)
- The `router` plugin uses an internal classifier model (not exposed via LiteLLM).
- Cached under `~/.cache/huggingface/hub` for the OptiLLM service user:
  - `codelion/optillm-modernbert-large` (router head)
  - `answerdotai/ModernBERT-large` (base encoder)
- OptiLLM loads these directly during routing and they do not appear in `/v1/models`.

## Current OptiLLM aliases (router-only)

There are **no separate OptiLLM aliases** right now; MLX handles route
through OptiLLM automatically. OptiLLM calls LiteLLM using `router-mlx-*`
model names that map directly to MLX ports. These `router-mlx-*` entries
are internal (not in `handles.jsonl`) but appear in LiteLLM `/v1/models`.
This behavior can be toggled via `mlxctl sync-gateway --no-route-via-optillm`.

## Technique selection (model prefixes)
OptiLLM chooses strategies based on the model prefix:
- `moa-<base>`: Mixture-of-Agents (strong reasoning, higher latency)
- `bon-<base>`: best-of-n sampling (faster than MoA, moderate gains)
- `plansearch-<base>`: planning/search (slower, good for multi-step tasks)
- `self_consistency-<base>`: consistency voting (slower, robust)

Example:
```
OPTILLM_OPT_ROUTER_EXAMPLE_MODEL=router-<base-model>
```

## Ensemble Matrix (v0)
See `ENSEMBLES.md` for the initial OptiLLM ensemble matrix used for evaluation.

## Planned registry (service-level)
This service will own a JSONL registry for OptiLLM ensembles (planned):
- `layer-gateway/optillm-proxy/registry/ensembles.jsonl`
- Source of truth for OptiLLM selectors and ensemble membership.

---

## Verification checklist

- OptiLLM responds to `/v1/chat/completions` on localhost
- Requests without `Authorization` fail (if auth enabled)
- Requests via LiteLLM alias reach OptiLLM
- OptiLLM makes multiple upstream calls to LiteLLM
- No routing loops occur
