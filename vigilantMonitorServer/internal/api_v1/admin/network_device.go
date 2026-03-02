package admin

import (
	"net/http"
	"strconv"
	"time"

	"vigilantMonitorServer/internal/database/models"
	"vigilantMonitorServer/internal/dbcore"
	"vigilantMonitorServer/pkg/snmp"

	"github.com/gin-gonic/gin"
)

// GetNetworkDevices 获取网络设备列表
func GetNetworkDevices(c *gin.Context) {
	var devices []models.NetworkDevice
	db := dbcore.GetDBInstance()

	if err := db.Find(&devices).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"message": "Failed to fetch network devices",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    devices,
	})
}

// GetNetworkDevice 获取单个网络设备
func GetNetworkDevice(c *gin.Context) {
	id := c.Param("id")
	var device models.NetworkDevice
	db := dbcore.GetDBInstance()

	if err := db.First(&device, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"success": false,
			"message": "Network device not found",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    device,
	})
}

// CreateNetworkDevice 创建网络设备
func CreateNetworkDevice(c *gin.Context) {
	var device models.NetworkDevice

	if err := c.ShouldBindJSON(&device); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid request data: " + err.Error(),
		})
		return
	}

	db := dbcore.GetDBInstance()
	device.CreatedAt = models.FromTime(time.Now())
	device.UpdatedAt = models.FromTime(time.Now())

	if err := db.Create(&device).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"message": "Failed to create network device: " + err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    device,
		"message": "Network device created successfully",
	})
}

// UpdateNetworkDevice 更新网络设备
func UpdateNetworkDevice(c *gin.Context) {
	id := c.Param("id")
	var device models.NetworkDevice

	db := dbcore.GetDBInstance()
	if err := db.First(&device, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"success": false,
			"message": "Network device not found",
		})
		return
	}

	var updateData models.NetworkDevice
	if err := c.ShouldBindJSON(&updateData); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid request data: " + err.Error(),
		})
		return
	}

	// 保留原有的 ID 和创建时间
	updateData.ID = device.ID
	updateData.CreatedAt = device.CreatedAt
	updateData.UpdatedAt = models.FromTime(time.Now())

	if err := db.Save(&updateData).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"message": "Failed to update network device: " + err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    updateData,
		"message": "Network device updated successfully",
	})
}

// DeleteNetworkDevice 删除网络设备
func DeleteNetworkDevice(c *gin.Context) {
	id := c.Param("id")
	db := dbcore.GetDBInstance()

	// 同时删除相关的监控数据
	if err := db.Where("device_id = ?", id).Delete(&models.NetworkDeviceMetrics{}).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"message": "Failed to delete device metrics",
		})
		return
	}

	if err := db.Delete(&models.NetworkDevice{}, id).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"message": "Failed to delete network device",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Network device deleted successfully",
	})
}

// TestNetworkDeviceConnection 测试网络设备连接
func TestNetworkDeviceConnection(c *gin.Context) {
	var device models.NetworkDevice

	if err := c.ShouldBindJSON(&device); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid request data: " + err.Error(),
		})
		return
	}

	if err := snmp.TestConnection(&device); err != nil {
		c.JSON(http.StatusOK, gin.H{
			"success": false,
			"message": "Connection test failed: " + err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Connection test successful",
	})
}

// CollectNetworkDeviceMetrics 手动触发采集网络设备指标
func CollectNetworkDeviceMetrics(c *gin.Context) {
	id := c.Param("id")
	var device models.NetworkDevice
	db := dbcore.GetDBInstance()

	if err := db.First(&device, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"success": false,
			"message": "Network device not found",
		})
		return
	}

	if !device.Enabled {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Device is disabled",
		})
		return
	}

	// 创建采集器
	collector, err := snmp.NewCollector(&device)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"message": "Failed to create collector: " + err.Error(),
		})
		return
	}

	// 采集指标
	metrics, err := collector.Collect()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"message": "Failed to collect metrics: " + err.Error(),
		})
		return
	}

	// 保存指标到数据库
	metrics.CollectedAt = models.FromTime(time.Now())
	metrics.CreatedAt = models.FromTime(time.Now())

	if err := db.Create(metrics).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"message": "Failed to save metrics: " + err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    metrics,
		"message": "Metrics collected successfully",
	})
}

// GetNetworkDeviceMetrics 获取网络设备监控数据
func GetNetworkDeviceMetrics(c *gin.Context) {
	id := c.Param("id")
	db := dbcore.GetDBInstance()

	// 获取查询参数
	limitStr := c.DefaultQuery("limit", "100")
	limit, _ := strconv.Atoi(limitStr)

	var metrics []models.NetworkDeviceMetrics
	if err := db.Where("device_id = ?", id).
		Order("collected_at DESC").
		Limit(limit).
		Find(&metrics).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"message": "Failed to fetch metrics",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    metrics,
	})
}

// GetNetworkDeviceLatestMetrics 获取网络设备最新监控数据
func GetNetworkDeviceLatestMetrics(c *gin.Context) {
	id := c.Param("id")
	db := dbcore.GetDBInstance()

	var metrics models.NetworkDeviceMetrics
	if err := db.Where("device_id = ?", id).
		Order("collected_at DESC").
		First(&metrics).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"success": false,
			"message": "No metrics found",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    metrics,
	})
}
