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

# Fix permissions
chmod 700 /data/openclaw/.openclaw


exec openclaw gateway run --bind lan --port 3000 --auth token
