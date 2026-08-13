# syntax=docker/dockerfile:1

ARG CADDY_VERSION=2.11.4

FROM caddy:${CADDY_VERSION}-builder AS builder

ARG ALIDNS_VERSION=v1.0.29
ARG CLOUDFLARE_VERSION=v0.2.4
ARG TENCENTCLOUD_VERSION=v0.4.3
ARG LAYER4_VERSION=v0.1.2

RUN xcaddy build \
    --with github.com/caddy-dns/alidns@${ALIDNS_VERSION} \
    --with github.com/caddy-dns/cloudflare@${CLOUDFLARE_VERSION} \
    --with github.com/caddy-dns/tencentcloud@${TENCENTCLOUD_VERSION} \
    --with github.com/mholt/caddy-l4@${LAYER4_VERSION} \
    && caddy list-modules | grep -Fxq 'dns.providers.alidns' \
    && caddy list-modules | grep -Fxq 'dns.providers.cloudflare' \
    && caddy list-modules | grep -Fxq 'dns.providers.tencentcloud' \
    && caddy list-modules | grep -Fxq 'layer4.handlers.proxy'

FROM caddy:${CADDY_VERSION}-alpine

COPY --from=builder /usr/bin/caddy /usr/bin/caddy

