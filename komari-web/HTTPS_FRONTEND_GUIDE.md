# 前端 HTTPS 配置指南

## 概述

komari-web 前端开发服务器现已支持 HTTPS，自动复用后端生成的 SSL 证书。

## 🔧 自动配置（推荐）

### 前提条件

后端已生成 SSL 证书：
```bash
cd ../vigilantMonitorServer
./vigilantMonitorServer ssl generate
```

### 启动步骤

1. **确认证书存在**：
```bash
# Windows
dir ..\vigilantMonitorServer\data\ssl\

# Linux/macOS
ls -la ../vigilantMonitorServer/data/ssl/
```

应该看到：
- `cert.pem` - SSL 证书
- `key.pem` - 私钥

2. **启动开发服务器**：
```bash
npm run dev
```

3. **访问**：
```
https://localhost:5173
```

⚠️ **注意**：使用自签名证书时，浏览器会显示安全警告，点击"高级"→"继续访问"即可。

## 📝 工作原理

### 自动检测

`vite.config.ts` 会自动：
1. 检查 `../vigilantMonitorServer/data/ssl/` 下是否有证书
2. 如果存在，启用 HTTPS
3. 如果不存在，回退到 HTTP 模式

### 证书路径

```typescript
const sslCertPath = "../vigilantMonitorServer/data/ssl/cert.pem"
const sslKeyPath = "../vigilantMonitorServer/data/ssl/key.pem"
```

### 代理配置

```typescript
proxy: {
  "/api": {
    target: "https://127.0.0.1:25774",  // HTTPS后端
    secure: false,  // 允许自签名证书
  }
}
```

## 🎛️ 环境变量配置

### 创建配置文件

复制示例文件：
```bash
cp .env.development.example .env.development
```

### 编辑配置

`.env.development`:
```bash
# 使用 HTTPS 后端
VITE_API_TARGET=https://127.0.0.1:25774

# 或使用 HTTP 后端
# VITE_API_TARGET=http://127.0.0.1:25774
```

## 📊 配置场景

### 场景 1: 完整 HTTPS（推荐）

**后端**：使用 HTTPS（25774 端口）  
**前端**：使用 HTTPS（5173 端口）

```bash
# 1. 后端生成证书并启动
cd vigilantMonitorServer
./vigilantMonitorServer ssl generate
./vigilantMonitorServer server

# 2. 前端启动（自动使用证书）
cd ../komari-web
npm run dev

# 3. 访问
https://localhost:5173
```

### 场景 2: 后端 HTTPS + 前端 HTTP

**后端**：使用 HTTPS  
**前端**：使用 HTTP（临时开发）

```bash
# 1. 删除或重命名证书（临时）
cd vigilantMonitorServer/data/ssl
mv cert.pem cert.pem.bak
mv key.pem key.pem.bak

# 2. 修改环境变量
# .env.development
VITE_API_TARGET=https://127.0.0.1:25774

# 3. 启动前端
cd ../../komari-web
npm run dev

# 4. 访问
http://localhost:5173
```

### 场景 3: 全部 HTTP（不推荐）

**后端**：禁用 SSL  
**前端**：HTTP

```json
// vigilantMonitorServer/data/komari.json
{
  "ssl": {
    "enabled": false
  }
}
```

```bash
# .env.development
VITE_API_TARGET=http://127.0.0.1:25774
```

## 🔍 启动日志

### HTTPS 模式（成功）

```
  VITE v5.0.0  ready in 500 ms

  ➜  Local:   https://localhost:5173/
  ➜  Network: use --host to expose
  ➜  press h + enter to show help
  
  ✓ HTTPS enabled for Vite dev server
    Certificate: E:\devops\vigilantMonitorServer\data\ssl\cert.pem
    Private Key: E:\devops\vigilantMonitorServer\data\ssl\key.pem
```

### HTTP 模式（回退）

```
  VITE v5.0.0  ready in 500 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
  
  ⚠️  SSL certificates not found, running HTTP mode
    Expected cert: E:\devops\vigilantMonitorServer\data\ssl\cert.pem
    Expected key: E:\devops\vigilantMonitorServer\data\ssl\key.pem
    Run: cd ../vigilantMonitorServer && ./vigilantMonitorServer ssl generate
```

