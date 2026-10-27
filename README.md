# WireGuard-Kube

From-scratch WireGuard image for Kubernetes, built for
[GameCTL](https://github.com/GameCTL-HQ/GameCTL) /
[ProxyCTL](https://github.com/GameCTL-HQ/ProxyCTL) tunnel pods:
ProxyCTL's per-game gateway pods and GameCTL's egress-mode game sidecars.

- **Sources:** Debian's official base; `wireguard-tools` built **from
  upstream source** (WireGuard/wireguard-tools at a pinned, SHA-256-checked
  tag) rather than the distro package, so upstream fixes (e.g. wg-quick's
  no-leak-on-up ordering, the conditional `src_valid_mark` guard) ship
  without waiting on a distro repack. The data plane is the **host
  kernel's** WireGuard (built-in since 5.6); this image carries only the
  userspace tools.
- **Contract:** brings up every `/config/wg_confs/*.conf` with `wg-quick`
  (`wg0.conf` → `wg0`), takes them down cleanly on pod stop.
- **Security posture:** base is Debian 13 (trixie) slim. The 2026-10-27
  Trivy scan (CRITICAL/HIGH) reports 31 findings, all in packages at their
  current stable versions with no distro fix available yet (util-linux
  2.41.5, systemd 257.13, ncurses 6.5, libacl, perl-base); none are
  reachable from this container's input surface (wg-quick invokes only
  iptables/ip/sysctl; systemd, ncurses-TTY, perl never run). Zero secrets,
  zero misconfig. Re-scan after each base rebuild and re-verify the floor.
- **Requirements:** the pod needs `NET_ADMIN`; full-tunnel configs also want
  `net.ipv4.conf.all.src_valid_mark=1` (ProxyCTL/GameCTL set it via a
  privileged init container).

Image: `ghcr.io/gamectl-hq/wireguard-kube` (Actions-built).
