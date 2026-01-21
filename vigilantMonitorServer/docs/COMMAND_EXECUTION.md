# 远程命令执行功能文档

## 功能概述

vigilantMonitorServer 和 vigilantMonitor 现在支持批量远程命令执行功能。服务端可以向多个在线客户端下发系统命令，客户端通过异步进程执行命令，并将执行结果（包括原始输出、退出码、执行时间等）回传给服务端。

## 数据库表结构

### command_tasks 表（命令任务表）
```sql
CREATE TABLE `command_tasks` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `task_id` varchar(36) NOT NULL,                    -- 任务ID（唯一）
  `command` text NOT NULL,                            -- 要执行的命令
  `target_os` varchar(20) DEFAULT NULL,               -- 目标操作系统（windows/linux/null）
  `target_clients` longtext,                          -- 目标客户端UUID列表（JSON）
  `status` varchar(20) DEFAULT 'pending',             -- 任务状态（pending/running/completed/failed）
  `created_by` varchar(36) DEFAULT NULL,              -- 创建者用户ID
  `total_clients` int(11) DEFAULT 0,                  -- 目标客户端总数
  `success_count` int(11) DEFAULT 0,                  -- 成功执行数量
  `failed_count` int(11) DEFAULT 0,                   -- 失败执行数量
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_task_id` (`task_id`),
  KEY `idx_status` (`status`),
  KEY `idx_created_at` (`created_at`)
);
```

### command_results 表（命令执行结果表）
```sql
CREATE TABLE `command_results` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `task_id` varchar(36) NOT NULL,                    -- 关联的任务ID
  `client_uuid` varchar(36) NOT NULL,                -- 执行客户端UUID
  `executed` tinyint(1) DEFAULT 0,                   -- 是否已执行
  `output` longtext,                                  -- 命令输出（stdout + stderr）
  `exit_code` int(11) DEFAULT NULL,                  -- 退出码（0表示成功）
  `error_message` text,                               -- 错误信息
  `executed_at` datetime(3) DEFAULT NULL,            -- 执行时间
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `idx_task_id` (`task_id`),
  KEY `idx_client_uuid` (`client_uuid`),
  KEY `idx_executed_at` (`executed_at`),
  CONSTRAINT `fk_command_results_task` FOREIGN KEY (`task_id`) 
    REFERENCES `command_tasks` (`task_id`) ON DELETE CASCADE
);
```

## API 接口

### 1. 创建并下发命令任务
**端点**: `POST /api/admin/command/create`

**请求头**:
- 需要管理员认证（Cookie或Session）

**请求体**:
```json
{
  "command": "echo hello world",         // 必填：要执行的命令
  "target_os": "windows",                // 可选：目标操作系统 (windows/linux/空字符串表示全部)
  "target_clients": ["uuid1", "uuid2"]   // 可选：指定客户端UUID列表，为空则根据target_os选择
}
```

**响应示例**:
```json
{
  "status": "success",
  "data": {
    "task_id": "abc123xyz789",
    "command": "echo hello world",
    "target_os": "windows",
    "total_clients": 5,
    "sent_count": 5,
    "failed_clients": [],
    "status": "running"
  }
}
```

**批量执行示例**:

1. 在所有Windows客户端上执行：
```bash
curl -X POST http://localhost:25774/api/admin/command/create \
  -H "Content-Type: application/json" \
  -b "session=your_session_cookie" \
  -d '{
    "command": "Get-ComputerInfo | Select-Object WindowsVersion",
    "target_os": "windows"
  }'
```

2. 在所有Linux客户端上执行：
```bash
curl -X POST http://localhost:25774/api/admin/command/create \
  -H "Content-Type: application/json" \
  -b "session=your_session_cookie" \
  -d '{
    "command": "uname -a",
    "target_os": "linux"
  }'
```

3. 在指定客户端上执行：
```bash
curl -X POST http://localhost:25774/api/admin/command/create \
  -H "Content-Type: application/json" \
  -b "session=your_session_cookie" \
  -d '{
    "command": "df -h",
    "target_clients": ["client-uuid-1", "client-uuid-2"]
  }'
