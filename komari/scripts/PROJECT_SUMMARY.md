# MySQL 迁移项目总结

## 📁 创建的文件清单

### 核心文件

1. **scripts/mysql_schema.sql**
   - MySQL 数据库完整表结构定义
   - 包含所有 19 个表的 DDL 语句
   - 字段与 SQLite 版本完全一比一对应
   - 支持 utf8mb4 字符集和外键约束

2. **scripts/migrate_sqlite_to_mysql.sh**
   - Linux/Mac 平台自动迁移脚本
   - 支持数据完整性校验
   - 自动处理外键约束

3. **scripts/migrate_sqlite_to_mysql.ps1**
   - Windows PowerShell 迁移脚本
   - 功能与 bash 版本一致
   - 适配 Windows 环境

### 文档文件

4. **scripts/MIGRATION_GUIDE.md**
   - 完整的迁移指南
   - 包含前置要求、详细步骤
   - 故障排查和常见问题解答
   - 性能优化建议

5. **scripts/DOCKER_GUIDE.md**
   - Docker Compose 部署指南
   - 支持 SQLite 和 MySQL 两种模式
   - 包含监控、备份、恢复等运维操作

6. **scripts/QUICK_REFERENCE.md**
   - 快速参考卡片
   - 常用命令速查
   - 问题快速解决方案

### 配置文件

7. **docker-compose.yml**
   - Docker Compose 配置文件
   - 支持 SQLite 和 MySQL profile
   - 包含健康检查和自动重启

8. **.env.example**
   - 环境变量配置模板
   - 包含所有可配置参数
   - 详细的配置说明

### 更新的文件

9. **README.md**
   - 添加了 MySQL 支持说明
   - 更新了部署指南
   - 添加了数据库迁移章节

## 📊 数据库表结构映射

所有表完全一比一对应，包含：

### 用户和会话管理
- `users` - 用户账户
- `sessions` - 用户会话
- `schema_versions` - 数据库版本控制

### 客户端和监控
- `clients` - 客户端设备信息
- `records` - 短期监控记录
- `records_long_term` - 长期监控记录
- `gpu_records` - GPU 监控记录
- `gpu_records_long_term` - GPU 长期记录

### 通知系统
- `offline_notifications` - 离线通知配置
- `load_notifications` - 负载通知规则
- `ping_tasks` - Ping 任务配置
- `ping_records` - Ping 结果记录

### 任务管理
- `tasks` - 执行任务定义
- `task_results` - 任务执行结果

### 系统功能
- `logs` - 系统日志
- `clipboards` - 剪贴板数据
- `oidc_providers` - OAuth 提供商配置
- `message_sender_providers` - 消息发送器配置
- `theme_configurations` - 主题配置

## 🎯 关键特性

### 1. 完整的字段映射
- ✅ 所有字段类型正确转换
- ✅ 保留所有索引（主键、唯一索引、普通索引）
- ✅ 外键约束完整实现
- ✅ 字符集统一为 utf8mb4

### 2. 数据迁移支持
- ✅ 自动化迁移脚本
- ✅ 跨平台支持（Linux/Mac/Windows）
- ✅ 数据完整性验证
- ✅ 支持增量迁移

### 3. Docker 部署
- ✅ 支持 SQLite 和 MySQL 两种模式
- ✅ 使用 Docker Compose Profile
- ✅ 健康检查和自动重启
- ✅ 数据持久化

### 4. 完善的文档
- ✅ 详细的迁移指南
- ✅ Docker 部署指南
- ✅ 快速参考手册
- ✅ 故障排查指南

## 🔄 使用流程

### 方式 1: 自动迁移（推荐）

```bash
# 1. 备份数据
cp data/komari.db data/komari.db.backup

# 2. 准备 MySQL 数据库
mysql -u root -p -e "CREATE DATABASE komari CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"

# 3. 运行迁移脚本
cd scripts
chmod +x migrate_sqlite_to_mysql.sh
./migrate_sqlite_to_mysql.sh

# 4. 更新配置
export KOMARI_DB_TYPE=mysql
export KOMARI_DB_HOST=localhost
export KOMARI_DB_USER=komari
export KOMARI_DB_PASS=your_password
export KOMARI_DB_NAME=komari

# 5. 重启应用
go run ./main.go
```

