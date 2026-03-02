package snmp

import (
	"encoding/json"
	"fmt"
	"strconv"
	"strings"
	"time"

	"vigilantMonitorServer/internal/database/models"

	"github.com/gosnmp/gosnmp"
)

// SNMP OID 常量
const (
	// 系统信息
	OID_SYSTEM_DESC   = "1.3.6.1.2.1.1.1.0" // 系统描述
	OID_SYSTEM_UPTIME = "1.3.6.1.2.1.1.3.0" // 系统运行时间

	// CPU 负载
	OID_LOAD_AVERAGE_5MIN = "1.3.6.1.4.1.2021.10.1.3.2" // UCD-SNMP-MIB::laLoad.2 (5分钟平均负载)

	// 内存信息 (HOST-RESOURCES-MIB)
	OID_MEMORY_SIZE   = "1.3.6.1.2.1.25.2.2.0" // hrMemorySize (KB)
	OID_STORAGE_TABLE = "1.3.6.1.2.1.25.2.3.1" // hrStorageTable

	// 网络接口流量 (IF-MIB)
	OID_IF_TABLE       = "1.3.6.1.2.1.2.2.1"    // ifTable
	OID_IF_DESC        = "1.3.6.1.2.1.2.2.1.2"  // ifDescr
	OID_IF_IN_OCTETS   = "1.3.6.1.2.1.2.2.1.10" // ifInOctets
	OID_IF_OUT_OCTETS  = "1.3.6.1.2.1.2.2.1.16" // ifOutOctets
	OID_IF_OPER_STATUS = "1.3.6.1.2.1.2.2.1.8"  // ifOperStatus
)

// SNMPCollector SNMP 采集器
type SNMPCollector struct {
	device *models.NetworkDevice
	client *gosnmp.GoSNMP
}

// NewCollector 创建新的 SNMP 采集器
func NewCollector(device *models.NetworkDevice) (*SNMPCollector, error) {
	client := &gosnmp.GoSNMP{
		Target:  device.Host,
		Port:    uint16(device.Port),
		Timeout: time.Duration(5) * time.Second,
		Retries: 2,
		MaxOids: 60,
	}

	// 配置 SNMP 版本和认证
	switch strings.ToLower(device.SNMPVersion) {
	case "v1":
		client.Version = gosnmp.Version1
		client.Community = device.Community
	case "v2c", "v2":
		client.Version = gosnmp.Version2c
		client.Community = device.Community
	case "v3":
		client.Version = gosnmp.Version3
		// 配置 SNMPv3 安全参数
		msgFlags := gosnmp.NoAuthNoPriv
		switch strings.ToLower(device.SecurityLevel) {
		case "authnopriv":
			msgFlags = gosnmp.AuthNoPriv
		case "authpriv":
			msgFlags = gosnmp.AuthPriv
		}

		authProtocol := gosnmp.NoAuth
		if strings.ToLower(device.AuthProtocol) == "md5" {
			authProtocol = gosnmp.MD5
		} else if strings.ToLower(device.AuthProtocol) == "sha" {
			authProtocol = gosnmp.SHA
		}

		privProtocol := gosnmp.NoPriv
		if strings.ToLower(device.PrivacyProtocol) == "des" {
			privProtocol = gosnmp.DES
		} else if strings.ToLower(device.PrivacyProtocol) == "aes" {
			privProtocol = gosnmp.AES
		}

		client.MsgFlags = msgFlags
		client.SecurityModel = gosnmp.UserSecurityModel
		client.SecurityParameters = &gosnmp.UsmSecurityParameters{
			UserName:                 device.AuthUsername,
			AuthenticationProtocol:   authProtocol,
			AuthenticationPassphrase: device.AuthPassword,
			PrivacyProtocol:          privProtocol,
			PrivacyPassphrase:        device.PrivacyPassword,
		}
	default:
		return nil, fmt.Errorf("unsupported SNMP version: %s", device.SNMPVersion)
	}

	return &SNMPCollector{
		device: device,
		client: client,
	}, nil
}

// Connect 连接到 SNMP 设备
func (c *SNMPCollector) Connect() error {
	return c.client.Connect()
}

// Close 关闭连接
func (c *SNMPCollector) Close() error {
	return c.client.Conn.Close()
}

// Collect 采集所有指标
func (c *SNMPCollector) Collect() (*models.NetworkDeviceMetrics, error) {
	if err := c.Connect(); err != nil {
		return nil, fmt.Errorf("failed to connect: %w", err)
	}
	defer c.Close()

	metrics := &models.NetworkDeviceMetrics{
		DeviceID: c.device.ID,
	}

	// 采集系统信息
	if err := c.collectSystemInfo(metrics); err != nil {
		return nil, fmt.Errorf("failed to collect system info: %w", err)
	}

	// 采集 CPU 负载
	if err := c.collectCPULoad(metrics); err != nil {
		// 非关键错误，记录但继续
		fmt.Printf("Warning: failed to collect CPU load: %v\n", err)
	}

	// 采集内存信息
	if err := c.collectMemoryInfo(metrics); err != nil {
		fmt.Printf("Warning: failed to collect memory info: %v\n", err)
	}

	// 采集磁盘信息
	if err := c.collectDiskInfo(metrics); err != nil {
		fmt.Printf("Warning: failed to collect disk info: %v\n", err)
	}

	// 采集网络接口流量
	if err := c.collectNetworkTraffic(metrics); err != nil {
		fmt.Printf("Warning: failed to collect network traffic: %v\n", err)
	}

	return metrics, nil
}

