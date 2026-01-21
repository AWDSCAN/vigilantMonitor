# vigilantMonitor Agent HTTPS 更新完成

## ✅ 更新状态

**日期**: 2026-01-21  
**版本**: 1.1.0  
**状态**: ✅ 编译成功，等待测试

---

## 🎯 完成的修改

### 1. WebSocket 协议自动检测

**文件**: `server/websocket.go`

**修改点**:
- ✅ EstablishWebSocketConnection() - 自动检测 https → wss
- ✅ establishTerminalConnection() - 终端连接支持 wss
- ✅ newWSDialer() - 默认跳过证书验证

**代码变更**:
```go
// 自动检测协议：https -> wss, http -> ws
if strings.HasPrefix(websocketEndpoint, "https") {
    websocketEndpoint = "wss" + strings.TrimPrefix(websocketEndpoint, "https")
} else {
    websocketEndpoint = "ws" + strings.TrimPrefix(websocketEndpoint, "http")
}
```

### 2. 心跳间隔优化

**文件**: `server/websocket.go` (Line 47-49)

**修改**:
```go
// 修改前: 30 秒
heartbeatTicker := time.NewTicker(30 * time.Second)

// 修改后: 10 秒
heartbeatTicker := time.NewTicker(10 * time.Second)
```

### 3. TLS 证书配置

**文件**: `cmd/root.go` (Line 112-120)

**修改**:
```go
// 默认忽略不安全的证书以支持自签名证书（HTTPS）
if flags.IgnoreUnsafeCert || strings.HasPrefix(flags.Endpoint, "https") {
    if http.DefaultTransport.(*http.Transport).TLSClientConfig == nil {
        http.DefaultTransport.(*http.Transport).TLSClientConfig = &tls.Config{}
    }
    http.DefaultTransport.(*http.Transport).TLSClientConfig.InsecureSkipVerify = true
    log.Println("TLS certificate verification disabled for HTTPS connections")
}
```

---

## 📦 编译结果

```bash
✅ 编译成功: vigilantMonitor.exe (Windows x64)
   位置: E:\devops\vigilantMonitor\vigilantMonitor.exe
   大小: ~15-20 MB
```

---

## 🚀 使用方法

### 基本命令

```bash
# 连接到 HTTPS 服务器
.\vigilantMonitor.exe --endpoint https://127.0.0.1:25774 --token YOUR_TOKEN

# 完整命令（推荐）
.\vigilantMonitor.exe \
    --endpoint https://127.0.0.1:25774 \
    --token YOUR_TOKEN \
    --interval 1 \
    --disable-auto-update
```

### 使用测试脚本

```powershell
# Windows PowerShell
cd E:\devops\vigilantMonitor
.\test_https.ps1
```

---

## ✅ 验证清单

### 启动前检查

- [x] vigilantMonitor.exe 已编译
- [x] vigilantMonitorServer HTTPS 服务器运行中
- [x] SSL 证书存在: vigilantMonitorServer/data/ssl/cert.pem
- [x] SSL 证书存在: vigilantMonitorServer/data/ssl/key.pem
- [ ] 获取有效的 Agent Token

### 运行时检查

启动 Agent 后，应该看到：

```
✅ 日志示例:
vigilantMonitor Agent v1.x.x
Github Repo: ...
Using system default DNS resolver
Monitoring Mountpoints: [C:\ D:\]
Monitoring Interfaces: [Ethernet, Wi-Fi]
TLS certificate verification disabled for HTTPS connections
Basic info uploaded successfully
Attempting to connect to WebSocket...
WebSocket connected
```

### 服务器端验证

在 vigilantMonitorServer 日志中查找：

```
✅ 期望日志:
[INFO] 200 POST /api/clients/uploadBasicInfo | 127.0.0.1
[INFO/WS] Client connected: [UUID]
[INFO] 200 GET /api/clients/report | 127.0.0.1
```

### Web 界面验证

1. 访问: https://localhost:5174 (或 https://localhost:5173)
2. 登录管理界面
3. 检查客户端列表
4. 确认 Agent 状态为"在线"
5. 验证数据更新（每秒）
6. 验证心跳状态（每10秒）

---

## 🔧 获取 Agent Token

### 方法1: 手动添加客户端

1. 登录 Web 界面: https://localhost:5174
2. 导航到"客户端管理" → "添加客户端"
3. 填写客户端信息（名称、备注）
4. 保存后获取 Token

### 方法2: 使用 API

```bash
# 使用 API 创建客户端（需要管理员 Token）
curl -k -X POST https://localhost:25774/api/admin/client/add \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Agent",
    "note": "HTTPS Test"
  }'
```

### 方法3: 数据库直接查询

```bash
# 连接 MySQL 查询现有 Token
mysql -u root -p komari_db
mysql> SELECT uuid, name, token FROM clients;
```

---

## 🧪 测试场景

### 场景 1: 本地 HTTPS 连接

