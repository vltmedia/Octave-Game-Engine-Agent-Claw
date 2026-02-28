# Octave Dev Claw

An AI-powered development agent for the [Octave Game Engine](https://github.com/vltmedia/octave), built on [OpenClaw](https://docs.openclaw.ai). Ships with the `octave_dev` skill — deep knowledge of every Octave subsystem, naming convention, and development pattern — ready to assist with code generation, architecture questions, debugging, and code review.

## Quick Start

```bash
docker run -d \
  --name octave_claw \
  -e OCTAVE_REPO=https://github.com/vltmedia/octave \
  -e OPENCLAW_HOME=/data/openclaw \
  -p 3348:3000 \
  -v openclaw_octave_state:/data/openclaw \
  --tty --interactive \
  vltmedia/octave-dev-claw:latest
```

Then run onboarding to set up your API key (first time only):

```bash
docker exec -it octave_claw openclaw onboard
docker restart octave_claw
```

Open the Control UI at **http://localhost:3348** and enter the auth token (default: `lobstero`).

## What's Inside

- **Node 22** runtime with OpenClaw installed via npm
- **octave_dev skill** — a comprehensive Octave Engine development prompt covering RTTI/factory patterns, serialization, node/asset/graph node creation, Lua bindings, editor panels, and platform-specific code
- On first boot, automatically clones the Octave repository into the container workspace
- **Agent memory** files baked into the image for pre-seeded context
- Persistent volume keeps credentials, session history, and the cloned repo across restarts
- **Sync mode** (`SYNC_MODE=true`) to force-refresh config, skills, and memory from the image on every boot

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `OCTAVE_REPO` | Yes | Git URL for the Octave repository |
| `OPENCLAW_HOME` | No | OpenClaw data directory (default: `/data/openclaw`) |
| `SYNC_MODE` | No | Set to `true` to overwrite config/skills/memory from the image on every boot. Default: only copies on first run. |
| `ALLOWED_ORIGINS` | No | Comma-separated list of allowed origins for the Control UI (e.g., `http://localhost:3348,https://myhost.example.com`). Patches the config at runtime. |
| `GATEWAY_TOKEN` | No | Override the gateway auth token at runtime without editing `openclaw.json`. |

## Ports

| Container Port | Description |
|----------------|-------------|
| `3000` | OpenClaw Gateway + Control UI |

Map it to any host port you like (e.g., `-p 3348:3000`).

## Volumes

| Path | Description |
|------|-------------|
| `/data/openclaw` | Persistent storage for credentials, config, cloned repo, and session data |

## Authentication

The gateway requires a token to connect. Default token: `lobstero`.

You can override the token and allowed origins via environment variables — no rebuild needed:

```bash
docker run -d \
  --name octave_claw \
  -e OCTAVE_REPO=https://github.com/vltmedia/octave \
  -e OPENCLAW_HOME=/data/openclaw \
  -e GATEWAY_TOKEN=my-secret-token \
  -e ALLOWED_ORIGINS="http://localhost:3348,https://myhost.example.com" \
  -p 3348:3000 \
  -v openclaw_octave_state:/data/openclaw \
  --tty --interactive \
  vltmedia/octave-dev-claw:latest
```

The entrypoint patches the config JSON at runtime with the values from `GATEWAY_TOKEN` and `ALLOWED_ORIGINS`.

## Onboarding

The first time you run the container, you need to register your LLM provider credentials:

```bash
docker exec -it octave_claw openclaw onboard
```

The wizard will ask you to:
1. Accept the terms
2. Choose a model provider (OpenAI or Anthropic)
3. Enter your API key

Credentials are stored in the persistent volume — you only need to do this once unless you remove the volume.

## Use Cases

- **Scaffold engine types** — "Create a new ParticleEmitter3D node with velocity, lifetime, and emission rate properties"
- **Architecture deep-dives** — "Explain how the NodeGraph processor evaluates pins and links"
- **Debug assistance** — "My custom asset isn't appearing at runtime, what could be wrong?"
- **Code review** — "Check this Node implementation for missing registration, guards, or serialization version gating"
- **Onboard new developers** — "Walk me through the rendering pipeline from Vulkan init to frame submission"

## Sync Mode

By default, config, skills, and memory are only copied into the volume on first boot. To always overwrite from the image (useful when iterating on skills or config):

```bash
docker run -d \
  -e SYNC_MODE=true \
  -e OCTAVE_REPO=https://github.com/vltmedia/octave \
  -e OPENCLAW_HOME=/data/openclaw \
  -p 3348:3000 \
  -v openclaw_octave_state:/data/openclaw \
  --tty --interactive \
  vltmedia/octave-dev-claw:latest
```

## Docker Compose

```yaml
services:
  octave_claw:
    image: vltmedia/octave-dev-claw:latest
    environment:
      OCTAVE_REPO: https://github.com/vltmedia/octave
      OPENCLAW_HOME: /data/openclaw
      # SYNC_MODE: "true"       # Uncomment to overwrite config/skills/memory on every boot
      # ALLOWED_ORIGINS: "http://localhost:3348,https://myhost.example.com"
      # GATEWAY_TOKEN: "my-secret-token"
    ports:
      - "3348:3000"
    volumes:
      - openclaw_octave_state:/data/openclaw
    tty: true
    stdin_open: true

volumes:
  openclaw_octave_state:
```

## Links

- [Octave Engine](https://github.com/vltmedia/octave)
- [Source & Dockerfile](https://github.com/vltmedia/Octave-Game-Engine-Agent-Claw/blob/main/Dockerfile)
