# OpenClaw Railway Template

One-click deploy for OpenClaw (formerly Moltbot/Clawdbot) on Railway. Express wrapper server that proxies to an internal OpenClaw gateway, with a `/setup` wizard for configuration without CLI access.

## Why This Fork Exists

This is a fork of `vignesh07/clawdbot-railway-template` with key additions:

1. **Version control** - Pin to a specific OpenClaw version via `OPENCLAW_GIT_REF` build arg
2. **Import/restore capability** - Added `POST /setup/import` endpoint to restore from backup tarballs
3. **Backwards compatibility** - Supports `OPENCLAW_*`, `MOLTBOT_*`, and `CLAWDBOT_*` env vars

---

## Architecture

```
Browser → Express wrapper (:8080) → OpenClaw gateway (:18789)
                ↓
        /setup (wizard)
        /openclaw (Control UI)
        /telegram, /discord, /slack (webhooks)
```

The wrapper handles:
- Authentication (Basic Auth via `SETUP_PASSWORD`)
- HTTPS enforcement
- Proxying to the internal gateway
- Setup wizard and backup/restore endpoints

---

## Key Files

| File | Purpose |
|------|---------|
| `src/server.js` | Express wrapper - auth, proxy, setup wizard API, import/export |
| `src/setup-app.js` | Frontend JS for /setup wizard |
| `Dockerfile` | Multi-stage build: OpenClaw from source → runtime image |
| `railway.toml` | Railway deployment config (healthcheck, restart policy) |
| `scripts/smoke.js` | Basic sanity test (openclaw/moltbot/clawdbot commands exist) |

---

## Environment Variables

The wrapper supports three env var prefixes for backwards compatibility. `OPENCLAW_*` takes precedence, then `MOLTBOT_*`, then `CLAWDBOT_*`.

| Variable | Required | Description |
|----------|----------|-------------|
| `SETUP_PASSWORD` | Yes | Basic Auth password for /setup and Control UI |
| `OPENCLAW_STATE_DIR` | No | Default: auto-detected (`/data/.openclaw` or `/data/.clawdbot` if exists) |
| `OPENCLAW_WORKSPACE_DIR` | No | Default: `{STATE_DIR}/workspace` |
| `OPENCLAW_GATEWAY_TOKEN` | No | Auto-generated and persisted if not set |
| `ANTHROPIC_API_KEY` | No | For Anthropic/Claude models |

Legacy prefixes (`MOLTBOT_*`, `CLAWDBOT_*`) also work for backwards compatibility.

---

## Authentication

Two layers protect the system:

1. **Basic Auth** (`SETUP_PASSWORD`)
   - Required for `/setup/*` routes
   - Required for `/openclaw/*` (Control UI)
   - WebSocket connections to Control UI also require it

2. **Gateway token**
   - Internal auth between wrapper and OpenClaw gateway
   - Passed via URL query param to Control UI

3. **Public routes** (bypass auth for external webhooks):
   - `/telegram`, `/discord`, `/slack`, `/webhook`, `/healthz`

---

## Key Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/setup` | GET | Configuration wizard UI |
| `/setup/export` | GET | Download backup tarball (.tar.gz) |
| `/setup/import` | POST | Restore from backup tarball |
| `/setup/api/token` | GET | View current gateway token |
| `/setup/dashboard` | GET | Redirect to Control UI with token |
| `/setup/api/doctor` | POST | Run `openclaw doctor --fix` |
| `/setup/api/reset` | POST | Delete config to rerun onboarding |
| `/setup/api/debug` | GET | Debug info (versions, paths, etc.) |
| `/openclaw` | * | Control UI (proxied to gateway) |

---

## Local Development

```bash
# Build the image
docker build -t openclaw-railway-template .

# Run locally
docker run -p 8080:8080 \
  -e SETUP_PASSWORD=test \
  -v $(pwd)/.tmpdata:/data \
  openclaw-railway-template

# Open http://localhost:8080/setup (password: test)
```

---

## Dockerfile Notes

The Dockerfile uses a multi-stage build:

1. **Build stage** (`openclaw-build`)
   - Clones OpenClaw from GitHub at `OPENCLAW_GIT_REF` (default: `main`)
   - Builds with pnpm
   - Patches workspace protocol references in extension package.json files

2. **Runtime stage**
   - Node 22 on Debian Bookworm
   - Copies built OpenClaw to `/openclaw`
   - Creates `/usr/local/bin/openclaw` wrapper script
   - Symlinks `moltbot` → `openclaw` and `clawdbot` → `openclaw` for backwards compat
   - Installs bird CLI for Twitter/X reading

To pin to a specific version:
```bash
docker build --build-arg OPENCLAW_GIT_REF=v2026.1.30 -t openclaw-railway-template .
```

---

## State Directory Auto-Detection

The wrapper automatically detects which state directory to use:

1. If `OPENCLAW_STATE_DIR` (or `MOLTBOT_STATE_DIR`/`CLAWDBOT_STATE_DIR`) is explicitly set → use it
2. Else if `/data/.openclaw` exists → use it
3. Else if `/data/.clawdbot` exists → use it (backwards compat for existing deployments)
4. Else if `/data` exists → create `/data/.openclaw` (new Railway installs)
5. Else → use `~/.openclaw`

This ensures existing deployments with `/data/.clawdbot` continue working without changes.

---

## Config File Support

The wrapper checks for config files in this order:
1. `openclaw.json`
2. `moltbot.json`
3. `clawdbot.json`

New onboarding creates `openclaw.json`. Imported backups with older config files continue to work.

---

## Notes

- OpenClaw reads `openclaw.json` config files (with fallback to `moltbot.json`/`clawdbot.json`)
- Gateway binds to loopback (127.0.0.1) - wrapper handles all external traffic
- HTTPS enforced via `x-forwarded-proto` header check (Railway terminates TLS)
- Import endpoint validates archive structure and prevents path traversal attacks
- Token is stable across restarts (persisted to `{STATE_DIR}/gateway.token` if not in env)
- Control UI route is `/openclaw` (configured via `gateway.controlUi.basePath`)
