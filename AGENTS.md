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

## SSH Access
- **Studio:** `ssh studio` (alias configured in `~/.ssh/config`)
  - Account: `openclaw-agent@100.107.179.94`
  - Key: `~/.ssh/id_studio` (Ed25519, dedicated key)
- **Mini:** `ssh aihub@100.99.164.42`

## LaunchDaemons (Auto-Start)
Both machines run exo via LaunchDaemons with `KeepAlive` and `RunAtLoad` enabled:
- **Mini (Worker):** `ai.exo.worker` — `/Library/LaunchDaemons/ai.exo.worker.plist`
- **Studio (Master):** `ai.exo.master` — `/Library/LaunchDaemons/ai.exo.master.plist`

## Key Commands
- Restart Mini: `sudo launchctl bootout system/ai.exo.worker && sudo launchctl bootstrap system /Library/LaunchDaemons/ai.exo.worker.plist`
- Restart Studio: `sudo launchctl bootout system/ai.exo.master && sudo launchctl bootstrap system /Library/LaunchDaemons/ai.exo.master.plist`
- Test API: `curl http://100.107.179.94:52415/v1/models`

## Current Status
Exo cluster is running as LaunchDaemons but **parked as a future upgrade path** — standalone Ollama on the Studio handles current workloads fine.
- **Ollama tunnel:** Port 11434 forwards to standalone Ollama on Studio for local inference
- **Ollama path on Studio:** `/opt/homebrew/bin/ollama` (full path required)
- **Confirmed working:** `llama3.1:8b` and `llama3.1:70b` via standalone Ollama

## Cedar Authorization Rules (37+ custom rules)
Policy enforcement via Cedar for agent tool usage:
- **permit-ssh-studio-readonly** — allows `ps`, `vm_stat`, `top`, `df`, `uptime`, `tail` (logs), `curl` on Studio
- **permit-ssh-studio-ollama** — allows `ollama list`, `ollama ps`, `ollama pull`, `ollama stop`, `ollama run` on Studio
- **forbid-ssh-studio-destructive** — blocks `rm`, `kill`, `sudo`, `brew`, `pip`, `launchctl`, `chmod`, `chown`, etc. on Studio
- **Obsidian vault permits** — Cedar rules for Obsidian vault file access
- **Web search** — enabled via Brave API key in gateway LaunchDaemon env vars

## Sondera Integration
- Path normalization fix applied in `index.ts`

## Development Notes
- Base branch for PRs: `main`
- Our working branch: `openclaw`
- When modifying Rust code, rebuild with `cargo build` from the repo root
- The cluster uses libp2p for peer-to-peer communication between nodes
