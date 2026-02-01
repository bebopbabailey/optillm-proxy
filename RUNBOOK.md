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

## Auth reminder
- OptiLLM requires `Authorization: Bearer <OPTILLM_API_KEY>` for all requests, even from localhost.
- Missing headers return `Invalid Authorization header`.

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

## Update OptiLLM (upstream release)
1) Update the pin in `pyproject.toml`.
2) Reinstall and restart:
```bash
cd /home/christopherbailey/homelab-llm/layer-gateway/optillm-proxy
uv sync
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
