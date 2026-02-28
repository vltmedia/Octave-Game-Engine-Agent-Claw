# syntax=docker/dockerfile:1.6
FROM node:22-slim

ENV OPENCLAW_HOME=/data/openclaw \
    WORKSPACE=/workspace \
    OCTAVE_DIR=/data/openclaw/.openclaw/workspace/Octave

RUN apt-get update && apt-get install -y --no-install-recommends \
      git \
      ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install OpenClaw globally via npm
RUN npm install -g openclaw

WORKDIR ${WORKSPACE}

# Copy OpenClaw config (staged for runtime copy since /data/openclaw is a volume)
COPY openclaw/openclaw.json /root/.openclaw/openclaw.json
COPY openclaw/openclaw.json /tmp/openclaw.json
COPY openclaw/skills/ /tmp/skills/

EXPOSE 3000

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