// collectSystemInfo 采集系统信息
func (c *SNMPCollector) collectSystemInfo(metrics *models.NetworkDeviceMetrics) error {
	// 系统描述
	result, err := c.client.Get([]string{OID_SYSTEM_DESC})
	if err != nil {
		return err
	}
	if len(result.Variables) > 0 {
		metrics.SystemDesc = gosnmpValueToString(result.Variables[0])
	}

	// 系统运行时间
	result, err = c.client.Get([]string{OID_SYSTEM_UPTIME})
	if err != nil {
		return err
	}
	if len(result.Variables) > 0 {
		// sysUpTime 是以 1/100 秒为单位的
		uptimeTicks := gosnmpValueToInt64(result.Variables[0])
		metrics.SystemUptime = uptimeTicks / 100 // 转换为秒
	}

	return nil
}

// collectCPULoad 采集 CPU 负载
func (c *SNMPCollector) collectCPULoad(metrics *models.NetworkDeviceMetrics) error {
	result, err := c.client.Get([]string{OID_LOAD_AVERAGE_5MIN})
	if err != nil {
		return err
	}
	if len(result.Variables) > 0 {
		load := gosnmpValueToString(result.Variables[0])
		if loadFloat, err := strconv.ParseFloat(load, 64); err == nil {
			metrics.CPULoad5Min = loadFloat
			metrics.CPUUsage = loadFloat * 100 / float64(1) // 简化计算
		}
	}
	return nil
}

// collectMemoryInfo 采集内存信息
func (c *SNMPCollector) collectMemoryInfo(metrics *models.NetworkDeviceMetrics) error {
	// 通过 hrStorageTable 获取内存信息
	// hrStorageDescr (1.3.6.1.2.1.25.2.3.1.3)
	// hrStorageAllocationUnits (1.3.6.1.2.1.25.2.3.1.4)
	// hrStorageSize (1.3.6.1.2.1.25.2.3.1.5)
	// hrStorageUsed (1.3.6.1.2.1.25.2.3.1.6)

	// Walk the storage table
	results, err := c.client.BulkWalkAll(OID_STORAGE_TABLE)
	if err != nil {
		return err
	}

	var totalMem, usedMem int64
	storageMap := make(map[string]map[string]interface{})

	for _, variable := range results {
		oid := variable.Name
		parts := strings.Split(oid, ".")
		if len(parts) < 2 {
			continue
		}
		index := parts[len(parts)-1]

		if _, ok := storageMap[index]; !ok {
			storageMap[index] = make(map[string]interface{})
		}

		if strings.HasPrefix(oid, "1.3.6.1.2.1.25.2.3.1.3.") { // hrStorageDescr
			storageMap[index]["desc"] = gosnmpValueToString(variable)
		} else if strings.HasPrefix(oid, "1.3.6.1.2.1.25.2.3.1.4.") { // hrStorageAllocationUnits
			storageMap[index]["units"] = gosnmpValueToInt64(variable)
		} else if strings.HasPrefix(oid, "1.3.6.1.2.1.25.2.3.1.5.") { // hrStorageSize
			storageMap[index]["size"] = gosnmpValueToInt64(variable)
		} else if strings.HasPrefix(oid, "1.3.6.1.2.1.25.2.3.1.6.") { // hrStorageUsed
			storageMap[index]["used"] = gosnmpValueToInt64(variable)
		}
	}

	// 查找物理内存
	for _, storage := range storageMap {
		desc, _ := storage["desc"].(string)
		if strings.Contains(strings.ToLower(desc), "physical memory") ||
			strings.Contains(strings.ToLower(desc), "ram") {
			units := storage["units"].(int64)
			size := storage["size"].(int64)
			used := storage["used"].(int64)

			totalMem = size * units
			usedMem = used * units
			break
		}
	}

	if totalMem > 0 {
		metrics.MemTotal = totalMem
		metrics.MemAvailable = totalMem - usedMem
		metrics.MemUsagePercent = float64(usedMem) / float64(totalMem) * 100
	}

	return nil
}

