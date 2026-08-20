# useful-caddy

在国内网络环境中，自行构建带插件的 Caddy 往往比较麻烦：不仅拉取 Caddy 基础镜像需要代理，Dockerfile 构建阶段运行的 `xcaddy` 也需要访问 GitHub 和 Go 模块源。与其在每台服务器上为整条构建链路配置代理，本项目直接通过 GitHub Actions 构建包含我常用功能的多架构成品镜像；部署时只需为 GHCR 镜像拉取配置加速代理，然后使用 `ghcr.io/qiudeng7/useful-caddy` 即可。

镜像内置：

- [AliDNS](https://github.com/caddy-dns/alidns)
- [Cloudflare DNS](https://github.com/caddy-dns/cloudflare)
- [腾讯云 DNSPod](https://github.com/caddy-dns/tencentcloud)
- [caddy-l4](https://github.com/mholt/caddy-l4)，提供 TCP/UDP 四层代理能力

## 使用镜像

```bash
docker pull ghcr.io/qiudeng7/useful-caddy:latest
docker run --rm ghcr.io/qiudeng7/useful-caddy:latest caddy list-modules
```

镜像保持与 Caddy 官方 Docker 镜像相同的入口、配置目录和数据目录，可以直接替换官方镜像：

```yaml
services:
  caddy:
    image: ghcr.io/qiudeng7/useful-caddy:latest
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
      - "443:443/udp"
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile:ro
      - caddy_data:/data
      - caddy_config:/config

volumes:
  caddy_data:
  caddy_config:
```

生产环境建议固定版本标签，避免 `latest` 更新带来意外变化。

## DNS 插件配置

凭证建议通过环境变量注入，不要直接写入 Caddyfile 或提交到 Git。

### AliDNS

```caddyfile
example.com {
    tls {
        dns alidns {
            access_key_id {env.ALIYUN_ACCESS_KEY_ID}
            access_key_secret {env.ALIYUN_ACCESS_KEY_SECRET}
        }
    }

    respond "Hello from Caddy"
}
```

### Cloudflare

API Token 至少需要目标域名的 `Zone:Read` 和 `DNS:Edit` 权限。

```caddyfile
example.com {
    tls {
        dns cloudflare {env.CF_API_TOKEN}
    }

    respond "Hello from Caddy"
}
```

### 腾讯云 DNSPod

```caddyfile
example.com {
    tls {
        dns tencentcloud {
            secret_id {env.TENCENTCLOUD_SECRET_ID}
            secret_key {env.TENCENTCLOUD_SECRET_KEY}
        }
    }

    respond "Hello from Caddy"
}
```

## Layer 4

`caddy-l4` 支持通过 Caddyfile 或 JSON 配置 TCP/UDP 转发、TLS SNI 匹配和协议探测。该插件仍处于快速迭代阶段，配置前请查看其[最新文档和示例](https://github.com/mholt/caddy-l4/tree/master/docs)。

下面的全局配置会把 `:5432` 的 TCP 流量转发到 PostgreSQL：

```caddyfile
{
    layer4 {
        :5432 {
            route {
                proxy postgres:5432
            }
        }
    }
}
```

## 构建与发布

GitHub Actions 会分别使用 GitHub 托管的 x64 和 ARM64 Runner 原生构建 `linux/amd64`、`linux/arm64` 镜像，然后合并多架构 manifest。整个流程不使用 QEMU 模拟。

工作流会在以下情况运行：

- 推送到 `main`：发布 `latest` 和 `sha-<commit>`
- 推送 `v*` 标签：发布同名版本标签和 `sha-<commit>`
- 每周一自动重建：获取基础镜像的安全修复
- 手动触发 workflow
- Pull Request：只验证构建，不推送镜像

当前构建版本见 [Dockerfile](./Dockerfile)。更新版本后推送即可触发新镜像构建。

本地构建：

```bash
docker build -t useful-caddy:local .
docker run --rm useful-caddy:local caddy list-modules --versions
```

## License

[MIT](./LICENSE)
