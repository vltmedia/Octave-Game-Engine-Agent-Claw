#!/bin/bash
set -e

if [ -z "$OCTAVE_REPO" ]; then
  echo "OCTAVE_REPO not set"
  exit 1
fi

if [ ! -d "$OCTAVE_DIR/.git" ]; then
  echo "Cloning Octave from $OCTAVE_REPO..."
  git clone "$OCTAVE_REPO" "$OCTAVE_DIR"
else
  echo "Octave repo already exists, pulling latest..."
  cd "$OCTAVE_DIR"
  git pull
fi

cd "$OCTAVE_DIR"


# Copy config and skills:
# - SYNC_MODE=true: always sync from the image on every boot
# - Otherwise: only copy on first run (when flag.json is missing)

if [ "$SYNC_MODE" = "true" ] || [ ! -f /data/openclaw/.openclaw/flag.json ]; then

  # Copy config into both possible locations
  mkdir -p /data/openclaw/.openclaw/workspace/memory
  mkdir -p /data/openclaw/.openclaw/workspace/skills
  mkdir -p /root/.openclaw/skills
  mkdir -p /root/.openclaw/memory


  # Copy skills to all discovery paths (workspace, managed, home)
  cp -r /tmp/skills/* /data/openclaw/.openclaw/workspace/skills/
  cp -r /tmp/memory/* /data/openclaw/.openclaw/workspace/memory/
  cp -r /tmp/skills/* /root/.openclaw/skills/
  cp -r /tmp/memory/* /root/.openclaw/memory/



  echo "First run detected, copying config to /data/openclaw/.openclaw"
  cp /tmp/openclaw.json /data/openclaw/.openclaw/openclaw.json
  cp /tmp/openclaw.json /root/.openclaw/openclaw.json
  # Create a flag file to indicate that the config has been copied
  touch /data/openclaw/.openclaw/flag.json
fi

# Patch allowedOrigins at runtime if ALLOWED_ORIGINS is set
# Accepts a comma-separated list, e.g. ALLOWED_ORIGINS="http://localhost:3348,https://myhost.example.com"
if [ -n "$ALLOWED_ORIGINS" ]; then
  ORIGINS_JSON=$(echo "$ALLOWED_ORIGINS" | sed 's/,/","/g' | sed 's/^/["/' | sed 's/$/"]/')
  for cfg in /data/openclaw/.openclaw/openclaw.json /root/.openclaw/openclaw.json; do
    if [ -f "$cfg" ]; then
      TMP=$(mktemp)
      node -e "
        const fs = require('fs');
        const cfg = JSON.parse(fs.readFileSync('$cfg', 'utf8'));
        cfg.gateway = cfg.gateway || {};
        cfg.gateway.controlUi = cfg.gateway.controlUi || {};
        cfg.gateway.controlUi.allowedOrigins = $ORIGINS_JSON;
        fs.writeFileSync('$cfg', JSON.stringify(cfg, null, 2) + '\n');
      "
    fi
  done
  echo "Patched allowedOrigins: $ALLOWED_ORIGINS"
fi

# Patch gateway auth token at runtime if GATEWAY_TOKEN is set
if [ -n "$GATEWAY_TOKEN" ]; then
  for cfg in /data/openclaw/.openclaw/openclaw.json /root/.openclaw/openclaw.json; do
    if [ -f "$cfg" ]; then
      node -e "
        const fs = require('fs');
        const cfg = JSON.parse(fs.readFileSync('$cfg', 'utf8'));
        cfg.gateway = cfg.gateway || {};
        cfg.gateway.auth = cfg.gateway.auth || {};
        cfg.gateway.auth.token = '$GATEWAY_TOKEN';
        fs.writeFileSync('$cfg', JSON.stringify(cfg, null, 2) + '\n');
      "
    fi
  done
  echo "Patched gateway auth token from GATEWAY_TOKEN env"
fi

# Fix permissions
chmod 700 /data/openclaw/.openclaw


exec openclaw gateway run --bind lan --port 3000 --auth token
