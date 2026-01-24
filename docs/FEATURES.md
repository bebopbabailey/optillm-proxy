# OptiLLM Features (Enabled)

Status: running with **all bundled plugins loaded** (as of 2026-01-19).

## Core
- **Approach**: proxy (per-request technique selection).
- **Bind**: 127.0.0.1:4020
- **Upstream**: LiteLLM (`http://127.0.0.1:4000/v1`)

## Techniques (Approaches)
These are inference-time strategies selectable via `optillm_approach` (request body) or prompt tags. Descriptions are based on OptiLLM docs.

- `mars` — Multi-agent reasoning with diverse temperature exploration, cross-verification, and iterative improvement. citeturn3view0
- `cepo` — Cerebras Planning and Optimization; combines Best-of-N, CoT, self-reflection, and self-improvement. citeturn3view0
- `cot_reflection` — Chain-of-thought with explicit reflection/output stages. citeturn3view0
- `plansearch` — Search over candidate plans in natural language. citeturn3view0
- `re2` — ReRead (processes queries twice for improved reasoning). citeturn3view0
- `self_consistency` — Advanced self-consistency reasoning. citeturn3view0
- `z3` — Uses the Z3 theorem prover for logical reasoning. citeturn3view0
- `rstar` — R* algorithm for problem-solving. citeturn3view0
- `leap` — Learns task-specific principles from few-shot examples. citeturn3view0
- `rto` — Round-trip optimization (iterate/critique to refine answers). citeturn3view0
- `bon` — Best-of-N sampling; generate multiple answers and pick the best. citeturn3view0
- `moa` — Mixture-of-Agents; merges critiques from multiple candidates. citeturn3view0
- `mcts` — Monte Carlo Tree Search for decision-making in chat responses. citeturn3view0
- `pvg` — Prover-Verifier Game (PV Game) at inference time. citeturn3view0

Other techniques exist in OptiLLM but are not available in proxy mode (e.g., deep confidence, CoT decoding, entropy decoding, thinkdeeper, autothink). citeturn3view0

## Plugins (Loaded)
Plugins are chained with `&` and can be combined with approaches. Descriptions are from OptiLLM docs.

- `spl` — System Prompt Learning ("third paradigm"). citeturn3view1
- `deepthink` — Gemini-like Deep Think inference-time scaling. citeturn3view1
- `longcepo` — Long-context CePO with planning + divide-and-conquer for long docs. citeturn3view1
- `majority_voting` — Generate k candidates and select the most frequent answer. citeturn3view1
- `mcp` — MCP client for tool access over MCP servers. citeturn3view1
- `router` — Uses `optillm-modernbert-large` to route prompts to approaches. citeturn3view1
- `coc` — Chain-of-code (CoT + code execution/simulation). citeturn3view1
- `memory` — Short-term memory layer for large context handling. citeturn3view1
- `privacy` — Anonymize PII, then restore in output. citeturn3view1
- `readurls` — Fetch URL contents and inject into context. citeturn3view1
- `executecode` — Execute Python code from prompts/outputs. citeturn3view1
- `json` — Structured outputs via outlines (Pydantic/JSON schema). citeturn3view1
- `genselect` — Generate multiple candidates and select best by quality. citeturn3view1
- `web_search` — **SearXNG** search when `SEARXNG_API_BASE` is set; otherwise uses the Selenium/Google fallback. citeturn3view1
- `deep_research` — Test-Time Diffusion deep research with iterative refinement. citeturn3view1
- `proxy` — Load balancing + failover across LLM providers. citeturn3view1

## Router model (internal)
- The router plugin uses a ModernBERT-based classifier: `codelion/optillm-modernbert-large`. citeturn3view1turn0search2
- This model is internal to OptiLLM (not exposed via LiteLLM handles).
- Proxy cache location (Mini): `~/.cache/huggingface/hub` for the OptiLLM service user.

## Notes
- Plugin chaining with `&`/`|` still works, but technique selection is set per request.
- If plugin load errors appear, check `journalctl -u optillm-proxy.service`.
- OptiLLM local (Studio) pins `transformers<5` to keep router compatible.
