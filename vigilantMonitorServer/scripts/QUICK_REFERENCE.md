# MySQL 迁移快速参考

## 🚀 一键迁移

### Linux/Mac
```bash
cd komari/scripts
chmod +x migrate_sqlite_to_mysql.sh
./migrate_sqlite_to_mysql.sh
```

### Windows
```powershell
cd komari\scripts
.\migrate_sqlite_to_mysql.ps1
```

## 📋 文件清单

| 文件 | 说明 |
|------|------|
| `mysql_schema.sql` | MySQL 表结构定义（DDL） |
| `migrate_sqlite_to_mysql.sh` | Linux/Mac 迁移脚本 |
| `migrate_sqlite_to_mysql.ps1` | Windows 迁移脚本 |
| `MIGRATION_GUIDE.md` | 完整迁移指南 |
| `DOCKER_GUIDE.md` | Docker 部署指南 |
| `docker-compose.yml` | Docker Compose 配置 |
| `.env.example` | 环境变量模板 |

## 🔑 关键配置

### 环境变量
```bash
export KOMARI_DB_TYPE=mysql
export KOMARI_DB_HOST=localhost
export KOMARI_DB_PORT=3306
export KOMARI_DB_USER=komari
export KOMARI_DB_PASS=your_password
export KOMARI_DB_NAME=komari
```

### Dockerfile
```dockerfile
ENV KOMARI_DB_TYPE=mysql
ENV KOMARI_DB_HOST=mysql
ENV KOMARI_DB_USER=komari
ENV KOMARI_DB_PASS=your_password
ENV KOMARI_DB_NAME=komari
```

## 📊 表结构对应

所有 19 个表完全一比一映射：

✅ **核心表**
- users, sessions, clients

✅ **监控数据**
- records, records_long_term
- gpu_records, gpu_records_long_term

✅ **功能表**
- logs, clipboards
- ping_tasks, ping_records
- tasks, task_results
- load_notifications, offline_notifications

✅ **配置表**
- oidc_providers
- message_sender_providers
- theme_configurations
- schema_versions

## 🎯 字段类型映射

| SQLite | MySQL |
|--------|-------|
| TEXT | VARCHAR/TEXT/LONGTEXT |
| INTEGER | INT/BIGINT |
| REAL | DECIMAL(5,2)/DOUBLE |
| BOOLEAN | TINYINT(1) |
| TIMESTAMP | TIMESTAMP |

## ⚡ Docker 快速启动

### SQLite 模式
```bash
docker-compose --profile sqlite up -d
```

### MySQL 模式
```bash
docker-compose --profile mysql up -d
```

## 🔍 验证迁移

```sql
-- 检查表数量
SELECT COUNT(*) FROM information_schema.tables 
WHERE table_schema = 'komari';
-- 应返回 19

-- 检查数据量
SELECT 
  (SELECT COUNT(*) FROM clients) as clients,
  (SELECT COUNT(*) FROM users) as users,
  (SELECT COUNT(*) FROM records) as records;
```

## 🆘 常见问题

### 连接失败
```sql
-- 检查用户权限
SHOW GRANTS FOR 'komari'@'%';

-- 重置权限
GRANT ALL PRIVILEGES ON komari.* TO 'komari'@'%';
FLUSH PRIVILEGES;
```

### 字符编码
```sql
-- 设置正确的字符集
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER DATABASE komari CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

### 外键错误
```sql
-- 临时禁用外键检查
SET FOREIGN_KEY_CHECKS=0;
-- 执行操作
SET FOREIGN_KEY_CHECKS=1;
```

## 📞 获取帮助

- 📖 完整文档：`MIGRATION_GUIDE.md`
- 🐳 Docker 指南：`DOCKER_GUIDE.md`
- 💬 提交 Issue
