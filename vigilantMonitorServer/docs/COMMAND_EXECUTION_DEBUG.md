# 命令执行功能调试指南

## 错误现象
```
2026/01/21 11:46:26 [INFO/GIN] 400 POST /api/admin/command/create | 127.0.0.1 | 33.7402ms
2026/01/21 11:46:36 [INFO/GIN] 400 POST /api/admin/command/create | 127.0.0.1 | 61.6851ms
```

## 可能原因分析

### 1. 没有在线的Agent客户端
**症状**：后端返回 `"No clients are currently online"`

**排查**：
- 检查是否有agent连接到服务器
- 查看 `/admin` 页面，确认节点列表中有在线节点（绿色状态）
- 检查后端日志：`[INFO] CreateCommandTask - Connected clients count: 0`

### 2. 没有匹配的目标客户端
**症状**：后端返回 `"No matching online clients found"`

**排查**：
- 如果选择了"所有 Windows 客户端"，确保有Windows节点在线
- 如果选择了"所有 Linux 客户端"，确保有Linux节点在线  
- 如果选择了"自定义选择节点"，确保至少选中了一个节点
- 检查后端日志：
  ```
  [ERROR] CreateCommandTask - No matching online clients found. target_os=windows, target_clients=[]
  ```

### 3. 请求参数错误
**症状**：后端返回 `"Invalid request: ..."`

**排查**：
- 检查浏览器控制台，查看"发送命令请求:"日志
- 验证请求体格式：
  ```json
  {
    "command": "echo hello",
    "target_os": "windows"  // 或 "linux" 或省略
  }
  ```
  或
  ```json
  {
    "command": "echo hello",
    "target_clients": ["uuid1", "uuid2"]
  }
  ```

## 调试步骤

### 第一步：检查Agent连接状态
1. 打开浏览器开发者工具（F12）
2. 访问 `/admin` 页面
3. 查看节点列表，确认有在线节点（状态显示为绿色/在线）

### 第二步：查看前端请求
1. 打开浏览器控制台（Console标签）
2. 在命令执行页面输入测试命令（如 `echo hello`）
3. 选择执行目标（Windows/Linux/自定义节点）
4. 点击"执行命令"
5. 查看控制台输出的"发送命令请求:"日志

**预期输出示例**：
```javascript
发送命令请求: {command: "echo hello", target_os: "windows"}
// 或
发送命令请求: {command: "echo hello", target_clients: ["abc123", "def456"]}
```

### 第三步：查看后端日志
在vigilantMonitorServer控制台查找以下日志：

**成功情况**：
```
[INFO] CreateCommandTask - Request: command=echo hello, target_os=windows, target_clients=[]
[INFO] CreateCommandTask - Connected clients count: 3
[INFO] CreateCommandTask - Target clients determined: [uuid1 uuid2] (count: 2)
```

**失败情况1 - 无在线客户端**：
```
[INFO] CreateCommandTask - Request: command=echo hello, target_os=windows, target_clients=[]
[ERROR] CreateCommandTask - No clients are currently online
```

**失败情况2 - 无匹配客户端**：
```
[INFO] CreateCommandTask - Request: command=echo hello, target_os=windows, target_clients=[]
[INFO] CreateCommandTask - Connected clients count: 2
[ERROR] CreateCommandTask - No matching online clients found. target_os=windows, target_clients=[]
```

**失败情况3 - 请求参数错误**：
```
[ERROR] CreateCommandTask - Failed to bind JSON: Key: 'Command' Error:Field validation for 'Command' failed on the 'required' tag
```

## 解决方案

### 情况1：无在线客户端
**解决方法**：
1. 启动至少一个agent
2. 确认agent能成功连接到服务器
3. 检查网络连接和防火墙设置

### 情况2：无匹配的Windows/Linux客户端
**解决方法**：
1. 选择"自定义选择节点"而不是操作系统批量执行
2. 手动选择想要执行命令的节点
3. 或者启动对应操作系统的agent

### 情况3：自定义选择但未选中节点
**解决方法**：
1. 在"选择节点"区域中勾选至少一个节点
2. 或者改为选择"所有 Windows 客户端"/"所有 Linux 客户端"

## 代码改进

### 已添加的调试日志
后端文件：`vigilantMonitorServer/internal/api_v1/admin/commandTask.go`

1. 请求参数日志（第48行）：
   ```go
   log.Printf("[INFO] CreateCommandTask - Request: command=%s, target_os=%s, target_clients=%v", 
       req.Command, req.TargetOS, req.TargetClients)
   ```

2. 在线客户端数量日志（第54行）：
   ```go
   log.Printf("[INFO] CreateCommandTask - Connected clients count: %d", len(connectedClients))
   ```

3. 目标客户端确定日志（第106行）：
   ```go
   log.Printf("[INFO] CreateCommandTask - Target clients determined: %v (count: %d)", 
       targetClients, len(targetClients))
   ```

### 前端调试日志
前端文件：`komari-web/src/pages/admin/exec.tsx`

请求发送前日志（第253行）：
```typescript
console.log("发送命令请求:", requestBody);
```

## 测试用例

### 测试1：批量执行Windows命令
```
前置条件：至少有1个Windows agent在线
操作：
1. 选择"所有 Windows 客户端"
2. 输入命令："whoami"
3. 点击"执行命令"
预期结果：成功执行，显示Windows用户名
```

### 测试2：批量执行Linux命令  
```
前置条件：至少有1个Linux agent在线
操作：
1. 选择"所有 Linux 客户端"
2. 输入命令："whoami"
3. 点击"执行命令"
预期结果：成功执行，显示Linux用户名
```

### 测试3：自定义选择节点
```
前置条件：至少有1个agent在线
操作：
1. 选择"自定义选择节点"
2. 勾选一个或多个节点
3. 输入命令："echo hello"
4. 点击"执行命令"
预期结果：成功执行，显示"hello"
```

### 测试4：错误情况 - 未选择节点
```
操作：
1. 选择"自定义选择节点"
2. 不勾选任何节点
3. 输入命令："echo hello"
4. 点击"执行命令"
预期结果：弹出提示"请选择目标节点或操作系统"（前端验证）
```

## 下一步行动

请按照以下步骤排查问题：

1. **重启服务**（确保新的日志代码生效）
   ```powershell
   # 在vigilantMonitorServer目录
   cd E:\devops\vigilantMonitorServer
   go run main.go server
   ```

2. **重新构建前端**（如果前端正在运行，刷新页面即可）
   ```powershell
   # 在komari-web目录，如果使用开发模式，应该自动热重载
   ```

3. **复现问题**
   - 打开浏览器开发者工具（F12）
   - 访问 `/admin/exec` 页面
   - 尝试执行命令
   - 观察：
     - 浏览器控制台的"发送命令请求:"日志
     - vigilantMonitorServer控制台的详细日志

4. **提供以下信息**：
   - 浏览器控制台的"发送命令请求:"输出
   - vigilantMonitorServer的完整日志（从发送请求到返回400的所有日志）
   - `/admin` 页面是否显示有在线节点
   - 选择的执行目标类型（Windows/Linux/自定义）

根据这些信息，我们可以精确定位是哪个环节出了问题。
