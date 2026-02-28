# Octave Game Engine Dev Agent - OpenClaw Docker Deployment

A self-contained Docker deployment of an [OpenClaw](https://docs.openclaw.ai) agent specialized for [Octave Engine](https://github.com/vltmedia/octave) development. On startup it clones the Octave repository, loads the `octave_dev` skill, and exposes the OpenClaw Gateway + Control UI over HTTP.

## What It Does

The agent ships with the **octave_dev** skill, which gives it deep knowledge of the Octave Engine codebase — architecture, naming conventions, subsystems, and development patterns. It reads the `.llm/` documentation files and source code directly from the cloned repo inside the container.

### Use Cases

- **Code generation** — Ask it to scaffold new Node types, Asset types, Graph Nodes, Lua bindings, or Editor panels following Octave's exact conventions (RTTI macros, factory registration, serialization patterns).
- **Architecture Q&A** — Query subsystem design, class hierarchies, or how specific engine features are implemented.
- **Debugging assistance** — Describe a bug and it will trace call chains, read relevant source files, and suggest fixes.
- **Code review** — Paste code and it will check for missing `FORCE_LINK_CALL` registration, incorrect naming, missing `#if EDITOR` guards, asset version gating, and other common pitfalls.
- **Onboarding** — New developers can ask the agent to explain any part of the engine, from the rendering pipeline to the plugin API.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) and Docker Compose
- An [OpenAI API key](https://platform.openai.com/api-keys) (the agent uses `gpt-5.1-codex` by default)

## Quick Start

### 1. Create a `.env` file

```bash
cp .env.example .env
```

Edit `.env` and set:

```
OCTAVE_REPO=https://github.com/vltmedia/octave
```

### 2. Build and start the container

```bash
docker compose up --build -d
```

### 3. Run onboarding (first time only)

The agent needs your OpenAI or Anthropic API key stored in its credential store. Shell into the running container and run the onboard wizard:

```bash
docker compose exec octave_claw openclaw onboard
```

This walks you through:
- Accepting the terms
- Selecting your model provider (choose **OpenAI** or **Anthropic**)
- Entering your **API key**

The key is saved inside the persistent Docker volume, so you only need to do this once. The container will retain it across restarts.

### 4. Restart the gateway

After onboarding, restart the container so the gateway picks up the new credentials:

```bash
docker compose restart
```

### 5. Open the Control UI

Navigate to:

```
http://localhost:3348
```

You should see the OpenClaw Control UI. Enter the gateway auth token when prompted (see [Authentication](#authentication) below).

## Authentication

The gateway uses **token-based auth**. When you open the Control UI, you'll be asked for a token.

### Default token

The default token is set in `openclaw/openclaw.json` under `gateway.auth.token`:

```json
"auth": {
  "mode": "token",
  "token": "lobstero"
}
```

Enter `lobstero` (or whatever you've changed it to) in the Control UI token prompt.

### Changing the token

Edit `openclaw/openclaw.json` and change `gateway.auth.token` to any string you want, then rebuild:

```bash
docker compose up --build -d
```

### Device pairing

Device pairing is **disabled** in this deployment (`dangerouslyDisableDeviceAuth: true`) for convenience. This means any browser that has the token can connect without an additional approval step.

If you want to re-enable pairing for tighter security, set `dangerouslyDisableDeviceAuth` to `false` in `openclaw/openclaw.json`. New browsers will then require approval:

```bash
docker compose exec octave_claw openclaw devices list
docker compose exec octave_claw openclaw devices approve <requestId>
```

### Security notes

- The gateway binds to `0.0.0.0` inside the container (`bind: "lan"`) so Docker can route traffic to it. It is only exposed on port `3348` on your host.
- Do **not** expose port `3348` to the public internet without changing the token to something strong and re-enabling device auth.
- The `allowedOrigins` in the config restricts Control UI access to `http://localhost:3348`. Update this if you access it from a different host or port.

## Running Without Docker Compose

If you prefer plain `docker` commands instead of Compose:

### 1. Build the image

```bash
docker build -t octave-claw .
```

### 2. Create a volume for persistent data

```bash
docker volume create openclaw_octave_state
```

### 3. Run the container

```bash
docker run -d \
  --name octave_claw \
  -e OCTAVE_REPO=https://github.com/vltmedia/octave \
  -e OPENCLAW_HOME=/data/openclaw \
  -p 3348:3000 \
  -v openclaw_octave_state:/data/openclaw \
  --tty --interactive \
  octave-claw
```

### 4. Run onboarding (first time only)

```bash
docker exec -it octave_claw openclaw onboard
```

Then restart the container:

```bash
docker restart octave_claw
```

### 5. Open the Control UI

Navigate to `http://localhost:3348` and enter the auth token (default: `lobstero`).

### Useful commands

```bash
# View logs
docker logs -f octave_claw

# Shell into the container
docker exec -it octave_claw bash

# List skills
docker exec octave_claw openclaw skills list

# Stop and remove
docker stop octave_claw && docker rm octave_claw

# Fully reset (remove persistent data)
docker volume rm openclaw_octave_state
```

## Project Structure

```
.
├── Dockerfile              # Node 22 base, installs OpenClaw via npm
├── docker-compose.yml      # Service definition, port mapping, volume
├── entrypoint.sh           # Clones Octave repo, copies config, starts gateway
├── .env                    # Environment variables (OCTAVE_REPO)
├── openclaw/
│   ├── openclaw.json       # OpenClaw gateway + agent configuration
│   ├── skills/
│   │   └── octave_dev/
│   │       └── SKILL.md    # The Octave Engine developer skill
│   └── memory/             # Agent memory files (persisted into workspace)
└── README.md
```

## Configuration

### Changing the model

Edit `openclaw/openclaw.json` and update `agents.defaults.model.primary` and the agent's `model` field in `agents.list`:

```json
"model": {
  "primary": "openai/gpt-5.1-codex"
}
```

### Changing the port

The gateway listens on port `3000` inside the container, mapped to `3348` on the host. To change the host port, edit `docker-compose.yml`:

```yaml
ports:
  - "YOUR_PORT:3000"
```

Then update `gateway.controlUi.allowedOrigins` in `openclaw/openclaw.json` to match.

### Sync mode

By default, the config, skills, and memory files are only copied into the volume on the **first boot** (tracked by a `flag.json` marker). This means changes you make inside the container (via onboarding, editing config, etc.) are preserved across restarts.

If you want the container to **always overwrite** the volume config/skills/memory with what's baked into the image, set `SYNC_MODE=true`:

```yaml
# docker-compose.yml
environment:
  SYNC_MODE: "true"
```

Or with plain Docker:

```bash
docker run -d \
  -e SYNC_MODE=true \
  ...
```

This is useful during development when you're iterating on `openclaw.json`, skills, or memory files and want every rebuild to push the latest changes into the running volume.

### Persistent data

The Docker volume `openclaw_octave_state` persists:
- The cloned Octave repository
- OpenClaw credentials (from onboarding)
- Session history and memory
- Config and skills (after first boot, unless `SYNC_MODE=true`)

To fully reset, remove the volume:

```bash
docker compose down -v
```

## Troubleshooting

### "Gateway token missing"
Enter the auth token in the Control UI prompt. Default: `lobstero`.

### "Pairing required"
If you re-enabled device auth, approve the device from inside the container (see [Device pairing](#device-pairing)).

### Skill not showing up
The `octave_dev` skill should appear in the agent's skill list. Verify with:

```bash
docker compose exec octave_claw openclaw skills list
```

If it shows as missing, check that the SKILL.md was copied correctly:

```bash
docker compose exec octave_claw cat /data/openclaw/.openclaw/workspace/skills/octave_dev/SKILL.md
```

### Onboarding credentials lost
If you removed the Docker volume, re-run onboarding:

```bash
docker compose exec octave_claw openclaw onboard
docker compose restart
```
