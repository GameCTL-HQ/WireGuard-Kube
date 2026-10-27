# GameCTL WireGuard image — built from scratch so GameCTL/ProxyCTL control
# exactly what runs on the tunnel path. Used by ProxyCTL's per-game gateway
# pods and GameCTL's egress-mode sidecars.
#
# wireguard-tools is built FROM UPSTREAM SOURCE, not from the distro
# package. Debian 12 ships v1.0.20210914; upstream (WireGuard/wireguard-tools
# — github.com/WireGuard/wireguard-tools is a mirror of the official
# git.zx2c4.com/wireguard-tools) has since shipped the fixes this image
# needs, notably wg-quick's no-leak-on-up ordering and the conditional
# src_valid_mark sysctl guard (which the previous image had to sed in by
# hand — that hack is gone now). The source is fetched at a pinned tag with
# a SHA-256 check, so builds are reproducible; bumping upstream is a
# two-arg change (WIREGUARD_TOOLS_REF + WIREGUARD_TOOLS_SHA256).
#
# The WireGuard data plane is the HOST KERNEL's (module/built-in >= 5.6);
# this image only carries the userspace tools (wg, wg-quick) and a minimal
# supervisor that brings up every config in /config/wg_confs — the same
# layout contract as before, so existing manifests only swap the image ref.
#
# Runtime deps: bash (wg-quick + entrypoint shebangs), iptables/iproute2/
# procps (wg-quick's route/firewall helpers). The wg binary links libc only
# (upstream's Linux IPC is raw netlink, no libmnl). Base is Debian 13 (trixie):
# Debian 12's util-linux/zlib/systemd carry unfixed HIGH CVEs (as of the
# 2026-10-27 build) with no bookworm fix available.
FROM debian:13-slim AS build
ARG WIREGUARD_TOOLS_REF=v1.0.20260223
ARG WIREGUARD_TOOLS_SHA256=859f8af03702db5e5c43f8ece77f5ebef40a2f4627c3e03997a031d4940ea9bc
RUN apt-get update \
    && apt-get upgrade -y --no-install-recommends \
    && apt-get install -y --no-install-recommends \
       build-essential pkg-config ca-certificates curl \
    && rm -rf /var/lib/apt/lists/* \
    && curl -fsSL -o /tmp/wireguard-tools.tar.gz \
       "https://github.com/WireGuard/wireguard-tools/archive/refs/tags/${WIREGUARD_TOOLS_REF}.tar.gz" \
    && echo "${WIREGUARD_TOOLS_SHA256}  /tmp/wireguard-tools.tar.gz" | sha256sum -c - \
    && mkdir /src \
    && tar -xzf /tmp/wireguard-tools.tar.gz -C /src --strip-components=1 \
    && rm /tmp/wireguard-tools.tar.gz \
    && make -C /src/src \
    && make -C /src/src install DESTDIR=/out WITH_WGQUICK=yes

FROM debian:13-slim
RUN apt-get update \
    && apt-get upgrade -y --no-install-recommends \
    && apt-get install -y --no-install-recommends \
       bash iptables iproute2 procps \
    && rm -rf /var/lib/apt/lists/*
COPY --from=build /out/usr/bin/wg /usr/bin/wg
COPY --from=build /out/usr/bin/wg-quick /usr/bin/wg-quick
COPY entrypoint.sh /usr/local/bin/entrypoint
RUN chmod +x /usr/local/bin/entrypoint

ENTRYPOINT ["/usr/local/bin/entrypoint"]
