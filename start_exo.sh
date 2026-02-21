#!/bin/bash
export EXO_STATIC_PEERS="/ip4/100.107.179.94/tcp/51400"
export EXO_LIBP2P_NAMESPACE=loyal-test-1
cd ~/exo
pkill -9 -f "python.*exo" 2>/dev/null
sleep 2
rm -f /tmp/exo.log
nohup .venv/bin/python -m exo --api-port 52415 -v > /tmp/exo.log 2>&1 &
echo "Exo started PID: $!"
