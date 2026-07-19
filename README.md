# WireGuard-Kube

From-scratch WireGuard image for Kubernetes, built for
[GameCTL](https://github.com/GameCTL-HQ/GameCTL) /
[ProxyCTL](https://github.com/GameCTL-HQ/ProxyCTL) tunnel pods:
ProxyCTL's per-game gateway pods and GameCTL's egress-mode game sidecars.

- **Sources:** Debian's official base and Debian's own `wireguard-tools` —
  no community images. The data plane is the **host kernel's** WireGuard
  (built-in since 5.6); this image carries only the userspace tools.
- **Contract:** brings up every `/config/wg_confs/*.conf` with `wg-quick`
  (`wg0.conf` → `wg0`), takes them down cleanly on pod stop. Needs
  `NET_ADMIN`; full-tunnel configs also want
  `net.ipv4.conf.all.src_valid_mark=1` (ProxyCTL/GameCTL set it via a
  privileged init container).

Image: `ghcr.io/gamectl-hq/wireguard-kube` (Actions-built).
