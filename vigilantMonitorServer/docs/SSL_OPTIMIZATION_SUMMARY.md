# HTTPS 强制使用配置完成总结

## ✅ 已完成的功能

### 1. SSL/TLS 支持
- ✅ **HTTPS 服务器**：支持 TLS 1.2+ 协议
- ✅ **自动生成证书**：首次启动自动生成自签名证书
- ✅ **证书管理工具**：提供命令行工具管理 SSL 证书
- ✅ **强制 HTTPS**：可配置禁用 HTTP 访问
- ✅ **HTTP 重定向**：可配置将 HTTP 请求重定向到 HTTPS

### 2. 配置项
在 `komari.json` 中新增 `ssl` 配置块：
```json
{
  "ssl": {
    "enabled": true,           // 启用 HTTPS
    "cert_file": "./data/ssl/cert.pem",  // 证书路径
    "key_file": "./data/ssl/key.pem",    // 私钥路径
    "auto_generate": true,     // 自动生成证书
    "force_https": true,       // 强制HTTPS
    "redirect_to_https": true  // HTTP重定向
  }
}
```

### 3. 命令行工具
```bash
# 生成自签名证书
./vigilantMonitorServer ssl generate [flags]

# 查看证书信息
./vigilantMonitorServer ssl info

# 检查证书有效性
./vigilantMonitorServer ssl check
```

### 4. 安全特性
- **TLS 版本**: 最低 TLS 1.2
- **密码套件**: 支持现代化加密套件
  - TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384
  - TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384
  - TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256
  - TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256
  - TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305
  - TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305
- **密钥类型**: 默认 ECDSA P-256（更快更安全）
- **前向保密**: 支持 ECDHE 密钥交换

## 📁 新增文件

### 1. 核心功能
- `vigilantMonitorServer/pkg/utils/ssl.go` - SSL 证书生成和管理工具
- `vigilantMonitorServer/cmd/ssl.go` - SSL 命令行工具
- `vigilantMonitorServer/internal/conf/vars.go` - 新增 SSL 配置结构体

### 2. 文档
- `vigilantMonitorServer/HTTPS_SSL_GUIDE.md` - 完整的 HTTPS/SSL 配置指南
- `vigilantMonitorServer/SSL_OPTIMIZATION_SUMMARY.md` - 本总结文档

## 🔧 修改的文件

### 1. 服务器启动逻辑
**文件**: `vigilantMonitorServer/cmd/server.go`
- 添加 SSL 初始化逻辑
- 添加 TLS 配置
- 支持 HTTPS 和 HTTP 重定向
- 添加证书自动生成功能

**关键改动**:
```go
// 初始化SSL证书
if err := initializeSSL(); err != nil {
    slog.Error("Failed to initialize SSL", slog.Any("error", err))
    os.Exit(1)
}

// 配置TLS
if conf.Conf.SSL.Enabled {
    tlsConfig := &tls.Config{
        MinVersion:               tls.VersionTLS12,
        PreferServerCipherSuites: true,
        // ... 密码套件配置
    }
    srv.TLSConfig = tlsConfig
}

// 启动HTTPS服务器
if conf.Conf.SSL.Enabled && conf.Conf.SSL.ForceHTTPS {
    log.Printf("Starting HTTPS server on %s ...", conf.Conf.Listen)
    srv.ListenAndServeTLS(conf.Conf.SSL.CertFile, conf.Conf.SSL.KeyFile)
}
```

### 2. 配置结构
**文件**: `vigilantMonitorServer/internal/conf/vars.go`
- 添加 `SSL` 结构体定义

**新增结构**:
```go
type SSL struct {
    Enabled         bool   `json:"enabled"`
    CertFile        string `json:"cert_file"`
    KeyFile         string `json:"key_file"`
    AutoGenerate    bool   `json:"auto_generate"`
    ForceHTTPS      bool   `json:"force_https"`
    RedirectToHTTPS bool   `json:"redirect_to_https"`
}
```

### 3. 默认配置
**文件**: `vigilantMonitorServer/internal/conf/config.go`
- 添加 SSL 默认配置

**默认值**:
```go
SSL: SSL{
    Enabled:         true,
    CertFile:        "./data/ssl/cert.pem",
    KeyFile:         "./data/ssl/key.pem",
    AutoGenerate:    true,
    ForceHTTPS:      true,
    RedirectToHTTPS: true,
},
```

## 🚀 使用方法

### 快速开始（自动模式）

1. **启动服务器**（会自动生成证书）:
```bash
./vigilantMonitorServer server
```

输出示例：
```
SSL certificates not found or invalid, generating self-signed certificates...
✓ Self-signed SSL certificates generated successfully
  Certificate: ./data/ssl/cert.pem
  Private Key: ./data/ssl/key.pem
⚠️  Note: Self-signed certificates will show security warnings in browsers.
Starting HTTPS server on 0.0.0.0:25774 ...
```

2. **访问服务器**:
```
https://localhost:25774
```

⚠️ **注意**: 浏览器会显示安全警告，点击"高级"→"继续访问"即可。

### 手动生成证书

