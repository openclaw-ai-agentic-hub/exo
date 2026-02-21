#!/bin/bash
# Maintains a persistent SSH tunnel to Studio's Ollama on port 11434
# Used by LaunchDaemon or can be run manually

STUDIO_HOST="aistudio1@10.168.168.20"
LOCAL_PORT=11434
REMOTE_PORT=11434

# Start Ollama on Studio if not running
ssh -o ConnectTimeout=5 "$STUDIO_HOST" \
  "pgrep -f 'ollama serve' >/dev/null || nohup /opt/homebrew/bin/ollama serve > /tmp/ollama.log 2>&1 &"

# Create tunnel (autossh keeps it alive)
if command -v autossh &>/dev/null; then
    exec autossh -M 0 -N \
        -o "ServerAliveInterval 30" \
        -o "ServerAliveCountMax 3" \
        -o "ExitOnForwardFailure yes" \
        -L "${LOCAL_PORT}:localhost:${REMOTE_PORT}" \
        "$STUDIO_HOST"
else
    # Fallback: plain ssh with keepalive
    exec ssh -N \
        -o "ServerAliveInterval 30" \
        -o "ServerAliveCountMax 3" \
        -o "ExitOnForwardFailure yes" \
        -L "${LOCAL_PORT}:localhost:${REMOTE_PORT}" \
        "$STUDIO_HOST"
fi
