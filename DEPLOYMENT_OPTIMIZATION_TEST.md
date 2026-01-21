# 部署功能优化测试文档

## 修改概述

### 1. 前端修改 (komari-web/src/pages/admin/index.tsx)

#### 移除的选项：
- ✅ GitHub 代理 (--install-ghproxy)
- ✅ 禁用远程控制 (--disable-web-ssh)
- ✅ 忽略不安全证书 (--ignore-unsafe-cert) - 改为默认启用
- ✅ 禁用自动更新 (--disable-auto-update) - 改为默认启用

#### 修改后的命令生成逻辑：
```typescript
// 默认启用的选项
args.push("--disable-auto-update");
args.push("--ignore-unsafe-cert");
```

#### 下载源变更：
- **之前**: 从 GitHub releases 下载
  ```
  https://github.com/狰察-monitor/vigilantMonitor-agent/releases/...
  ```
- **之后**: 从本地服务器下载
  ```
  ${host}/api/agent/download/${scriptFile}
  ```

**重要**: API路径为 `/api/agent/download/` 而不是 `/api/download/agent/`

#### 生成的命令示例：

**Linux:**
```bash
wget -qO- http://localhost:5173/api/agent/download/install.sh | sudo bash -s -- -e http://localhost:5173 -t TOKEN --disable-auto-update --ignore-unsafe-cert
```

**Windows:**
```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "iwr 'http://localhost:5173/api/agent/download/install.ps1' -UseBasicParsing -OutFile 'install.ps1'; & '.\install.ps1' '-e' 'http://localhost:5173' '-t' 'TOKEN' '--disable-auto-update' '--ignore-unsafe-cert'"
```

**macOS:**
```bash
zsh <(curl -sL http://localhost:5173/api/agent/download/install.sh) -e http://localhost:5173 -t TOKEN --disable-auto-update --ignore-unsafe-cert
```

---

### 2. 安装脚本修改

#### vigilantMonitor/install.sh
**关键修改：**
1. 添加 server_endpoint 参数提取：
   ```bash
   -e)
       server_endpoint="$2"
       vigilantMonitor_args="$vigilantMonitor_args $1 $2"
       shift 2
       ;;
   ```

2. 从服务器下载而不是GitHub：
   ```bash
   download_url="${server_endpoint}/api/agent/download/${file_name}"
   ```

3. 必须提供服务器endpoint：
   ```bash
   if [ -z "$server_endpoint" ]; then
       log_error "Server endpoint (-e) is required"
       exit 1
   fi
   ```

#### vigilantMonitor/install.ps1
**关键修改：**
1. 添加 ServerEndpoint 参数：
   ```powershell
   $ServerEndpoint = ""
   "-e" { $ServerEndpoint = $args[$i + 1]; ... }
   ```

2. 从服务器下载：
   ```powershell
   $DownloadUrl = "$ServerEndpoint/api/agent/download/$BinaryName"
   ```

3. 必须提供endpoint：
   ```powershell
   if ([string]::IsNullOrWhiteSpace($ServerEndpoint)) {
       Log-Error "Server endpoint (-e) is required"
       exit 1
   }
   ```

---

### 3. Agent构建和部署

#### 已完成的步骤：
✅ 1. 使用 `vigilantMonitor/build_all.ps1` 构建所有平台的agent
✅ 2. 将agent文件复制到 `vigilantMonitorServer/agentfile/`
✅ 3. 将安装脚本复制到 `vigilantMonitorServer/agentfile/`

#### agentfile目录内容：
```
vigilantMonitorServer/agentfile/
├── install.sh (20,526 字节)
├── install.ps1 (11,165 字节)
├── vigilantMonitor-agent-windows-amd64.exe (10.7 MB)
├── vigilantMonitor-agent-windows-arm64.exe (9.9 MB)
├── vigilantMonitor-agent-windows-386.exe (10.2 MB)
├── vigilantMonitor-agent-linux-amd64 (8.2 MB)
├── vigilantMonitor-agent-linux-arm64 (7.7 MB)
├── vigilantMonitor-agent-linux-386 (7.9 MB)
├── vigilantMonitor-agent-linux-arm (7.9 MB)
├── vigilantMonitor-agent-darwin-amd64 (8.2 MB)
├── vigilantMonitor-agent-darwin-arm64 (7.8 MB)
├── vigilantMonitor-agent-freebsd-amd64 (7.9 MB)
├── vigilantMonitor-agent-freebsd-arm64 (7.4 MB)
├── vigilantMonitor-agent-freebsd-386 (7.6 MB)
└── vigilantMonitor-agent-freebsd-arm (7.6 MB)
```