## 🐛 故障排查

### 问题 1: 证书错误

**现象**：
```
Error: ENOENT: no such file or directory
```

**解决方案**：
```bash
cd ../vigilantMonitorServer
./vigilantMonitorServer ssl generate
cd ../komari-web
npm run dev
```

### 问题 2: 端口被占用

**现象**：
```
Port 5173 is in use
```

**解决方案**：
```bash
# 查找占用进程
netstat -ano | findstr :5173

# 杀死进程
taskkill /PID <进程ID> /F

# 或使用其他端口
npm run dev -- --port 5174
```

### 问题 3: 代理错误

**现象**：
```
[vite] http proxy error: UNABLE_TO_VERIFY_LEAF_SIGNATURE
```

**解决方案**：
确保代理配置中有 `secure: false`（已默认配置）

### 问题 4: 浏览器安全警告

**现象**：浏览器显示"您的连接不是私密连接"

**解决方案**：
1. 点击"高级"
2. 点击"继续访问 localhost（不安全）"
3. 这是自签名证书的正常行为

### 问题 5: WebSocket 连接失败

**现象**：
```
WebSocket connection failed
```

**解决方案**：
确保后端也在运行 HTTPS：
```bash
cd ../vigilantMonitorServer
./vigilantMonitorServer server
```

## 🔐 生产环境

### 构建配置

生产环境不需要证书（由 Web 服务器处理）：

```bash
npm run build
```

生成的静态文件在 `dist/` 目录。

### Nginx 配置示例

```nginx
server {
    listen 443 ssl http2;
    server_name your-domain.com;
    
    ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;
    
    root /path/to/komari-web/dist;
    index index.html;
    
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    location /api {
        proxy_pass https://127.0.0.1:25774;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_ssl_verify off;  # 如果后端使用自签名证书
    }
    
    location /themes {
        proxy_pass https://127.0.0.1:25774;
        proxy_set_header Host $host;
        proxy_ssl_verify off;
    }
}
```

## 📚 相关配置文件

- `vite.config.ts` - Vite 配置（包含 HTTPS 设置）
- `.env.development` - 开发环境变量
- `.env.development.example` - 环境变量示例
- `../vigilantMonitorServer/data/ssl/` - SSL 证书目录

## 🎯 最佳实践

### 开发环境

1. ✅ 使用自签名证书
2. ✅ 前后端都用 HTTPS
3. ✅ 配置 `secure: false` 允许自签名证书
4. ✅ 添加浏览器安全例外

### 生产环境

1. ✅ 使用可信 CA 证书（Let's Encrypt）
2. ✅ 通过 Nginx/Apache 处理 HTTPS
3. ✅ 启用 HSTS
4. ✅ 配置 HTTP → HTTPS 重定向

## ⚡ 性能提示

### HTTP/2

Vite 开发服务器支持 HTTP/2（需要 HTTPS）：
- 多路复用
- 头部压缩
- 服务器推送

### 热更新

HTTPS 不影响 HMR（热模块替换）速度。

## 🔄 更新证书

如果证书过期或需要更新：

```bash
# 1. 重新生成证书
cd vigilantMonitorServer
./vigilantMonitorServer ssl generate --days 3650

# 2. 重启前端开发服务器
cd ../komari-web
# Ctrl+C 停止
npm run dev
```

## ✅ 检查清单

部署前确认：

- [ ] 后端 SSL 证书已生成
- [ ] 前端可以读取证书文件
- [ ] `.env.development` 配置正确
- [ ] VITE_API_TARGET 指向 HTTPS 后端
- [ ] 浏览器已添加安全例外
- [ ] WebSocket 连接正常
- [ ] 所有 API 请求成功

---

**配置完成日期**: 2026-01-21

**相关文档**:
- [后端 HTTPS 配置](../vigilantMonitorServer/HTTPS_SSL_GUIDE.md)
- [SSL 优化总结](../vigilantMonitorServer/SSL_OPTIMIZATION_SUMMARY.md)
