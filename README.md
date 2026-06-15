# OpenAppNest Agent

Node agent for [OpenAppNest](https://github.com/xixi-zhao/openappnest) — runs Docker containers and manages Caddy reverse proxy on VPS nodes.

## Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/xixi-zhao/openappnest-agent/main/install-agent.sh | bash -s -- --token <YOUR_TOKEN> --endpoint <MASTER_URL>
```

## Binaries

| Platform | Download |
|----------|----------|
| Linux AMD64 | [agent-linux-amd64](https://github.com/xixi-zhao/openappnest-agent/raw/main/agent-linux-amd64) |
| Linux ARM64 | [agent-linux-arm64](https://github.com/xixi-zhao/openappnest-agent/raw/main/agent-linux-arm64) |

## API Endpoints

All behind `Authorization: Bearer <token>`:

| Method | Path | Description |
|--------|------|-------------|
| GET | /api/v1/health | Health check |
| GET | /api/v1/status | Node resource stats |
| POST | /api/v1/instances | Create instance (docker compose up -d) |
| GET | /api/v1/instances/{id}/status | Instance status (compose ps) |
| POST | /api/v1/instances/{id}/start | Start instance |
| POST | /api/v1/instances/{id}/stop | Stop instance |
| POST | /api/v1/instances/{id}/restart | Restart instance |
| DELETE | /api/v1/instances/{id} | Delete instance (compose down -v) |
| POST | /api/v1/instances/{id}/backup | Create backup |
| POST | /api/v1/instances/{id}/restore | Restore backup |

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| AGENT_PORT | 9100 | HTTP listen port |
| AGENT_TOKEN | (required) | Bearer token for API auth |
| AGENT_ENDPOINT | (optional) | Master server URL for heartbeat |
| APPS_DIR | /srv/apps | Instance data directory |
| CADDY_FILE | /etc/caddy/Caddyfile.apps | Caddy config for reverse proxy |

## Docs

See [node-setup.md](https://github.com/xixi-zhao/openappnest/blob/main/docs/node-setup.md) for detailed installation guide.
