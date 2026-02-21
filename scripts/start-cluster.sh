#!/bin/bash
# Start the Exo cluster across Mini and Studio with bootstrap peer discovery
# Run this from the Mini (the machine that initiates the connection)

set -e

STUDIO_HOST="aistudio1@10.168.168.20"
STUDIO_IP="10.168.168.20"
MINI_IP="10.168.168.60"
EXO_DIR_MINI="/Users/aihub/exo"
EXO_DIR_STUDIO="/Users/aistudio1/exo"
LOG_MINI="/tmp/exo-mini.log"
LOG_STUDIO="/tmp/exo.log"

echo "=== Exo Cluster Startup ==="

# 1. Kill any existing Exo processes
echo "[1/6] Stopping existing Exo processes..."
pkill -f "uv run exo" 2>/dev/null || true
ssh "$STUDIO_HOST" "pkill -f 'uv run exo' 2>/dev/null || true"
sleep 2

# 2. Start Studio Exo (no bootstrap — it will accept incoming connections)
echo "[2/6] Starting Exo on Studio..."
ssh "$STUDIO_HOST" "export PATH=/opt/homebrew/bin:\$PATH && cd $EXO_DIR_STUDIO && nohup uv run exo > $LOG_STUDIO 2>&1 &"
sleep 5

# 3. Get Studio's peer ID and swarm port
echo "[3/6] Discovering Studio's peer info..."
STUDIO_PEER_ID=$(ssh "$STUDIO_HOST" "grep 'Starting node' $LOG_STUDIO | head -1" | grep -oE '12D3KooW[A-Za-z0-9]+')
STUDIO_PORT=$(ssh "$STUDIO_HOST" "grep 'NewListenAddr.*$STUDIO_IP' $LOG_STUDIO | head -1" | grep -oE 'tcp/[0-9]+' | head -1 | cut -d/ -f2)

if [ -z "$STUDIO_PEER_ID" ] || [ -z "$STUDIO_PORT" ]; then
    echo "ERROR: Could not discover Studio peer info"
    echo "  Peer ID: ${STUDIO_PEER_ID:-NOT FOUND}"
    echo "  Port: ${STUDIO_PORT:-NOT FOUND}"
    echo "  Check $LOG_STUDIO on Studio"
    exit 1
fi
echo "  Studio: $STUDIO_PEER_ID @ $STUDIO_IP:$STUDIO_PORT"

# 4. Start Mini Exo with Studio as bootstrap peer
BOOTSTRAP="/ip4/$STUDIO_IP/tcp/$STUDIO_PORT/p2p/$STUDIO_PEER_ID"
echo "[4/6] Starting Exo on Mini with bootstrap: $BOOTSTRAP"
cd "$EXO_DIR_MINI"
EXO_BOOTSTRAP_PEERS="$BOOTSTRAP" nohup uv run exo > "$LOG_MINI" 2>&1 &
sleep 5

# 5. Verify connection
echo "[5/6] Verifying cluster connection..."
if grep -q "ConnectionEstablished" "$LOG_MINI" 2>/dev/null; then
    echo "  CONNECTED!"
else
    echo "  WARNING: No connection event found yet — check logs"
fi

# 6. Show cluster status
echo "[6/6] Cluster status:"
MINI_PEER_ID=$(grep 'Starting node' "$LOG_MINI" | head -1 | grep -oE '12D3KooW[A-Za-z0-9]+')
echo "  Mini:   $MINI_PEER_ID (Worker)"
echo "  Studio: $STUDIO_PEER_ID (Master)"

# Check API
MODEL_COUNT=$(curl -s http://localhost:52415/v1/models 2>/dev/null | python3 -c "import sys,json; print(len(json.load(sys.stdin).get('data',[])))" 2>/dev/null || echo "0")
echo "  Models available: $MODEL_COUNT"
echo ""
echo "=== Cluster running ==="
echo "  Mini log:   $LOG_MINI"
echo "  Studio log: ssh $STUDIO_HOST 'tail -f $LOG_STUDIO'"
echo "  API:        http://localhost:52415/v1/models"
