# HTTPS/SSL 配置指南

vigilantMonitorServer 现在支持强制使用 HTTPS 协议，提供更安全的通信方式。

## 🔒 功能特性

- ✅ **强制 HTTPS**：完全禁用 HTTP 访问
- ✅ **自动生成证书**：首次启动自动生成自签名证书
- ✅ **证书管理**：提供命令行工具管理 SSL 证书
- ✅ **HTTP 重定向**：可选将 HTTP 请求重定向到 HTTPS
- ✅ **TLS 1.2+**：使用现代化的 TLS 配置和加密套件
- ✅ **ECDSA 支持**：默认使用更快更安全的 ECDSA 密钥

## 📋 配置说明

在 `komari.json` 配置文件中添加 SSL 配置：

```json
{
  "listen": "0.0.0.0:25774",
  "ssl": {
    "enabled": true,
    "cert_file": "./data/ssl/cert.pem",
    "key_file": "./data/ssl/key.pem",
    "auto_generate": true,
    "force_https": true,
    "redirect_to_https": true
  }
}
```

### 配置项说明

| 配置项 | 类型 | 默认值 | 说明 |
|-------|------|--------|------|
| `enabled` | bool | `true` | 是否启用 HTTPS |
| `cert_file` | string | `./data/ssl/cert.pem` | SSL 证书文件路径 |
| `key_file` | string | `./data/ssl/key.pem` | SSL 私钥文件路径 |
| `auto_generate` | bool | `true` | 证书不存在时自动生成自签名证书 |
| `force_https` | bool | `true` | 强制使用 HTTPS，禁用 HTTP |
| `redirect_to_https` | bool | `true` | 将 HTTP 请求重定向到 HTTPS（仅在监听 443 端口时启用 80 端口重定向） |

## 🚀 快速开始

### 方式一：使用自动生成的证书（推荐用于测试）

1. **修改配置文件** `komari.json`：
```json
{
  "ssl": {
    "enabled": true,
    "auto_generate": true,
    "force_https": true
  }
}
```

2. **启动服务器**：
```bash
./vigilantMonitorServer server
```

服务器会自动生成自签名证书并启动 HTTPS 服务。

⚠️ **注意**：自签名证书会在浏览器中显示安全警告，这是正常的。点击"高级"→"继续访问"即可。

### 方式二：使用命令行工具生成证书

```bash
# 生成证书
./vigilantMonitorServer ssl generate \
  --common-name "your-domain.com" \
  --organization "Your Organization" \
  --days 3650

# 查看证书信息
./vigilantMonitorServer ssl info

# 检查证书有效性
./vigilantMonitorServer ssl check
```

### 方式三：使用已有的证书（推荐用于生产环境）

如果你已经有来自可信 CA（如 Let's Encrypt）的证书：

1. **将证书文件放置到指定位置**：
```bash
cp your-cert.pem ./data/ssl/cert.pem
cp your-key.pem ./data/ssl/key.pem
```

2. **修改配置**：
```json
{
  "ssl": {
    "enabled": true,
    "cert_file": "./data/ssl/cert.pem",
    "key_file": "./data/ssl/key.pem",
    "auto_generate": false,
    "force_https": true
  }
}
```

3. **启动服务器**：
```bash
./vigilantMonitorServer server
```

## 🔧 SSL 命令行工具

### 生成证书

```bash
./vigilantMonitorServer ssl generate [flags]

Flags:
  --cert string          证书文件路径（默认：从配置读取）
  --key string           私钥文件路径（默认：从配置读取）
  --common-name string   证书通用名称（默认：vigilant-monitor）
  --organization string  组织名称（默认：Vigilant Monitor）
  --days int            有效期（天）（默认：3650）
  --key-type string     密钥类型：ecdsa 或 rsa（默认：ecdsa）
```

**示例**：
```bash
# 生成 10 年有效期的 ECDSA 证书
./vigilantMonitorServer ssl generate \
  --common-name "monitor.example.com" \
  --organization "Example Corp" \
  --days 3650 \
  --key-type ecdsa

# 生成 RSA 证书
./vigilantMonitorServer ssl generate \
  --key-type rsa \
  --common-name "localhost"
```

