# Runbook: OptiLLM Proxy

## Start/stop
```bash
sudo systemctl start optillm-proxy.service
sudo systemctl stop optillm-proxy.service
sudo systemctl restart optillm-proxy.service
```

## Logs
```bash
journalctl -u optillm-proxy.service -f
```

### Confirm approach usage
OptiLLM already logs the selected approaches at INFO level. Look for:
```
Using approach(es) [...]
```
Quick filter:
```bash
journalctl -u optillm-proxy.service -n 200 --no-pager | rg -n "Using approach\\(es\\)"

### Streaming benchmark (TTFT + total time)

```bash
layer-gateway/optillm-proxy/scripts/bench_stream.py \
  --model p-plan-max \
  --prompt "Write a detailed migration plan with risks and rollbacks." \
  --max-tokens 1200
```
```

## Update OptiLLM fork (durable patches)
1) Update the fork repo (rebase or merge upstream changes).
2) Apply/verify local patches:
   - `optillm/server.py`: honor `optillm_base_model` (prevents LiteLLM preset loops)
   - `optillm/server.py`: preserve router prefix parsing and strip `optillm_approach`
   - `optillm/bon.py`: enforce strict role alternation for rating prompts
3) Push the fork and note the new commit hash.
4) Update the pin in `pyproject.toml`.
5) Reinstall and restart:
```bash
cd /home/christopherbailey/homelab-llm/layer-gateway/optillm-proxy
uv sync
./scripts/apply_optillm_patches.sh
sudo systemctl restart optillm-proxy.service
```

## Rebuild the venv (if needed)
```bash
cd /home/christopherbailey/homelab-llm/layer-gateway/optillm-proxy
rm -rf .venv
uv venv .venv
uv sync
sudo systemctl restart optillm-proxy.service
```
