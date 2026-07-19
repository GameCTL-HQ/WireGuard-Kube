# GameCTL WireGuard image — built from scratch so GameCTL/ProxyCTL control
# exactly what runs on the tunnel path. Used by ProxyCTL's per-game gateway
# pods and GameCTL's egress-mode sidecars.
#
# Sources: Debian's official base and Debian's own wireguard-tools. The
# WireGuard data plane is the HOST KERNEL's (module/built-in >= 5.6); this
# image only carries the userspace tools (wg, wg-quick) and a minimal
# supervisor that brings up every config in /config/wg_confs — the same
# layout contract as before, so existing manifests only swap the image ref.
FROM debian:12-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       wireguard-tools iptables iproute2 procps \
    && rm -rf /var/lib/apt/lists/* \
    # In an unprivileged container /proc/sys is read-only, so wg-quick's
    # unconditional src_valid_mark write fails even when a privileged init
    # already set it. Make it conditional (upstream gained the same guard
    # after the version Debian 12 ships).
    && sed -i 's|\[\[ $proto == -4 \]\] && cmd sysctl -q net.ipv4.conf.all.src_valid_mark=1|[[ $proto == -4 ]] \&\& [[ $(sysctl -n net.ipv4.conf.all.src_valid_mark 2>/dev/null) != 1 ]] \&\& cmd sysctl -q net.ipv4.conf.all.src_valid_mark=1|' /usr/bin/wg-quick \
    && grep -q 'sysctl -n net.ipv4.conf.all.src_valid_mark' /usr/bin/wg-quick

COPY entrypoint.sh /usr/local/bin/entrypoint
RUN chmod +x /usr/local/bin/entrypoint

ENTRYPOINT ["/usr/local/bin/entrypoint"]
