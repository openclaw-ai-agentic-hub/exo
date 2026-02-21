import os
os.chdir(os.path.expanduser("~/exo"))

path1 = "rust/networking/src/swarm.rs"
with open(path1) as f:
    c = f.read()
old1 = chr(32)*4 + "swarm.listen_on(" + chr(34) + "/ip4/0.0.0.0/tcp/0" + chr(34) + ".parse()?)?;"
new1 = chr(32)*4 + "let port = std::env::var(" + chr(34) + "EXO_LIBP2P_PORT" + chr(34) + ").unwrap_or_else(|_| " + chr(34) + "0" + chr(34) + ".to_string());\n" + chr(32)*4 + "let addr = format!(" + chr(34) + "/ip4/0.0.0.0/tcp/{port}" + chr(34) + ");\n" + chr(32)*4 + "swarm.listen_on(addr.parse()?)?;"
if old1 in c:
    c = c.replace(old1, new1)
    with open(path1, "w") as f:
        f.write(c)
    print("OK: swarm.rs patched")
else:
    print("SKIP: swarm.rs not found")

path2 = "rust/exo_pyo3_bindings/src/networking.rs"
with open(path2) as f:
    c = f.read()
marker = chr(32)*4 + "log::info!(" + chr(34) + "RUST: networking task started" + chr(34) + ");"
inject = "\n" + chr(32)*4 + "if let Ok(peers) = std::env::var(" + chr(34) + "EXO_STATIC_PEERS" + chr(34) + ") {\n" + chr(32)*8 + "for addr_str in peers.split(" + chr(34) + "," + chr(34) + ").map(str::trim).filter(|s| " + chr(33) + "s.is_empty()) {\n" + chr(32)*12 + "match addr_str.parse::<libp2p::Multiaddr>() {\n" + chr(32)*16 + "Ok(addr) => {\n" + chr(32)*20 + "log::info!(" + chr(34) + "RUST: dialing static peer: {addr}" + chr(34) + ");\n" + chr(32)*20 + "if let Err(e) = swarm.dial(addr.clone()) {\n" + chr(32)*24 + "log::error!(" + chr(34) + "RUST: failed to dial {addr}: {e}" + chr(34) + ");\n" + chr(32)*20 + "}\n" + chr(32)*16 + "}\n" + chr(32)*16 + "Err(e) => log::error!(" + chr(34) + "RUST: bad static peer addr: {e}" + chr(34) + "),\n" + chr(32)*12 + "}\n" + chr(32)*8 + "}\n" + chr(32)*4 + "}"
if marker in c and "EXO_STATIC_PEERS" not in c:
    c = c.replace(marker, marker + inject, 1)
    with open(path2, "w") as f:
        f.write(c)
    print("OK: networking.rs patched")
elif "EXO_STATIC_PEERS" in c:
    print("SKIP: already patched")
else:
    print("ERROR: marker not found")
