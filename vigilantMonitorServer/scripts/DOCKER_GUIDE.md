# Docker Compose 使用指南

本文档说明如何使用 Docker Compose 部署 vigilant Monitor，支持 SQLite 和 MySQL 两种数据库模式。

## 📦 快速开始

### SQLite 模式（单容器，适合小规模部署）

```bash
# 启动服务
docker-compose --profile sqlite up -d

# 查看日志
docker-compose logs -f komari-sqlite

# 停止服务
docker-compose --profile sqlite down
```

### MySQL 模式（推荐生产环境）

```bash
# 启动服务（包含 MySQL 容器）
docker-compose --profile mysql up -d

# 查看日志
docker-compose logs -f komari-mysql mysql

# 停止服务
docker-compose --profile mysql down

# 停止并删除数据卷（警告：会删除所有数据）
docker-compose --profile mysql down -v
```

## 🔧 配置说明

### SQLite 模式配置

编辑 `docker-compose.yml` 中的 `komari-sqlite` 服务：

```yaml
environment:
  - KOMARI_DB_TYPE=sqlite
  - KOMARI_DB_FILE=/app/data/komari.db
  - TZ=Asia/Shanghai  # 修改为你的时区
```

### MySQL 模式配置

#### 修改密码

**强烈建议在生产环境修改默认密码！**

```yaml
# vigilant Monitor 服务
environment:
  - KOMARI_DB_USER=komari
  - KOMARI_DB_PASS=your_secure_password  # 修改此处
  - KOMARI_DB_NAME=komari

# MySQL 服务
environment:
  - MYSQL_ROOT_PASSWORD=your_root_password  # 修改此处
  - MYSQL_PASSWORD=your_secure_password     # 与上面保持一致
```

#### 性能优化

根据服务器配置调整 MySQL 参数：

```yaml
command:
  - --innodb_buffer_pool_size=512M  # 增加缓冲池（建议物理内存的50-70%）
  - --max_connections=2000           # 增加最大连接数
  - --innodb_log_file_size=256M     # 增加日志文件大小
```

## 📁 目录结构

```
.
├── docker-compose.yml          # Docker Compose 配置
├── data/                       # SQLite 数据库文件（仅 SQLite 模式）
│   └── komari.db
├── themes/                     # 主题文件
├── logs/                       # 应用日志
└── scripts/
    ├── mysql_schema.sql        # MySQL 初始化脚本
    ├── migrate_sqlite_to_mysql.sh
    └── migrate_sqlite_to_mysql.ps1
```

## 🔄 从 SQLite 迁移到 MySQL

### 方法 1: 使用迁移脚本（推荐）

```bash
# 1. 停止 SQLite 容器
docker-compose --profile sqlite down

# 2. 启动 MySQL 容器
docker-compose --profile mysql up -d mysql

# 等待 MySQL 就绪
docker-compose logs mysql | grep "ready for connections"

# 3. 运行迁移脚本
./scripts/migrate_sqlite_to_mysql.sh

# 4. 启动 Komari MySQL 模式
docker-compose --profile mysql up -d komari-mysql
```

### 方法 2: 容器内迁移

```bash
# 1. 准备迁移环境
docker-compose --profile mysql up -d mysql

# 2. 进入容器执行迁移
docker run --rm -it \
  -v $(pwd)/data:/data \
  -v $(pwd)/scripts:/scripts \
  --network komari-network \
  alpine:3.21 sh

# 在容器内安装工具并执行迁移
apk add --no-cache mysql-client sqlite
cd /scripts
chmod +x migrate_sqlite_to_mysql.sh
SQLITE_DB=/data/komari.db \
MYSQL_HOST=mysql \
MYSQL_USER=komari \
MYSQL_PASS=your_password \
./migrate_sqlite_to_mysql.sh

# 3. 启动 Komari MySQL 模式
docker-compose --profile mysql up -d komari-mysql
```

## 🔍 监控与维护

### 查看服务状态

```bash
# 查看所有服务
docker-compose ps

# 查看特定服务
docker-compose ps komari-mysql mysql
```

### 查看日志

```bash
# 实时日志
docker-compose logs -f

# 最近 100 行日志
docker-compose logs --tail=100

# 特定服务日志
docker-compose logs -f komari-mysql
docker-compose logs -f mysql
```

### 备份数据

#### SQLite 备份

