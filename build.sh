
if [ -z "$OCTAVE_REPO" ]; then
  echo "OCTAVE_REPO not set"
  exit 1
fi

if [ ! -d "$OCTAVE_DIR/.git" ]; then
  echo "Cloning Octave from $OCTAVE_REPO..."
  git clone "$OCTAVE_REPO" "/data/openclaw/.openclaw/workspace/Octave" --recursive
else
  echo "Octave repo already exists, pulling latest..."
  cd "/data/openclaw/.openclaw/workspace/Octave"
  git pull && git submodule update --init --recursive
fi