```bash
# 1. 启动服务器
cd E:\devops\vigilantMonitorServer
.\vigilantMonitorServer.exe server

# 2. 启动 Agent
cd E:\devops\vigilantMonitor
.\vigilantMonitor.exe --endpoint https://127.0.0.1:25774 --token YOUR_TOKEN --interval 1
```

**期望结果**:
- ✅ Agent 连接成功
- ✅ 数据每秒上报
- ✅ 心跳每10秒发送
- ✅ Web 界面显示在线

### 场景 2: 远程 HTTPS 连接

```bash
# Agent 连接远程服务器
.\vigilantMonitor.exe --endpoint https://your-domain.com:25774 --token YOUR_TOKEN
```

**期望结果**:
- ✅ 自动使用 wss:// 协议
- ✅ 忽略自签名证书
- ✅ 连接稳定

### 场景 3: 心跳测试

```bash
# 启动后观察日志
# 应该每10秒看到心跳活动（WebSocket ping/pong）
```

**期望结果**:
- ✅ 心跳间隔: 10秒
- ✅ 无超时断连
- ✅ 网络中断后自动重连

---

## 📊 性能对比

| 指标 | 修改前 | 修改后 | 改善 |
|------|--------|--------|------|
| **协议支持** | HTTP only | HTTP + HTTPS | ✅ |
| **心跳间隔** | 30秒 | 10秒 | ⚡ 3x |
| **故障检测** | ≤30秒 | ≤10秒 | 🚀 67% |
| **证书处理** | 需手动配置 | 自动处理 | ✅ |
| **WebSocket** | ws:// only | ws:// + wss:// | ✅ |

---

## 🐛 故障排查

### 问题 1: 连接失败

**错误**: `Failed to connect to WebSocket: dial tcp: i/o timeout`

**检查**:
```bash
# 1. 验证服务器运行
curl -k https://localhost:25774/ping
# 应返回: pong

# 2. 检查防火墙
# Windows: 允许入站 TCP 25774
# Linux: sudo ufw allow 25774/tcp

# 3. 检查服务器日志
# 应看到: Starting HTTPS server on 0.0.0.0:25774
```

### 问题 2: 证书错误

**错误**: `x509: certificate signed by unknown authority`

**解决**: ✅ 已自动解决，Agent 默认跳过证书验证

如果仍有问题：
```bash
.\vigilantMonitor.exe --endpoint https://... --token ... --ignore-unsafe-cert
```

### 问题 3: Token 无效

**错误**: `401 Unauthorized` 或 `403 Forbidden`

**解决**:
1. 检查 Token 是否正确（区分大小写）
2. 在 Web 界面重新生成 Token
3. 确认客户端未被禁用

### 问题 4: 频繁断连

**现象**: Agent 反复断开重连

**检查**:
```bash
# 1. 网络稳定性
ping -t your-server.com

# 2. 调整重连参数
.\vigilantMonitor.exe \
    --endpoint https://... \
    --token ... \
    --max-retries 10 \
    --reconnect-interval 15
```

---

## 📁 相关文件

- ✅ [vigilantMonitor\server\websocket.go](e:\devops\vigilantMonitor\server\websocket.go) - 已修改
- ✅ [vigilantMonitor\cmd\root.go](e:\devops\vigilantMonitor\cmd\root.go) - 已修改
- ✅ [vigilantMonitor\vigilantMonitor.exe](e:\devops\vigilantMonitor\vigilantMonitor.exe) - 已编译
- ✅ [vigilantMonitor\test_https.ps1](e:\devops\vigilantMonitor\test_https.ps1) - 测试脚本
- ✅ [vigilantMonitor\HTTPS_AGENT_UPDATE.md](e:\devops\vigilantMonitor\HTTPS_AGENT_UPDATE.md) - 详细文档

---

## 🎯 下一步

1. **获取 Token**: 在 Web 界面创建客户端并获取 Token
2. **运行测试脚本**: `.\test_https.ps1`
3. **验证连接**: 检查 Web 界面客户端状态
4. **监控日志**: 观察心跳和数据上报
5. **部署生产**: 将更新的 Agent 部署到实际服务器

---

## 📚 参考文档

- [HTTPS_AGENT_UPDATE.md](HTTPS_AGENT_UPDATE.md) - 完整更新说明
- [../HTTPS_VERIFICATION.md](../HTTPS_VERIFICATION.md) - 整体 HTTPS 验证
- [../vigilantMonitorServer/HTTPS_SSL_GUIDE.md](../vigilantMonitorServer/HTTPS_SSL_GUIDE.md) - 服务器 SSL 配置
- [../komari-web/HTTPS_FRONTEND_GUIDE.md](../komari-web/HTTPS_FRONTEND_GUIDE.md) - 前端 HTTPS 配置

---

**更新完成时间**: 2026-01-21 13:45  
**编译状态**: ✅ 成功  
**测试状态**: ⏳ 等待验证  
**部署状态**: ⏳ 待部署