### 查看证书信息

```bash
./vigilantMonitorServer ssl info [--cert /path/to/cert.pem]
```

**输出示例**：
```
SSL Certificate Information:
═══════════════════════════════════════════════════════
Subject         : vigilant-monitor
Issuer          : vigilant-monitor
Serial Number   : 123456789...
Valid From      : 2026-01-21T10:00:00Z
Valid Until     : 2036-01-19T10:00:00Z
Is CA           : false
DNS Names       : [localhost *.localhost]
IP Addresses    : [127.0.0.1 ::1]
═══════════════════════════════════════════════════════
```

### 检查证书有效性

```bash
./vigilantMonitorServer ssl check [--cert /path/to/cert.pem] [--key /path/to/key.pem]
```

**输出示例**：
```
Checking SSL certificates...
  Certificate: ./data/ssl/cert.pem
  Private Key: ./data/ssl/key.pem

✓ SSL certificates are valid and ready to use!
```

## 🌐 使用 Let's Encrypt 证书（生产环境推荐）

### 使用 Certbot 获取免费证书

1. **安装 Certbot**：
```bash
# Ubuntu/Debian
sudo apt install certbot

# CentOS/RHEL
sudo yum install certbot
```

2. **获取证书**（需要域名和公网 IP）：
```bash
sudo certbot certonly --standalone -d your-domain.com
```

3. **证书位置**：
```
证书: /etc/letsencrypt/live/your-domain.com/fullchain.pem
私钥: /etc/letsencrypt/live/your-domain.com/privkey.pem
```

4. **配置 vigilantMonitorServer**：
```json
{
  "ssl": {
    "enabled": true,
    "cert_file": "/etc/letsencrypt/live/your-domain.com/fullchain.pem",
    "key_file": "/etc/letsencrypt/live/your-domain.com/privkey.pem",
    "auto_generate": false,
    "force_https": true
  }
}
```

5. **设置自动续期**：
```bash
# 添加到 crontab
sudo crontab -e

# 每月1号凌晨2点检查并续期
0 2 1 * * certbot renew --post-hook "systemctl restart vigilant-monitor"
```

## 🔐 安全最佳实践

### 1. 证书文件权限

确保私钥文件权限正确：
```bash
chmod 600 ./data/ssl/key.pem
chmod 644 ./data/ssl/cert.pem
```

### 2. 使用强密码套件

默认配置已启用安全的密码套件：
- TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384
- TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384
- TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256
- TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256
- TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305
- TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305

### 3. TLS 版本

最低支持 TLS 1.2，不支持过时的 SSL 协议。

### 4. HSTS（推荐）

在反向代理中添加 HSTS 头：
```nginx
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
```

## 🐛 故障排查

### 问题 1：证书警告

**现象**：浏览器显示"您的连接不是私密连接"

**原因**：使用自签名证书

**解决方案**：
- 测试环境：点击"高级"→"继续访问"
- 生产环境：使用 Let's Encrypt 等可信 CA 签发的证书

### 问题 2：证书过期

**现象**：启动失败，日志显示 "certificate expired"

**解决方案**：
```bash
# 重新生成证书
./vigilantMonitorServer ssl generate

# 或设置自动生成
# 在配置中设置 "auto_generate": true
```

### 问题 3：端口被占用

**现象**：启动失败，显示 "address already in use"

**解决方案**：
```bash
# 查看占用端口的进程
lsof -i :25774
netstat -tlnp | grep 25774

# 更改监听端口
# 在配置文件中修改 "listen": "0.0.0.0:8443"
```

### 问题 4：Agent 连接失败

**现象**：Agent 无法连接到 HTTPS 服务器

**解决方案**：

1. **使用自签名证书时**，Agent 需要添加 `--ignore-unsafe-cert` 参数：
```bash
./vigilantMonitor-agent -e https://your-server:25774 -t TOKEN --ignore-unsafe-cert
```