```bash
# 备份数据库文件
docker-compose exec komari-sqlite cp /app/data/komari.db /app/data/komari.db.backup

# 或直接复制宿主机文件
cp data/komari.db data/komari.db.$(date +%Y%m%d_%H%M%S)
```

#### MySQL 备份

```bash
# 方法 1: 使用 mysqldump
docker-compose exec mysql mysqldump \
  -u komari -pkomari_secure_password \
  komari > backup_$(date +%Y%m%d_%H%M%S).sql

# 方法 2: 定期备份（添加到 crontab）
0 2 * * * docker-compose -f /path/to/docker-compose.yml exec -T mysql \
  mysqldump -u komari -pkomari_secure_password komari \
  | gzip > /backup/komari_$(date +\%Y\%m\%d).sql.gz
```

### 恢复数据

#### SQLite 恢复

```bash
# 停止服务
docker-compose --profile sqlite down

# 恢复备份
cp data/komari.db.backup data/komari.db

# 重启服务
docker-compose --profile sqlite up -d
```

#### MySQL 恢复

```bash
# 恢复备份
docker-compose exec -T mysql mysql \
  -u komari -pkomari_secure_password \
  komari < backup_20260120.sql

# 或从压缩备份恢复
gunzip < backup_20260120.sql.gz | \
  docker-compose exec -T mysql mysql \
  -u komari -pkomari_secure_password komari
```

## 🐛 故障排查

### MySQL 连接失败

```bash
# 检查 MySQL 是否就绪
docker-compose exec mysql mysqladmin ping -h localhost -u root -p

# 检查网络连接
docker-compose exec komari-mysql ping -c 3 mysql

# 查看 MySQL 日志
docker-compose logs mysql | tail -50

# 测试连接
docker-compose exec mysql mysql -u komari -pkomari_secure_password -e "SELECT 1;"
```

### 权限问题

```bash
# 检查文件权限
ls -la data/ themes/ logs/

# 修复权限
sudo chown -R 1000:1000 data/ themes/ logs/
```

### 容器无法启动

```bash
# 查看详细错误
docker-compose up komari-mysql

# 检查配置
docker-compose config

# 重新构建
docker-compose build --no-cache
```

### 端口被占用

```bash
# 查看端口占用
netstat -tlnp | grep 25774
lsof -i :25774

# 修改端口映射
# 编辑 docker-compose.yml
ports:
  - "8080:25774"  # 使用其他端口
```

## 📊 性能优化

### MySQL 性能调优

在 `docker-compose.yml` 中添加：

```yaml
mysql:
  command:
    # InnoDB 设置
    - --innodb_buffer_pool_size=1G
    - --innodb_log_file_size=256M
    - --innodb_flush_log_at_trx_commit=2
    - --innodb_flush_method=O_DIRECT
    
    # 查询缓存
    - --query_cache_type=1
    - --query_cache_size=64M
    
    # 连接设置
    - --max_connections=1000
    - --thread_cache_size=50
    
    # 表设置
    - --table_open_cache=2000
    - --tmp_table_size=256M
    - --max_heap_table_size=256M
```

### 监控 MySQL 性能

```bash
# 连接到 MySQL
docker-compose exec mysql mysql -u root -p

# 查看状态
SHOW STATUS LIKE 'Threads_connected';
SHOW PROCESSLIST;

# 查看慢查询
SET GLOBAL slow_query_log = 'ON';
SET GLOBAL long_query_time = 2;
SHOW VARIABLES LIKE 'slow_query%';
```

## 🔒 安全建议

1. **修改默认密码**
2. **限制端口暴露**：仅在必要时暴露 MySQL 端口
3. **使用网络隔离**：确保数据库容器不直接暴露到公网
4. **定期备份**：设置自动备份任务
5. **更新镜像**：定期更新基础镜像

```yaml
# 安全配置示例
mysql:
  # 不暴露端口到宿主机
  # ports:
  #   - "3306:3306"  # 注释掉
  
  # 只允许特定网络访问
  networks:
    - backend

networks:
  backend:
    internal: true
```

## 📝 常用命令

```bash
# 启动服务
docker-compose --profile mysql up -d

# 停止服务
docker-compose --profile mysql down

# 重启服务
docker-compose --profile mysql restart

# 查看日志
docker-compose logs -f

# 进入容器
docker-compose exec komari-mysql sh
docker-compose exec mysql bash

# 更新镜像
docker-compose pull
docker-compose --profile mysql up -d

# 清理资源
docker-compose down -v
docker system prune -a
```

---

**最后更新：** 2026-01-20
