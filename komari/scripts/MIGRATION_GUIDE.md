# Komari Monitor - SQLite 到 MySQL 迁移指南

本文档说明如何将 Komari Monitor 的数据库从 SQLite 迁移到 MySQL，确保表结构字段结构一比一对应。

## 📋 目录

- [前置要求](#前置要求)
- [迁移步骤](#迁移步骤)
- [数据库表结构对应](#数据库表结构对应)
- [回滚方案](#回滚方案)
- [常见问题](#常见问题)

## 🔧 前置要求

### 系统要求

- **MySQL 5.7+** 或 **MariaDB 10.3+**
- SQLite 数据库备份
- 足够的磁盘空间（建议至少是 SQLite 数据库大小的 2 倍）

### Linux/Mac 环境

```bash
# 安装 MySQL 客户端
# Ubuntu/Debian
sudo apt-get install mysql-client sqlite3

# CentOS/RHEL
sudo yum install mysql sqlite

# macOS
brew install mysql sqlite3
```

### Windows 环境

1. 安装 [MySQL](https://dev.mysql.com/downloads/mysql/)
2. 下载 [SQLite Command Line Tools](https://www.sqlite.org/download.html)
3. 将 MySQL 和 SQLite 的 bin 目录添加到系统 PATH

## 📦 迁移步骤

### 步骤 1: 备份现有数据

```bash
# 备份 SQLite 数据库
cp ./data/komari.db ./data/komari.db.backup
```

### 步骤 2: 准备 MySQL 数据库

```sql
-- 登录 MySQL
mysql -u root -p

-- 创建数据库和用户
CREATE DATABASE komari CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'komari'@'localhost' IDENTIFIED BY 'your_secure_password';
GRANT ALL PRIVILEGES ON komari.* TO 'komari'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

### 步骤 3: 运行迁移脚本

#### Linux/Mac

```bash
cd komari/scripts

# 方式 1: 使用默认配置
chmod +x migrate_sqlite_to_mysql.sh
./migrate_sqlite_to_mysql.sh

# 方式 2: 使用自定义配置
SQLITE_DB="../data/komari.db" \
MYSQL_HOST="localhost" \
MYSQL_PORT="3306" \
MYSQL_USER="komari" \
MYSQL_PASS="your_password" \
MYSQL_DB="komari" \
./migrate_sqlite_to_mysql.sh
```

#### Windows PowerShell

```powershell
cd komari\scripts

# 方式 1: 使用默认配置
.\migrate_sqlite_to_mysql.ps1

# 方式 2: 使用自定义配置
.\migrate_sqlite_to_mysql.ps1 `
  -SqliteDb "..\data\komari.db" `
  -MysqlHost "localhost" `
  -MysqlPort 3306 `
  -MysqlUser "komari" `
  -MysqlPass "your_password" `
  -MysqlDb "komari"
```

### 步骤 4: 更新 Komari 配置

#### 使用环境变量

```bash
export KOMARI_DB_TYPE=mysql
export KOMARI_DB_HOST=localhost
export KOMARI_DB_PORT=3306
export KOMARI_DB_USER=komari
export KOMARI_DB_PASS=your_password
export KOMARI_DB_NAME=komari
```

#### 修改 Dockerfile

```dockerfile
ENV KOMARI_DB_TYPE=mysql
ENV KOMARI_DB_HOST=localhost
ENV KOMARI_DB_PORT=3306
ENV KOMARI_DB_USER=komari
ENV KOMARI_DB_PASS=your_password
ENV KOMARI_DB_NAME=komari
```

#### 使用配置文件（如果支持）

```yaml
database:
  type: mysql
  host: localhost
  port: 3306
  user: komari
  password: your_password
  name: komari
```

### 步骤 5: 验证迁移

```bash
# 启动 Komari Monitor
go run ./main.go

# 或使用 Docker
docker-compose up -d

# 检查日志
tail -f logs/komari.log

# 验证数据
mysql -u komari -p komari -e "
SELECT 
  (SELECT COUNT(*) FROM clients) as clients_count,
  (SELECT COUNT(*) FROM users) as users_count,
  (SELECT COUNT(*) FROM records) as records_count;
"
```

## 🔍 数据库表结构对应

### 字段类型映射

| SQLite 类型 | MySQL 类型 | 说明 |
|------------|-----------|------|
| `TEXT` | `VARCHAR(n)` / `TEXT` / `LONGTEXT` | 根据长度选择 |
| `INTEGER` | `INT` / `BIGINT` | 根据范围选择 |
| `REAL` | `DECIMAL(5,2)` / `DOUBLE` | 根据精度选择 |
| `BLOB` | `BLOB` / `LONGBLOB` | 保持一致 |
| `BOOLEAN` | `TINYINT(1)` | MySQL 标准布尔类型 |
| `TIMESTAMP` | `TIMESTAMP` | 保持一致 |

### 完整表清单

迁移脚本处理以下所有表：

1. **schema_versions** - 数据库版本管理
2. **users** - 用户账户
3. **sessions** - 用户会话
4. **clients** - 客户端设备信息
5. **records** - 短期监控记录
6. **records_long_term** - 长期监控记录
7. **gpu_records** - GPU 监控记录
8. **gpu_records_long_term** - GPU 长期记录
9. **logs** - 系统日志
10. **clipboards** - 剪贴板数据
11. **offline_notifications** - 离线通知配置
12. **load_notifications** - 负载通知规则
13. **ping_tasks** - Ping 任务
14. **ping_records** - Ping 结果记录
15. **oidc_providers** - OAuth 提供商
16. **message_sender_providers** - 消息发送器配置
17. **theme_configurations** - 主题配置
18. **tasks** - 执行任务
19. **task_results** - 任务执行结果

### 索引和外键

MySQL 版本完整保留了所有：

- **主键 (PRIMARY KEY)**
- **唯一索引 (UNIQUE KEY)**
- **普通索引 (INDEX)**
- **外键约束 (FOREIGN KEY)** - 包含级联删除和更新

## 🔄 回滚方案

如果迁移后发现问题，可以快速回滚到 SQLite：

```bash
# 1. 停止 Komari Monitor
pkill komari

# 2. 恢复 SQLite 数据库
cp ./data/komari.db.backup ./data/komari.db

# 3. 更新配置为 SQLite
export KOMARI_DB_TYPE=sqlite
export KOMARI_DB_FILE=./data/komari.db

# 4. 重启 Komari
go run ./main.go
```

## ❓ 常见问题

### 1. 迁移过程中出现字符编码问题

**解决方案：**
```sql
-- 检查 MySQL 字符集
SHOW VARIABLES LIKE 'character%';

-- 确保使用 utf8mb4
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER DATABASE komari CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

### 2. 外键约束导致数据导入失败

**解决方案：**
```sql
-- 临时禁用外键检查
SET FOREIGN_KEY_CHECKS=0;
-- 执行导入操作
-- ...
-- 重新启用外键检查
SET FOREIGN_KEY_CHECKS=1;
```

迁移脚本已自动处理此问题。

### 3. 时间戳字段格式不兼容

**解决方案：**

确保 MySQL 的 `time_zone` 设置正确：
```sql
SET time_zone = '+00:00';  -- 或您的时区
```

### 4. CSV 导入时出现换行符问题

**Windows 环境特别注意：**

如果遇到换行符问题，可以使用 `mysqldump` 和 `mysqlimport` 的组合方式：

```powershell
# 导出为 SQL 格式
sqlite3 komari.db .dump > dump.sql

# 手动转换并导入（需要根据具体情况调整）
```

### 5. 数据量大导致迁移时间长

**优化建议：**

```sql
-- 临时调整 MySQL 配置以提高导入速度
SET autocommit=0;
SET unique_checks=0;
SET foreign_key_checks=0;

-- 导入数据...

-- 恢复设置
SET autocommit=1;
SET unique_checks=1;
SET foreign_key_checks=1;
```

### 6. 迁移后性能问题

**优化 MySQL 性能：**

```sql
-- 优化表
OPTIMIZE TABLE clients;
OPTIMIZE TABLE records;
OPTIMIZE TABLE records_long_term;

-- 分析表以更新统计信息
ANALYZE TABLE clients;
ANALYZE TABLE records;
```

## 📊 性能对比

| 数据库 | 优势 | 劣势 |
|-------|------|------|
| **SQLite** | • 零配置<br>• 单文件<br>• 轻量级 | • 并发写入受限<br>• 单机部署 |
| **MySQL** | • 高并发<br>• 集群支持<br>• 丰富的工具生态 | • 需要独立服务<br>• 配置复杂 |

## 🛠️ 手动创建表结构

如果不想使用迁移脚本，可以直接使用 `mysql_schema.sql`：

```bash
mysql -u komari -p komari < scripts/mysql_schema.sql
```

该 SQL 文件完整定义了所有表结构，确保与 SQLite 版本字段一比一对应。

## 📝 注意事项

1. **字符集统一**：所有表使用 `utf8mb4` 字符集，支持完整的 Unicode 字符（包括 Emoji）
2. **时间字段**：使用 `TIMESTAMP` 类型，自动处理时区
3. **JSON 字段**：`StringArray` 等类型在 MySQL 中存储为 `LONGTEXT`，应用层负责序列化/反序列化
4. **自增 ID**：保留了所有自增主键的行为
5. **外键级联**：实现了 `ON DELETE CASCADE` 和 `ON UPDATE CASCADE`

## 🔒 安全建议

1. **生产环境**：
   - 使用强密码
   - 限制数据库用户权限
   - 启用 SSL/TLS 连接
   - 定期备份

2. **备份策略**：
```bash
# 每日备份
mysqldump -u komari -p komari > backup_$(date +%Y%m%d).sql

# 增量备份（启用二进制日志）
# 在 my.cnf 中配置
[mysqld]
log-bin=mysql-bin
expire_logs_days=7
```

## 📞 获取帮助

如果遇到问题：

1. 查看 Komari Monitor 日志
2. 检查 MySQL 错误日志：`/var/log/mysql/error.log`
3. 提交 Issue 到项目仓库

---

**最后更新：** 2026-01-20
