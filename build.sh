#!/bin/bash
set -e

if [ -z "$OCTAVE_REPO" ]; then
  echo "OCTAVE_REPO not set"
  exit 1
fi

if [ ! -d "/data/openclaw/.openclaw/workspace/Octave/.git" ]; then
  echo "Cloning Octave from $OCTAVE_REPO..."
  rm -rf "/data/openclaw/.openclaw/workspace/Octave"
  git clone "$OCTAVE_REPO" "/data/openclaw/.openclaw/workspace/Octave" --recursive
else
  echo "Octave repo already exists, pulling latest..."
  cd "/data/openclaw/.openclaw/workspace/Octave"
  git pull && git submodule update --init --recursive
fi
