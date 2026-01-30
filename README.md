# OpenClaw Railway Template (1-click deploy)

This repo packages **OpenClaw** (formerly Moltbot/Clawdbot) for Railway with a small **/setup** web wizard so users can deploy and onboard **without running any commands**.

## What you get

- **OpenClaw Gateway + Control UI** (served at `/` and `/openclaw`)
- A friendly **Setup Wizard** at `/setup` (protected by a password)
- Persistent state via **Railway Volume** (so config/credentials/memory survive redeploys)
- One-click **Export backup** (so users can migrate off Railway later)
- **Import backup** to restore from a previous export

## How it works (high level)

- The container runs a wrapper web server.
- The wrapper protects `/setup` with `SETUP_PASSWORD`.
- During setup, the wrapper runs `openclaw onboard --non-interactive ...` inside the container, writes state to the volume, and then starts the gateway.
- After setup, **`/openclaw` is the Control UI**. The wrapper reverse-proxies all traffic (including WebSockets) to the local gateway process.

## Railway deploy instructions

In Railway:

1) Create a new project from this GitHub repo.
2) Add a **Volume** mounted at `/data`.
3) Set the following variables:

Required:
- `SETUP_PASSWORD` — user-provided password to access `/setup`

Recommended (for new deployments):
- `OPENCLAW_STATE_DIR=/data/.openclaw`
- `OPENCLAW_WORKSPACE_DIR=/data/workspace`

If upgrading from Moltbot/Clawdbot, your existing `MOLTBOT_*` or `CLAWDBOT_*` env vars continue to work.

Optional:
- `OPENCLAW_GATEWAY_TOKEN` — if not set, the wrapper generates one
- `OPENCLAW_GIT_REF` — build arg to pin to a specific OpenClaw version (default: `main`)

4) Enable **Public Networking** (HTTP). Railway will assign a domain.
5) Deploy.

Then:
- Visit `https://<your-app>.up.railway.app/setup`
- Complete setup
- Visit `https://<your-app>.up.railway.app/openclaw` for the Control UI

## Getting chat tokens

### Telegram bot token
1) Open Telegram and message **@BotFather**
2) Run `/newbot` and follow the prompts
3) BotFather will give you a token that looks like: `123456789:AA...`
4) Paste that token into `/setup`

### Discord bot token
1) Go to the Discord Developer Portal: https://discord.com/developers/applications
2) **New Application** → pick a name
3) Open the **Bot** tab → **Add Bot**
4) Copy the **Bot Token** and paste it into `/setup`
5) **Important:** Enable **MESSAGE CONTENT INTENT** in Bot > Privileged Gateway Intents
6) Invite the bot to your server (OAuth2 URL Generator → scopes: `bot`, `applications.commands`)

## Local smoke test

```bash
docker build -t openclaw-railway-template .

docker run --rm -p 8080:8080 \
  -e PORT=8080 \
  -e SETUP_PASSWORD=test \
  -e OPENCLAW_STATE_DIR=/data/.openclaw \
  -e OPENCLAW_WORKSPACE_DIR=/data/workspace \
  -v $(pwd)/.tmpdata:/data \
  openclaw-railway-template

# open http://localhost:8080/setup (password: test)
```

## Upgrading from Moltbot/Clawdbot

This template is backwards compatible with existing Moltbot/Clawdbot deployments:

- Your existing `MOLTBOT_*` or `CLAWDBOT_*` env vars continue to work
- Your existing `/data/.clawdbot` state directory is auto-detected
- Config files (`moltbot.json`, `clawdbot.json`) are recognized

The main change is the Control UI route: `/clawdbot` → `/openclaw`