2. **使用可信证书时**，直接连接即可：
```bash
./vigilantMonitor-agent -e https://your-server:25774 -t TOKEN
```

## 📝 配置示例

### 示例 1：开发环境（自签名证书）

```json
{
  "listen": "0.0.0.0:8443",
  "ssl": {
    "enabled": true,
    "cert_file": "./data/ssl/cert.pem",
    "key_file": "./data/ssl/key.pem",
    "auto_generate": true,
    "force_https": true,
    "redirect_to_https": false
  }
}
```

### 示例 2：生产环境（Let's Encrypt）

```json
{
  "listen": "0.0.0.0:443",
  "ssl": {
    "enabled": true,
    "cert_file": "/etc/letsencrypt/live/monitor.example.com/fullchain.pem",
    "key_file": "/etc/letsencrypt/live/monitor.example.com/privkey.pem",
    "auto_generate": false,
    "force_https": true,
    "redirect_to_https": true
  }
}
```

### 示例 3：禁用 HTTPS（不推荐）

```json
{
  "listen": "0.0.0.0:25774",
  "ssl": {
    "enabled": false
  }
}
```

⚠️ **警告**：禁用 HTTPS 会导致数据以明文传输，存在安全风险。仅用于内网测试环境。

## 🔄 迁移指南

### 从 HTTP 迁移到 HTTPS

1. **备份配置**：
```bash
cp komari.json komari.json.bak
```

2. **更新配置**：
```json
{
  "ssl": {
    "enabled": true,
    "auto_generate": true,
    "force_https": true
  }
}
```

3. **重启服务**：
```bash
./vigilantMonitorServer server
```

4. **更新 Agent 连接地址**：
```bash
# 旧方式（HTTP）
./vigilantMonitor-agent -e http://server:25774 -t TOKEN

# 新方式（HTTPS，自签名证书）
./vigilantMonitor-agent -e https://server:25774 -t TOKEN --ignore-unsafe-cert

# 新方式（HTTPS，可信证书）
./vigilantMonitor-agent -e https://server:25774 -t TOKEN
```

## 📚 相关资源

- [Let's Encrypt 官网](https://letsencrypt.org/)
- [Certbot 文档](https://certbot.eff.org/)
- [Mozilla SSL Configuration Generator](https://ssl-config.mozilla.org/)
- [SSL Labs Server Test](https://www.ssllabs.com/ssltest/)

## ❓ 常见问题

**Q: 是否必须使用 HTTPS？**

A: 强烈推荐使用 HTTPS，特别是在生产环境。默认配置已启用 HTTPS。

**Q: 自签名证书安全吗？**

A: 自签名证书提供加密传输，但浏览器无法验证其真实性。适用于内网或开发环境。生产环境建议使用可信 CA 签发的证书。

**Q: 如何获取免费的 SSL 证书？**

A: 使用 [Let's Encrypt](https://letsencrypt.org/)，它提供免费的 90 天有效期证书，支持自动续期。

**Q: 可以同时支持 HTTP 和 HTTPS 吗？**

A: 可以，将 `force_https` 设置为 `false` 即可。但不推荐这样做。

**Q: 监听 443 端口需要 root 权限吗？**

A: 在 Linux 下，监听 1024 以下端口需要 root 权限。建议使用 `setcap` 授权或使用反向代理。

```bash
# 授予绑定特权端口的能力
sudo setcap 'cap_net_bind_service=+ep' ./vigilantMonitorServer
```

## 🔧 技术细节

### TLS 配置

- **最低 TLS 版本**: TLS 1.2
- **密钥交换**: ECDHE（支持前向保密）
- **加密算法**: AES-GCM, ChaCha20-Poly1305
- **默认密钥类型**: ECDSA P-256（更快，密钥更小）
- **RSA 密钥大小**: 最小 2048 位

### 自动生成证书规格

- **算法**: ECDSA P-256
- **有效期**: 10 年
- **用途**: 服务器认证（Server Authentication）
- **DNS 名称**: localhost, *.localhost
- **IP 地址**: 127.0.0.1, ::1

---

如有问题或建议，请提交 Issue 或 Pull Request。