// collectDiskInfo 采集磁盘信息
func (c *SNMPCollector) collectDiskInfo(metrics *models.NetworkDeviceMetrics) error {
	results, err := c.client.BulkWalkAll(OID_STORAGE_TABLE)
	if err != nil {
		return err
	}

	storageMap := make(map[string]map[string]interface{})

	for _, variable := range results {
		oid := variable.Name
		parts := strings.Split(oid, ".")
		if len(parts) < 2 {
			continue
		}
		index := parts[len(parts)-1]

		if _, ok := storageMap[index]; !ok {
			storageMap[index] = make(map[string]interface{})
		}

		if strings.HasPrefix(oid, "1.3.6.1.2.1.25.2.3.1.3.") {
			storageMap[index]["desc"] = gosnmpValueToString(variable)
		} else if strings.HasPrefix(oid, "1.3.6.1.2.1.25.2.3.1.4.") {
			storageMap[index]["units"] = gosnmpValueToInt64(variable)
		} else if strings.HasPrefix(oid, "1.3.6.1.2.1.25.2.3.1.5.") {
			storageMap[index]["size"] = gosnmpValueToInt64(variable)
		} else if strings.HasPrefix(oid, "1.3.6.1.2.1.25.2.3.1.6.") {
			storageMap[index]["used"] = gosnmpValueToInt64(variable)
		}
	}

	var partitions []models.DiskPartition

	for _, storage := range storageMap {
		desc, _ := storage["desc"].(string)
		// 只保留磁盘分区（排除内存等）
		if strings.HasPrefix(desc, "/") || strings.Contains(desc, ":") {
			units, _ := storage["units"].(int64)
			size, _ := storage["size"].(int64)
			used, _ := storage["used"].(int64)

			total := size * units
			usedBytes := used * units

			if total > 0 {
				partition := models.DiskPartition{
					Partition:    desc,
					Description:  desc,
					Total:        total,
					Used:         usedBytes,
					UsagePercent: float64(usedBytes) / float64(total) * 100,
				}
				partitions = append(partitions, partition)
			}
		}
	}

	if len(partitions) > 0 {
		data, err := json.Marshal(partitions)
		if err == nil {
			metrics.DiskInfo = string(data)
		}
	}

	return nil
}

// collectNetworkTraffic 采集网络流量
func (c *SNMPCollector) collectNetworkTraffic(metrics *models.NetworkDeviceMetrics) error {
	// Walk the IF table
	results, err := c.client.BulkWalkAll(OID_IF_TABLE)
	if err != nil {
		return err
	}

	interfaceMap := make(map[string]*models.NetworkInterface)

	for _, variable := range results {
		oid := variable.Name
		parts := strings.Split(oid, ".")
		if len(parts) < 2 {
			continue
		}
		index := parts[len(parts)-1]

		if _, ok := interfaceMap[index]; !ok {
			idx, _ := strconv.Atoi(index)
			interfaceMap[index] = &models.NetworkInterface{
				Index: idx,
			}
		}

		if strings.HasPrefix(oid, OID_IF_DESC+".") {
			interfaceMap[index].Name = gosnmpValueToString(variable)
			interfaceMap[index].Description = gosnmpValueToString(variable)
		} else if strings.HasPrefix(oid, OID_IF_IN_OCTETS+".") {
			interfaceMap[index].InBytes = gosnmpValueToInt64(variable)
		} else if strings.HasPrefix(oid, OID_IF_OUT_OCTETS+".") {
			interfaceMap[index].OutBytes = gosnmpValueToInt64(variable)
		} else if strings.HasPrefix(oid, OID_IF_OPER_STATUS+".") {
			interfaceMap[index].Status = int(gosnmpValueToInt64(variable))
		}
	}

	var interfaces []models.NetworkInterface
	var totalIn, totalOut int64

	for _, iface := range interfaceMap {
		if iface.Name != "" {
			interfaces = append(interfaces, *iface)
			totalIn += iface.InBytes
			totalOut += iface.OutBytes
		}
	}

	metrics.NetInBytes = totalIn
	metrics.NetOutBytes = totalOut

	if len(interfaces) > 0 {
		data, err := json.Marshal(interfaces)
		if err == nil {
			metrics.InterfaceInfo = string(data)
		}
	}

	return nil
}

// Helper functions
func gosnmpValueToString(variable gosnmp.SnmpPDU) string {
	switch variable.Type {
	case gosnmp.OctetString:
		return string(variable.Value.([]byte))
	default:
		return fmt.Sprintf("%v", variable.Value)
	}
}

func gosnmpValueToInt64(variable gosnmp.SnmpPDU) int64 {
	switch variable.Type {
	case gosnmp.Integer:
		return int64(variable.Value.(int))
	case gosnmp.Counter32, gosnmp.Gauge32, gosnmp.TimeTicks:
		return int64(variable.Value.(uint))
	case gosnmp.Counter64:
		return int64(variable.Value.(uint64))
	default:
		if str := gosnmpValueToString(variable); str != "" {
			if val, err := strconv.ParseInt(str, 10, 64); err == nil {
				return val
			}
		}
		return 0
	}
}

// TestConnection 测试 SNMP 连接
func TestConnection(device *models.NetworkDevice) error {
	collector, err := NewCollector(device)
	if err != nil {
		return err
	}

	if err := collector.Connect(); err != nil {
		return err
	}
	defer collector.Close()

	// 尝试获取系统描述
	result, err := collector.client.Get([]string{OID_SYSTEM_DESC})
	if err != nil {
		return err
	}

	if len(result.Variables) == 0 {
		return fmt.Errorf("no response from device")
	}

	return nil
}