---

## 测试检查清单

### 前端测试
- [ ] 访问 `/admin` 页面
- [ ] 点击"一键部署指令"按钮
- [ ] 验证不再显示以下选项：
  - [ ] GitHub 代理
  - [ ] 禁用远程控制
  - [ ] 忽略不安全证书
  - [ ] 禁用自动更新
- [ ] 切换 Linux/Windows/macOS 平台
- [ ] 检查生成的命令包含：
  - [ ] `-e` 服务器地址
  - [ ] `-t` token
  - [ ] `--disable-auto-update`
  - [ ] `--ignore-unsafe-cert`
- [ ] 验证脚本URL格式：`${host}/api/download/agent/install.sh` 或 `install.ps1`

### 下载API测试
- [ ] 启动 vigilantMonitorServer
- [ ] 测试下载endpoint：
  ```bash
  curl http://localhost:5173/api/download/agent/install.sh
  curl http://localhost:5173/api/download/agent/install.ps1
  curl http://localhost:5173/api/download/agent/vigilantMonitor-agent-linux-amd64
  ```
- [ ] 验证返回正确的文件内容
- [ ] 检查HTTP响应头：
  - [ ] Content-Type: application/octet-stream
  - [ ] Content-Disposition: attachment

### 完整部署流程测试

#### Linux测试：
```bash
# 1. 从前端复制生成的命令
# 2. 在Linux机器上执行
# 3. 验证：
#    - agent成功下载
#    - 从服务器下载而不是GitHub
#    - agent正确安装到指定目录
#    - 服务正确配置和启动
#    - agent成功连接到服务器
```

#### Windows测试：
```powershell
# 1. 从前端复制生成的命令
# 2. 在Windows机器上以管理员身份运行PowerShell
# 3. 执行命令
# 4. 验证：
#    - install.ps1下载成功
#    - agent从服务器下载
#    - nssm服务配置正确
#    - 服务启动成功
```

---

## 预期行为

### 成功标准：
1. ✅ 前端不再显示已移除的4个选项
2. ✅ 生成的命令默认包含 `--disable-auto-update` 和 `--ignore-unsafe-cert`
3. ✅ 安装脚本从服务器下载（不是GitHub）
4. ✅ Agent二进制文件从服务器下载
5. ✅ 安装过程无需GitHub访问
6. ✅ Agent成功安装并连接到服务器

### 错误处理：
1. ✅ 未提供 `-e` 参数时，脚本应报错退出
2. ✅ 服务器endpoint不可达时，下载失败并提示
3. ✅ Agent文件不存在时，返回404

---

## 回滚方案

如果测试失败，可以：
1. 恢复前端代码中的GitHub下载逻辑
2. 恢复install.sh和install.ps1的原始版本
3. 从Git历史恢复：
   ```bash
   git checkout HEAD~1 -- komari-web/src/pages/admin/index.tsx
   git checkout HEAD~1 -- vigilantMonitor/install.sh
   git checkout HEAD~1 -- vigilantMonitor/install.ps1
   ```

---

## 注意事项

1. **服务器端要求**：
   - vigilantMonitorServer必须运行
   - `/api/download/agent/` endpoint必须可访问
   - agentfile目录必须包含所有必需的文件

2. **网络要求**：
   - 目标机器必须能访问vigilantMonitorServer
   - 不再需要GitHub访问

3. **安全考虑**：
   - 默认启用 `--ignore-unsafe-cert` 适用于自签名证书环境
   - 默认启用 `--disable-auto-update` 确保稳定性

---

## 文件变更总结

### 修改的文件：
1. `komari-web/src/pages/admin/index.tsx` - 前端界面和命令生成逻辑
2. `vigilantMonitor/install.sh` - Linux/macOS安装脚本
3. `vigilantMonitor/install.ps1` - Windows安装脚本

### 新增/更新的文件：
1. `vigilantMonitorServer/agentfile/` - Agent二进制文件目录（14个文件）
2. `vigilantMonitorServer/agentfile/install.sh` - 安装脚本
3. `vigilantMonitorServer/agentfile/install.ps1` - Windows安装脚本

---

*测试日期: 2026年1月21日*
*优化版本: v1.0*
