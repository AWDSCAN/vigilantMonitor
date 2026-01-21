# 前后端 HTTPS 配置验证

## ✅ 配置状态

### 后端（vigilantMonitorServer）
- ✅ SSL证书已生成
- ✅ 证书位置: `E:\devops\vigilantMonitorServer\data\ssl\cert.pem`
- ✅ 私钥位置: `E:\devops\vigilantMonitorServer\data\ssl\key.pem`
- ⚠️ 当前运行HTTP模式（需要启用SSL配置）

### 前端（komari-web）
- ✅ HTTPS已自动启用
- ✅ 使用后端SSL证书
- ✅ 开发服务器: `https://localhost:5174/`
- ✅ Vite配置已更新

## 🔧 启用后端HTTPS

### 方法1: 修改配置文件（推荐）

编辑 `vigilantMonitorServer/data/komari.json`，确保包含以下配置：

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

### 方法2: 检查默认配置

如果配置文件不存在或SSL配置缺失，删除配置文件让程序重新生成：

```bash
# Windows PowerShell
cd E:\devops\vigilantMonitorServer
Remove-Item data\komari.json
.\vigilantMonitorServer.exe server

# Linux/macOS
cd vigilantMonitorServer
rm data/komari.json
./vigilantMonitorServer server
```

## 🚀 完整启动流程

### 1. 启动后端（HTTPS）

```bash
cd E:\devops\vigilantMonitorServer
.\vigilantMonitorServer.exe server
```

期望日志：
```
✓ SSL certificates loaded successfully
  Subject: localhost
  Valid until: 2036-01-19T03:59:54Z
Starting HTTPS server on 0.0.0.0:25774 ...
```

### 2. 启动前端（HTTPS）

```bash
cd E:\devops\komari-web
npm run dev
```

期望输出：
```
✓ HTTPS enabled for Vite dev server
  Certificate: E:\devops\vigilantMonitorServer\data\ssl\cert.pem
  Private Key: E:\devops\vigilantMonitorServer\data\ssl\key.pem

  VITE v6.3.5  ready in 937 ms

  ➜  Local:   https://localhost:5173/
```

### 3. 访问应用

在浏览器中打开：
```
https://localhost:5173
```

⚠️ **首次访问**: 点击"高级"→"继续访问 localhost（不安全）"

## ✅ 验证步骤

### 1. 检查后端HTTPS

```bash
# Windows
curl -k https://localhost:25774/ping

# 应返回: pong
```

### 2. 检查前端HTTPS

浏览器访问 `https://localhost:5173`，检查：
- ✅ URL栏显示 `https://`（带锁图标）
- ✅ 开发者工具网络标签显示所有请求都是HTTPS
- ✅ WebSocket连接正常（wss://）

### 3. 检查证书信息

浏览器地址栏点击锁图标 → 证书：
- **颁发给**: localhost
- **颁发者**: localhost（自签名）
- **有效期**: 10年

## 📊 当前状态总结

### ✅ 已完成
- [x] 后端SSL证书生成
- [x] 前端Vite HTTPS配置
- [x] 证书自动检测和加载
- [x] 开发服务器HTTPS启动
- [x] 代理配置更新（secure: false）

### ⏳ 待完成
- [ ] 后端启用SSL配置
- [ ] 验证完整HTTPS流程
- [ ] 测试WebSocket连接
- [ ] 测试Agent连接（需要 --ignore-unsafe-cert）

## 🎯 下一步

1. **停止当前后端进程**（Ctrl+C）

2. **检查配置文件**：
   ```bash
   cat E:\devops\vigilantMonitorServer\data\komari.json | grep -A 8 '"ssl"'
   ```

3. **如果缺少SSL配置，手动添加或重新生成**

4. **重启后端**：
   ```bash
   cd E:\devops\vigilantMonitorServer
   .\vigilantMonitorServer.exe server
   ```

5. **验证日志输出**，应该看到：
   ```
   Starting HTTPS server on 0.0.0.0:25774 ...
   ```

6. **测试完整流程**：
   - 后端: `https://localhost:25774/ping`
   - 前端: `https://localhost:5173`
   - API调用: 开发者工具检查所有请求

## 📝 配置文件位置

- 后端配置: `E:\devops\vigilantMonitorServer\data\komari.json`
- 前端环境: `E:\devops\komari-web\.env.development`
- SSL证书: `E:\devops\vigilantMonitorServer\data\ssl\cert.pem`
- SSL私钥: `E:\devops\vigilantMonitorServer\data\ssl\key.pem`

## 🔍 故障排查

### 后端仍显示HTTP警告

**原因**: 配置文件中SSL未启用

**解决**:
```bash
cd vigilantMonitorServer
.\vigilantMonitorServer.exe ssl check
# 如果显示有效，编辑 data/komari.json 添加 SSL 配置
```

### 前端无法连接后端

**原因**: 后端未启动HTTPS或证书问题

**解决**:
1. 确认后端日志显示 `Starting HTTPS server`
2. 测试: `curl -k https://localhost:25774/ping`
3. 检查 `.env.development` 中的 `VITE_API_TARGET`

### 浏览器持续显示安全警告

**原因**: 自签名证书的正常行为

**解决**: 
- 开发环境: 点击"继续访问"即可
- 生产环境: 使用Let's Encrypt等可信CA证书

---

**测试日期**: 2026-01-21 13:17

**状态**: 前端HTTPS配置完成，等待后端启用SSL