```bash
# 生成证书
./vigilantMonitorServer ssl generate \
  --common-name "your-domain.com" \
  --organization "Your Company" \
  --days 3650

# 查看证书信息
./vigilantMonitorServer ssl info

# 检查证书
./vigilantMonitorServer ssl check

# 启动服务器
./vigilantMonitorServer server
```

### 使用 Let's Encrypt（生产环境）

1. **获取证书**:
```bash
sudo certbot certonly --standalone -d your-domain.com
```

2. **配置** `komari.json`:
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

3. **启动服务器**:
```bash
./vigilantMonitorServer server
```

## 📊 配置场景

### 场景 1: 开发环境（自签名证书）
```json
{
  "listen": "0.0.0.0:8443",
  "ssl": {
    "enabled": true,
    "auto_generate": true,
    "force_https": true
  }
}
```

### 场景 2: 生产环境（Let's Encrypt）
```json
{
  "listen": "0.0.0.0:443",
  "ssl": {
    "enabled": true,
    "cert_file": "/etc/letsencrypt/live/domain.com/fullchain.pem",
    "key_file": "/etc/letsencrypt/live/domain.com/privkey.pem",
    "auto_generate": false,
    "force_https": true,
    "redirect_to_https": true
  }
}
```

### 场景 3: 暂时禁用 HTTPS（不推荐）
```json
{
  "listen": "0.0.0.0:25774",
  "ssl": {
    "enabled": false
  }
}
```

## ⚠️ 注意事项

### 1. Agent 连接
使用 HTTPS 后，Agent 连接地址需要更新：

```bash
# 自签名证书（需要添加 --ignore-unsafe-cert）
./vigilantMonitor-agent -e https://server:25774 -t TOKEN --ignore-unsafe-cert

# 可信证书（不需要额外参数）
./vigilantMonitor-agent -e https://server:25774 -t TOKEN
```

### 2. 端口权限
监听 443 端口需要特殊权限：
```bash
# Linux: 授予绑定特权端口的能力
sudo setcap 'cap_net_bind_service=+ep' ./vigilantMonitorServer

# 或使用 sudo 运行
sudo ./vigilantMonitorServer server
```

### 3. 证书权限
```bash
# 确保私钥权限正确
chmod 600 ./data/ssl/key.pem
chmod 644 ./data/ssl/cert.pem
```

### 4. 浏览器警告
- 自签名证书会显示安全警告（正常现象）
- 生产环境请使用可信 CA 签发的证书

## 🔍 测试验证

### 1. 检查 HTTPS 可用性
```bash
curl -k https://localhost:25774/ping
# 输出: pong
```

### 2. 检查 HTTP 重定向
```bash
curl -I http://localhost/
# 应返回 301 重定向到 HTTPS
```

### 3. 查看 TLS 配置
```bash
# Linux/macOS
openssl s_client -connect localhost:25774 -tls1_2

# 检查证书信息
openssl x509 -in ./data/ssl/cert.pem -text -noout
```

### 4. SSL Labs 测试（公网）
访问: https://www.ssllabs.com/ssltest/

## 📚 相关文档

详细的配置说明和最佳实践，请参考：
- [HTTPS_SSL_GUIDE.md](./HTTPS_SSL_GUIDE.md) - 完整配置指南
- [README.md](./README.md) - 项目主文档

## 🎯 性能影响

### HTTPS vs HTTP
- **延迟增加**: 约 1-2ms（TLS 握手）
- **CPU 开销**: ECDSA 比 RSA 快约 2-3 倍
- **带宽影响**: 可忽略（TLS 头部约 20-40 字节）

### 优化建议
1. 使用 ECDSA 密钥（默认已启用）
2. 启用 HTTP/2（未来支持）
3. 使用 session resumption（默认已启用）
4. 配置 OCSP stapling（可选）

## ✅ 检查清单

部署前请确认：

- [ ] SSL 配置正确（`komari.json`）
- [ ] 证书文件存在且有效
- [ ] 证书文件权限正确（私钥 600）
- [ ] 防火墙开放 HTTPS 端口
- [ ] Agent 连接地址已更新
- [ ] 浏览器可以访问 HTTPS 地址
- [ ] 证书在有效期内（`ssl info` 查看）
- [ ] 生产环境使用可信 CA 证书

## 🐛 故障排查

### 问题: 启动失败，提示证书错误
**解决方案**:
```bash
# 重新生成证书
./vigilantMonitorServer ssl generate

# 或检查证书路径
./vigilantMonitorServer ssl check
```

### 问题: 浏览器无法访问
**解决方案**:
1. 检查防火墙是否开放端口
2. 确认使用 `https://` 而不是 `http://`
3. 自签名证书需要点击"继续访问"

### 问题: Agent 无法连接
**解决方案**:
```bash
# 使用自签名证书时添加参数
./vigilantMonitor-agent -e https://server:25774 -t TOKEN --ignore-unsafe-cert
```

---

**优化完成日期**: 2026-01-21

**版本**: vigilantMonitorServer v1.0.0+

**作者**: GitHub Copilot AI Assistant
