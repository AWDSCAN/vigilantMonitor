# Agent 文件下载目录

此目录用于存放 vigilantMonitor agent 可执行文件，供目标主机下载部署使用。

## 使用方法

### 1. 准备 Agent 文件

将编译好的 agent 可执行文件放入此目录，例如：
- `vigilantMonitor.exe` (Windows)
- `vigilantMonitor` (Linux)
- `vigilantMonitor-linux-amd64` (Linux AMD64)
- `vigilantMonitor-linux-arm64` (Linux ARM64)
- `install.sh` (安装脚本)
- `install.ps1` (PowerShell 安装脚本)

### 2. 下载 Agent

通过以下 URL 模式下载文件：
```
http://your-server:port/api/agent/download/{filename}
```

示例：
```bash
# Linux/Unix
curl -O http://localhost:25774/api/agent/download/vigilantMonitor

# Windows PowerShell
Invoke-WebRequest -Uri http://localhost:25774/api/agent/download/vigilantMonitor.exe -OutFile vigilantMonitor.exe

# wget
wget http://localhost:25774/api/agent/download/vigilantMonitor
```

### 3. 一键部署脚本示例

**Linux:**
```bash
#!/bin/bash
# 下载并安装 agent
curl -O http://your-server:25774/api/agent/download/vigilantMonitor
chmod +x vigilantMonitor
./vigilantMonitor --token YOUR_TOKEN --endpoint http://your-server:25774
```

**Windows PowerShell:**
```powershell
# 下载并安装 agent
Invoke-WebRequest -Uri http://your-server:25774/api/agent/download/vigilantMonitor.exe -OutFile vigilantMonitor.exe
.\vigilantMonitor.exe --token YOUR_TOKEN --endpoint http://your-server:25774
```

## 安全特性

此下载路由实现了以下安全措施：

1. **路径验证**: 仅允许访问 `agentfile` 目录内的文件
2. **文件名检查**: 禁止包含路径穿越符号（`..`, `/`, `\`）
3. **扩展名限制**: 仅允许 `.exe`, `.sh`, `.ps1` 和无扩展名文件
4. **目录隔离**: 通过绝对路径验证防止目录穿越攻击
5. **公开访问**: 不需要认证即可下载，方便部署

## 注意事项

- 确保此目录只包含 agent 相关的安全文件
- 定期更新 agent 版本
- 建议使用 HTTPS 传输以保护文件完整性
- 可以配合版本管理，使用不同的文件名区分版本