### 方式 2: Docker 部署

```bash
# SQLite 模式
docker-compose --profile sqlite up -d

# MySQL 模式（推荐生产环境）
docker-compose --profile mysql up -d
```

## 📈 性能对比

| 指标 | SQLite | MySQL |
|------|--------|-------|
| 并发写入 | 受限 | 优秀 |
| 查询性能 | 良好 | 优秀 |
| 扩展性 | 单机 | 支持集群 |
| 运维成本 | 低 | 中 |
| 适用场景 | 小规模 | 生产环境 |

## 🔒 安全建议

1. **修改默认密码**
   - MySQL root 密码
   - 应用数据库用户密码

2. **网络隔离**
   - 限制 MySQL 端口访问
   - 使用内网连接

3. **定期备份**
   - 每日自动备份
   - 保留多个版本

4. **权限管理**
   - 使用最小权限原则
   - 定期审计数据库访问

## 🎓 技术细节

### 字段类型转换规则

| SQLite 类型 | MySQL 类型 | 说明 |
|------------|-----------|------|
| TEXT (短) | VARCHAR(n) | n < 255 |
| TEXT (中) | TEXT | 255 < n < 65535 |
| TEXT (长) | LONGTEXT | n > 65535 |
| INTEGER | INT | -2147483648 到 2147483647 |
| INTEGER (大) | BIGINT | 更大范围 |
| REAL | DECIMAL(5,2) | 精确小数 |
| REAL (通用) | DOUBLE | 浮点数 |
| BOOLEAN | TINYINT(1) | 0/1 值 |
| TIMESTAMP | TIMESTAMP | 自动时区处理 |

### 索引策略

1. **主键索引** (PRIMARY KEY)
   - 所有主键字段
   - 自动创建聚簇索引

2. **唯一索引** (UNIQUE KEY)
   - token, username 等唯一字段
   - 保证数据唯一性

3. **普通索引** (KEY)
   - client, time 等查询频繁字段
   - 提升查询性能

4. **外键索引** (FOREIGN KEY)
   - 关联表字段
   - 保证引用完整性

### 字符集配置

```sql
-- 数据库级别
CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci

-- 表级别
ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci

-- 连接级别
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci
```

## 📞 支持

- 📖 查看 [MIGRATION_GUIDE.md](./MIGRATION_GUIDE.md)
- 🐳 查看 [DOCKER_GUIDE.md](./DOCKER_GUIDE.md)
- ⚡ 查看 [QUICK_REFERENCE.md](./QUICK_REFERENCE.md)
- 💬 提交 GitHub Issue
- 💬 加入 Telegram 群组

## ✅ 验证清单

迁移完成后，请验证：

- [ ] 所有表都已创建（19 个表）
- [ ] 数据量与 SQLite 一致
- [ ] 应用可以正常启动
- [ ] 可以正常登录
- [ ] 客户端数据显示正常
- [ ] 监控数据正常采集
- [ ] 通知功能正常
- [ ] 任务执行正常

## 🎉 总结

本次迁移项目完成了：

1. ✅ **完整的 MySQL 表结构定义**
   - 19 个表的 DDL
   - 完全一比一字段映射

2. ✅ **自动化迁移工具**
   - 跨平台脚本支持
   - 数据完整性保证

3. ✅ **生产级部署方案**
   - Docker Compose 支持
   - 健康检查和监控

4. ✅ **详尽的文档**
   - 迁移指南
   - 部署指南
   - 故障排查

5. ✅ **最佳实践**
   - 安全配置建议
   - 性能优化方案
   - 备份恢复策略

---

**创建时间：** 2026-01-20
**项目状态：** ✅ 完成