```

### 2. 查询任务详情
**端点**: `GET /api/admin/command/:task_id`

**响应示例**:
```json
{
  "status": "success",
  "data": {
    "id": 1,
    "task_id": "abc123xyz789",
    "command": "echo hello world",
    "target_os": "windows",
    "status": "completed",
    "total_clients": 5,
    "success_count": 5,
    "failed_count": 0,
    "created_at": "2026-01-21T09:30:00.000Z",
    "results": [
      {
        "id": 1,
        "task_id": "abc123xyz789",
        "client_uuid": "client-uuid-1",
        "executed": true,
        "output": "hello world\n",
        "exit_code": 0,
        "executed_at": "2026-01-21T09:30:01.500Z",
        "client_info": {
          "uuid": "client-uuid-1",
          "name": "Web Server 01",
          "os": "Windows Server 2022"
        }
      }
    ]
  }
}
```

### 3. 查询任务列表
**端点**: `GET /api/admin/command/list?page=1&page_size=20&status=running`

**查询参数**:
- `page`: 页码（默认1）
- `page_size`: 每页数量（默认20，最大100）
- `status`: 过滤状态（可选：pending/running/completed/failed）

**响应示例**:
```json
{
  "status": "success",
  "data": {
    "tasks": [...],
    "total": 50,
    "page": 1,
    "page_size": 20
  }
}
```

### 4. 删除任务
**端点**: `DELETE /api/admin/command/:task_id`

**响应示例**:
```json
{
  "status": "success",
  "data": {
    "message": "Task deleted successfully",
    "task_id": "abc123xyz789"
  }
}
```

## Agent 执行机制

### WebSocket 消息格式
服务端通过WebSocket向agent发送命令：
```json
{
  "message": "exec_command",
  "task_id": "abc123xyz789",
  "command": "echo hello world"
}
```

### 执行流程
1. **接收命令**: Agent通过WebSocket接收到`exec_command`消息
2. **异步执行**: 立即创建goroutine异步执行命令，避免阻塞主进程
3. **超时控制**: 命令执行默认30分钟超时
4. **输出捕获**: 同时捕获stdout和stderr
5. **结果回传**: 执行完成后通过HTTP POST发送结果到服务端

### 命令执行方式
- **Windows**: `powershell -NoProfile -ExecutionPolicy Bypass -Command "..."`
- **Linux/Unix**: `sh -c "..."`

### 回传结果格式
Agent向 `POST /api/clients/command/result` 发送：
```json
{
  "task_id": "abc123xyz789",
  "executed": true,
  "output": "hello world\n",
  "exit_code": 0,
  "error_message": "",
  "executed_at": "2026-01-21T09:30:01.500Z"
}
```

## 安全特性

1. **认证要求**:
   - 创建/查询/删除任务需要管理员权限
   - Agent回传结果需要token认证

2. **异步执行**: 防止长时间运行的命令阻塞agent进程

3. **超时保护**: 默认30分钟超时，防止无限期挂起

4. **审计日志**: 所有命令任务的创建和删除都会记录审计日志

5. **权限检查**: Agent可以通过`DisableWebSsh`标志禁用远程命令执行

## 使用场景

1. **批量系统维护**:
   ```json
   {
     "command": "apt update && apt upgrade -y",
     "target_os": "linux"
   }
   ```

2. **批量信息收集**:
   ```json
   {
     "command": "systeminfo",
     "target_os": "windows"
   }
   ```

3. **批量配置部署**:
   ```json
   {
     "command": "curl -o /etc/config.yml https://example.com/config.yml",
     "target_clients": ["prod-server-1", "prod-server-2"]
   }
   ```

4. **批量健康检查**:
   ```json
   {
     "command": "docker ps -a",
     "target_os": "linux"
   }
   ```

## 注意事项

1. 命令执行有30分钟超时限制
2. 只能向在线的客户端发送命令
3. 命令输出会完整保存到数据库，注意输出大小
4. 删除任务会级联删除所有相关结果
5. 建议定期清理历史任务数据
