package models

// NetworkDevice 网络设备表
type NetworkDevice struct {
	ID          uint   `json:"id" gorm:"primaryKey;autoIncrement"`
	Name        string `json:"name" gorm:"type:varchar(100);not null"`
	Host        string `json:"host" gorm:"type:varchar(100);not null"`        // IP 或主机名
	Port        int    `json:"port" gorm:"type:int;default:161"`              // SNMP 端口
	SNMPVersion string `json:"snmp_version" gorm:"type:varchar(10);not null"` // v1, v2c, v3
	Community   string `json:"community" gorm:"type:varchar(100)"`            // SNMP v1/v2c community string
	// SNMP v3 认证参数
	SecurityLevel   string `json:"security_level" gorm:"type:varchar(20)"` // noAuthNoPriv, authNoPriv, authPriv
	AuthUsername    string `json:"auth_username" gorm:"type:varchar(100)"`
	AuthPassword    string `json:"auth_password" gorm:"type:varchar(100)"`
	AuthProtocol    string `json:"auth_protocol" gorm:"type:varchar(20)"` // MD5, SHA
	PrivacyPassword string `json:"privacy_password" gorm:"type:varchar(100)"`
	PrivacyProtocol string `json:"privacy_protocol" gorm:"type:varchar(20)"` // DES, AES

	Description     string `json:"description" gorm:"type:text"`                // 设备描述
	Group           string `json:"group" gorm:"type:varchar(100)"`              // 设备分组
	Tags            string `json:"tags" gorm:"type:text"`                       // 标签，分号分隔
	Enabled         bool   `json:"enabled" gorm:"default:true"`                 // 是否启用
	CollectInterval int    `json:"collect_interval" gorm:"type:int;default:60"` // 采集间隔（秒）

	CreatedAt LocalTime `json:"created_at"`
	UpdatedAt LocalTime `json:"updated_at"`
}

// NetworkDeviceMetrics 网络设备监控指标
type NetworkDeviceMetrics struct {
	ID       uint `json:"id" gorm:"primaryKey;autoIncrement"`
	DeviceID uint `json:"device_id" gorm:"type:int;not null;index"`

	// 系统信息
	SystemDesc   string `json:"system_desc" gorm:"type:text"`     // 系统描述
	SystemUptime int64  `json:"system_uptime" gorm:"type:bigint"` // 系统运行时间（秒）

	// CPU 信息
	CPUUsage    float64 `json:"cpu_usage"`     // CPU 利用率（%）
	CPULoad5Min float64 `json:"cpu_load_5min"` // 5分钟平均负载

	// 内存信息
	MemTotal        int64   `json:"mem_total" gorm:"type:bigint"`     // 总内存（字节）
	MemAvailable    int64   `json:"mem_available" gorm:"type:bigint"` // 可用内存（字节）
	MemUsagePercent float64 `json:"mem_usage_percent"`                // 内存使用率（%）

	// 磁盘信息（JSON 格式存储多个分区）
	DiskInfo string `json:"disk_info" gorm:"type:text"` // JSON: [{partition, total, used, usage_percent}]

	// 网络流量
	NetInBytes  int64 `json:"net_in_bytes" gorm:"type:bigint"`  // 入站总字节数
	NetOutBytes int64 `json:"net_out_bytes" gorm:"type:bigint"` // 出站总字节数

	// 网络接口信息（JSON 格式存储多个接口）
	InterfaceInfo string `json:"interface_info" gorm:"type:text"` // JSON: [{name, in_bytes, out_bytes}]

	CollectedAt LocalTime `json:"collected_at"` // 采集时间
	CreatedAt   LocalTime `json:"created_at"`
}

// DiskPartition 磁盘分区信息
type DiskPartition struct {
	Partition    string  `json:"partition"`
	Description  string  `json:"description"`
	Total        int64   `json:"total"`
	Used         int64   `json:"used"`
	UsagePercent float64 `json:"usage_percent"`
}

// NetworkInterface 网络接口信息
type NetworkInterface struct {
	Index       int    `json:"index"`
	Name        string `json:"name"`
	Description string `json:"description"`
	InBytes     int64  `json:"in_bytes"`
	OutBytes    int64  `json:"out_bytes"`
	Status      int    `json:"status"` // 1=up, 2=down, ...
}
