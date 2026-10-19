# syntax=docker/dockerfile:1

ARG CADDY_VERSION=2.11.7

FROM caddy:${CADDY_VERSION}-builder AS builder

ARG CLOUDFLARE_VERSION=v0.2.4
ARG TENCENTCLOUD_VERSION=v0.4.3
ARG LAYER4_VERSION=v0.1.2
ARG ESA_VERSION=2292460005f95452bfca6d8e5fd4fa0e3ca2330f

RUN xcaddy build \
    --with github.com/nuln/caddy-plugins/alidns@${ESA_VERSION} \
    --with github.com/caddy-dns/cloudflare@${CLOUDFLARE_VERSION} \
    --with github.com/caddy-dns/tencentcloud@${TENCENTCLOUD_VERSION} \
    --with github.com/mholt/caddy-l4@${LAYER4_VERSION} \
    && caddy list-modules | grep -Fxq 'dns.providers.alidns' \
    && caddy list-modules | grep -Fxq 'dns.providers.cloudflare' \
    && caddy list-modules | grep -Fxq 'dns.providers.tencentcloud' \
    && caddy list-modules | grep -Fxq 'layer4.handlers.proxy' \
    && caddy list-modules | grep -Fxq 'dns.providers.esa'

FROM caddy:${CADDY_VERSION}-alpine

COPY --from=builder /usr/bin/caddy /usr/bin/caddy

