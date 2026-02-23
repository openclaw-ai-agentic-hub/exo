# Exo Cluster - OpenClaw Infrastructure

## What This Is
Distributed ML inference cluster running Llama 3.3 70B across two Apple Silicon machines connected via Tailscale. This is a fork maintained by the openclaw-ai-agentic-hub GitHub org, with custom patches on the `openclaw` branch.

## Architecture
- **Studio (Master):** Mac Studio M3 Ultra, 96GB unified memory, Tailscale IP `100.107.179.94`
- **Mini (Worker):** Mac Mini M4 Pro, 24GB unified memory, Tailscale IP `100.99.164.42`
- **Combined:** 120GB unified memory for 70B parameter inference
- **API Endpoint:** `http://100.107.179.94:52415/v1` (OpenAI-compatible)

## Our Patches (branch: openclaw)
- `rust/exo_pyo3_bindings/src/networking.rs` — `EXO_STATIC_PEERS` static peer dial (bypasses mDNS discovery for Tailscale)
- `rust/networking/src/swarm.rs` — `EXO_LIBP2P_PORT` fixed libp2p listen port
- `src/exo/utils/info_gatherer/net_profile.py` — loopback interface filter (prevents self-dial)
- Launch scripts: `start_exo.sh` on each machine

## Key Commands
- Start Studio: `ssh aihub@100.107.179.94 'bash ~/exo/start_exo.sh'`
- Start Mini: `ssh aihub@100.99.164.42 'bash ~/exo/start_exo.sh'`
- Test API: `curl http://100.107.179.94:52415/v1/models`

## Development Notes
- Base branch for PRs: `main`
- Our working branch: `openclaw`
- When modifying Rust code, rebuild with `cargo build` from the repo root
- The cluster uses libp2p for peer-to-peer communication between nodes
