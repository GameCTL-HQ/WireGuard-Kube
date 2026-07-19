#!/bin/bash
# GameCTL WireGuard entrypoint. Brings up every interface configured in
# /config/wg_confs/*.conf (wg0.conf -> wg0), then supervises: a TERM/INT
# takes the tunnels down cleanly so conntrack state on the peers ages out
# instead of holding half-open flows.
set -euo pipefail

CONF_DIR=/config/wg_confs
mkdir -p "$CONF_DIR"

shopt -s nullglob
confs=("$CONF_DIR"/*.conf)
if [ "${#confs[@]}" -eq 0 ]; then
  echo "ERROR: no WireGuard config found in $CONF_DIR" >&2
  exit 1
fi

ifaces=()
for c in "${confs[@]}"; do
  echo "wireguard: bringing up $(basename "$c")"
  wg-quick up "$c"
  ifaces+=("$(basename "$c" .conf)")
done

down() {
  for i in "${ifaces[@]}"; do
    wg-quick down "$CONF_DIR/$i.conf" 2>/dev/null || true
  done
  exit 0
}
trap down TERM INT

echo "wireguard: up (${ifaces[*]}) — supervising"
# Sleep-loop instead of `sleep infinity` so the trap fires promptly.
while :; do sleep 5 & wait $!; done
