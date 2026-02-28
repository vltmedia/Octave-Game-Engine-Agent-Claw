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

# Copy config into both possible locations
mkdir -p /data/openclaw/.openclaw/workspace/skills
mkdir -p /root/.openclaw/skills
cp /tmp/openclaw.json /data/openclaw/.openclaw/openclaw.json
cp /tmp/openclaw.json /root/.openclaw/openclaw.json

# Copy skills to all discovery paths (workspace, managed, home)
cp -r /tmp/skills/* /data/openclaw/.openclaw/workspace/skills/
cp -r /tmp/skills/* /root/.openclaw/skills/

# Fix permissions
chmod 700 /data/openclaw/.openclaw


exec openclaw gateway run --bind lan --port 3000 --auth token
