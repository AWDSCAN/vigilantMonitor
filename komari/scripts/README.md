# Komari Monitor - MySQL 数据库支持

本目录包含将 Komari Monitor 从 SQLite 迁移到 MySQL 的所有工具和文档。

## 📁 文件清单

### 🔧 核心工具

| 文件 | 说明 | 平台 |
|------|------|------|
| `mysql_schema.sql` | MySQL 数据库完整表结构定义 | 通用 |
| `migrate_sqlite_to_mysql.sh` | 自动迁移脚本 | Linux/Mac |
| `migrate_sqlite_to_mysql.ps1` | 自动迁移脚本 | Windows |
| `verify_migration.sh` | 迁移验证脚本 | Linux/Mac |
| `verify_migration.ps1` | 迁移验证脚本 | Windows |

### 📚 文档

| 文件 | 说明 |
|------|------|
| `MIGRATION_GUIDE.md` | 完整的迁移指南（必读） |
| `DOCKER_GUIDE.md` | Docker Compose 部署指南 |
| `QUICK_REFERENCE.md` | 快速参考卡片 |
| `PROJECT_SUMMARY.md` | 项目总结文档 |
| `README.md` | 本文件 |

## 🚀 快速开始

### 选项 1: 自动迁移（推荐）

#### Linux/Mac
```bash
cd komari/scripts
chmod +x migrate_sqlite_to_mysql.sh
./migrate_sqlite_to_mysql.sh
```

#### Windows
```powershell
cd komari\scripts
.\migrate_sqlite_to_mysql.ps1
```

### 选项 2: Docker 部署

```bash
# SQLite 模式
docker-compose --profile sqlite up -d

# MySQL 模式（推荐生产环境）
docker-compose --profile mysql up -d
```

### 选项 3: 手动迁移

1. 创建 MySQL 数据库：
   ```sql
   CREATE DATABASE komari CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
   ```

2. 导入表结构：
   ```bash
   mysql -u komari -p komari < mysql_schema.sql
   ```

3. 迁移数据（参考迁移脚本）

4. 更新 Komari 配置使用 MySQL

## 📖 详细文档

### 新手入门
建议按以下顺序阅读：

1. **[QUICK_REFERENCE.md](./QUICK_REFERENCE.md)** - 5 分钟快速了解
2. **[MIGRATION_GUIDE.md](./MIGRATION_GUIDE.md)** - 详细的迁移步骤
3. **[DOCKER_GUIDE.md](./DOCKER_GUIDE.md)** - Docker 部署方案

### 进阶使用
- **[PROJECT_SUMMARY.md](./PROJECT_SUMMARY.md)** - 技术细节和架构说明

## 🎯 核心特性

### ✅ 完整的表结构映射
- 19 个表完全一比一对应
- 所有字段类型正确转换
- 保留所有索引和约束

### ✅ 自动化工具
- 跨平台迁移脚本
- 数据完整性验证
- 错误处理和回滚

### ✅ 生产级支持
- Docker Compose 配置
- 健康检查
- 自动重启
- 数据持久化

### ✅ 完善的文档
- 详细的操作指南
- 故障排查方案
- 最佳实践建议

## 📊 表结构清单

所有 19 个表：

**核心表**
- `schema_versions` - 版本管理
- `users` - 用户账户
- `sessions` - 用户会话
- `clients` - 客户端信息

**监控数据**
- `records` - 短期监控记录
- `records_long_term` - 长期监控记录
- `gpu_records` - GPU 监控记录
- `gpu_records_long_term` - GPU 长期记录

**通知系统**
- `offline_notifications` - 离线通知
- `load_notifications` - 负载通知
- `ping_tasks` - Ping 任务
- `ping_records` - Ping 记录

**任务管理**
- `tasks` - 任务定义
- `task_results` - 任务结果

**系统功能**
- `logs` - 系统日志
- `clipboards` - 剪贴板
- `oidc_providers` - OAuth 配置
- `message_sender_providers` - 消息发送器
- `theme_configurations` - 主题配置

## 🔄 迁移流程

```
┌─────────────┐
│ SQLite 数据库│
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ 备份数据     │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ 创建 MySQL  │
│ 数据库      │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ 导入表结构  │ ← mysql_schema.sql
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ 迁移数据    │ ← migrate_*.sh/ps1
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ 验证迁移    │ ← verify_*.sh/ps1
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ 更新配置    │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ 重启应用    │
└─────────────┘
```

## 🔍 验证迁移

运行验证脚本：

```bash
# Linux/Mac
./verify_migration.sh

# Windows
.\verify_migration.ps1
```

验证项目：
- ✅ 数据库连接
- ✅ 所有表存在
- ✅ 数据量正确
- ✅ 索引完整
- ✅ 字符集正确
- ✅ 存储引擎正确

## 🛠️ 常用命令

### 备份 SQLite
```bash
cp data/komari.db data/komari.db.backup
```

### 备份 MySQL
```bash
mysqldump -u komari -p komari > backup.sql
```

### 恢复 MySQL
```bash
mysql -u komari -p komari < backup.sql
```

### 检查 MySQL 状态
```bash
mysql -u komari -p -e "
SELECT 
  (SELECT COUNT(*) FROM komari.users) as users,
  (SELECT COUNT(*) FROM komari.clients) as clients,
  (SELECT COUNT(*) FROM komari.records) as records;
"
```

## 🐛 故障排查

### 问题：连接失败
```sql
-- 检查用户权限
SHOW GRANTS FOR 'komari'@'%';

-- 授予权限
GRANT ALL PRIVILEGES ON komari.* TO 'komari'@'%';
FLUSH PRIVILEGES;
```

### 问题：字符编码错误
```sql
-- 设置字符集
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER DATABASE komari CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

### 问题：外键约束失败
```sql
-- 临时禁用外键检查
SET FOREIGN_KEY_CHECKS=0;
-- 执行操作
SET FOREIGN_KEY_CHECKS=1;
```

更多问题请查看 [MIGRATION_GUIDE.md](./MIGRATION_GUIDE.md) 的故障排查章节。

## 📞 获取帮助

- 📖 查看详细文档：[MIGRATION_GUIDE.md](./MIGRATION_GUIDE.md)
- 🐳 Docker 问题：[DOCKER_GUIDE.md](./DOCKER_GUIDE.md)
- ⚡ 快速参考：[QUICK_REFERENCE.md](./QUICK_REFERENCE.md)
- 💬 提交 Issue：[GitHub Issues](https://github.com/komari-monitor/komari/issues)
- 💬 加入讨论：[Telegram Group](https://t.me/komari_monitor)

## 🔒 安全建议

1. **修改默认密码**
2. **限制数据库访问**
3. **定期备份数据**
4. **使用 SSL/TLS 连接**
5. **最小权限原则**

详细的安全配置请查看 [MIGRATION_GUIDE.md](./MIGRATION_GUIDE.md)。

## 📝 版本历史

- **v1.0** (2026-01-20)
  - ✅ 初始版本
  - ✅ 完整的 MySQL 表结构
  - ✅ 自动化迁移脚本
  - ✅ Docker Compose 支持
  - ✅ 详细文档

## 📄 许可证

本项目遵循 Komari Monitor 的开源许可证。

---

**最后更新：** 2026-01-20  
**维护者：** Komari Monitor Team
