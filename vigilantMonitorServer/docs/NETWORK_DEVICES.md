# 网络设备监控功能使用说明

## 功能概述

vigilantMonitorServer 现已支持通过 SNMP 协议（v1/v2c/v3）监控网络设备，可以采集以下信息：

- **系统信息**：系统描述
- **CPU 信息**：5分钟平均负载
- **内存使用**：总内存、可用内存、使用率
- **磁盘使用**：各个分区的使用情况
- **网络流量**：入站/出站字节数、各接口流量统计
- **运行时间**：系统启动时间

## 功能特性

1. ✅ 支持 SNMP v1/v2c/v3 三个版本
2. ✅ SNMPv3 支持所有安全级别（NoAuthNoPriv, AuthNoPriv, AuthPriv）
3. ✅ 支持 MD5/SHA 认证和 DES/AES 加密
4. ✅ 设备分组管理
5. ✅ 自定义采集间隔
6. ✅ 手动触发采集
7. ✅ 连接测试功能
8. ✅ 历史数据查询

## 使用方法

### 1. 访问网络设备管理界面

登录管理后台后，在左侧菜单栏可以看到"网络设备"菜单项，点击进入。

### 2. 添加设备

点击"添加设备"按钮，填写以下信息：

#### 基本信息
- **设备名称** *（必填）：例如"核心交换机"
- **主机地址** *（必填）：设备的 IP 地址或主机名
- **端口**：SNMP 端口，默认 161
- **分组**：可选，用于设备分组管理
- **采集间隔**：数据采集间隔（秒），默认 60 秒
- **描述**：设备描述信息
- **启用设备**：是否启用该设备的监控

#### SNMP 配置

##### SNMP v1/v2c
选择 SNMP v1 或 v2c 版本时，需要配置：
- **Community String**：通常为 "public"（只读）

##### SNMP v3
选择 SNMP v3 版本时，需要配置：

**安全级别**：
- `NoAuthNoPriv`：无认证无加密
- `AuthNoPriv`：仅认证不加密
- `AuthPriv`：认证并加密（推荐）

**认证信息**（AuthNoPriv 和 AuthPriv 需要）：
- **用户名**：SNMPv3 用户名
- **认证协议**：MD5 或 SHA
- **认证密码**：认证密码

**加密信息**（仅 AuthPriv 需要）：
- **加密协议**：DES 或 AES
- **加密密码**：加密密码

### 3. 测试连接

在添加或编辑设备时，可以点击"测试连接"按钮验证 SNMP 配置是否正确。

### 4. 手动采集数据

在设备列表中，点击每个设备行的"采集"按钮（⚡图标）可以立即触发数据采集，并查看采集的监控数据。

### 5. 查看监控数据

采集成功后会弹出对话框，显示：
- 系统信息和描述
- 运行时间
- CPU 负载（5分钟平均值）
- 内存使用情况（总量、可用、使用率）
- 网络流量（入站、出站）
- 采集时间

## API 接口

### 设备管理

```
GET    /api/admin/network-device              # 获取设备列表
GET    /api/admin/network-device/:id          # 获取单个设备
POST   /api/admin/network-device              # 创建设备
PUT    /api/admin/network-device/:id          # 更新设备
DELETE /api/admin/network-device/:id          # 删除设备
POST   /api/admin/network-device/test         # 测试连接
```

### 数据采集

```
POST   /api/admin/network-device/:id/collect       # 手动触发采集
GET    /api/admin/network-device/:id/metrics       # 获取历史数据
GET    /api/admin/network-device/:id/metrics/latest # 获取最新数据
```

## 数据库表结构

### network_devices 表
存储网络设备的基本信息和 SNMP 配置。

### network_device_metrics 表
存储设备的监控指标历史数据，每次采集创建一条记录。

## SNMP OID 参考

本功能使用以下标准 SNMP OID：

- **sysDescr**: 1.3.6.1.2.1.1.1.0 - 系统描述
- **sysUpTime**: 1.3.6.1.2.1.1.3.0 - 系统运行时间
- **laLoad.2**: 1.3.6.1.4.1.2021.10.1.3.2 - 5分钟平均负载
- **hrStorageTable**: 1.3.6.1.2.1.25.2.3.1 - 存储表（内存/磁盘）
- **ifTable**: 1.3.6.1.2.1.2.2.1 - 网络接口表

## 常见问题

### 1. 连接测试失败？
- 检查设备 IP 地址和端口是否正确
- 确认 SNMP 服务已在设备上启用
- 验证 Community String（v1/v2c）或认证信息（v3）是否正确
- 检查网络防火墙是否允许 SNMP 流量（UDP 161端口）

### 2. 采集不到某些指标？
- 不同设备厂商的 SNMP 实现可能略有差异
- 某些设备可能不支持某些 OID
- 查看设备的 SNMP MIB 文档确认支持的 OID

### 3. SNMPv3 认证失败？
- 确认安全级别设置正确
- 验证用户名和密码
- 检查认证协议（MD5/SHA）和加密协议（DES/AES）设置
- 确保设备上已创建对应的 SNMPv3 用户

## 后续扩展

可以考虑添加以下功能：
- 定时自动采集（后台定时任务）
- 监控告警（CPU/内存/磁盘阈值告警）
- 数据可视化图表
- 支持更多自定义 OID
- 批量设备导入
- 设备状态监控（在线/离线）

## 技术栈

- **后端**：
  - Go + Gin
  - gosnmp - SNMP 库
  - GORM - ORM
  
- **前端**：
  - React + TypeScript
  - Radix UI - UI 组件
  - Lucide React - 图标

## 代码文件位置

### 后端
- `pkg/snmp/collector.go` - SNMP 采集器实现
- `internal/database/models/network_device.go` - 数据模型
- `internal/api_v1/admin/network_device.go` - API 处理器
- `internal/api_v1/init.go` - 路由注册
- `internal/dbcore/dbcore.go` - 数据库迁移

### 前端
- `src/pages/admin/network-devices.tsx` - 设备管理页面
- `src/config/menuConfig.json` - 菜单配置
- `src/routes.ts` - 路由配置
- `src/i18n/locales/zh_CN.json` - 中文翻译
- `src/utils/iconHelper.ts` - 图标映射
