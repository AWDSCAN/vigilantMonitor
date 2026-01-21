package admin

import (
	"encoding/json"
	"log"
	"runtime"
	"strconv"
	"strings"
	"time"

	"vigilantMonitorServer/internal/api_v1/resp"
	"vigilantMonitorServer/internal/database/auditlog"
	"vigilantMonitorServer/internal/database/models"
	"vigilantMonitorServer/internal/dbcore"
	"vigilantMonitorServer/internal/ws"
	"vigilantMonitorServer/pkg/utils"

	"github.com/gin-gonic/gin"
	"github.com/gorilla/websocket"
	"gorm.io/gorm"
)

// parseInt 解析字符串为整数
func parseInt(s string) (int, error) {
	return strconv.Atoi(s)
}

// CreateCommandTask 创建并下发命令任务
// POST /api/admin/command/create
// Request Body:
//
//	{
//	  "command": "echo hello",          // 必填：要执行的命令
//	  "target_os": "windows",           // 可选：目标操作系统 (windows/linux/空字符串表示全部)
//	  "target_clients": ["uuid1", ...], // 可选：指定客户端UUID列表，为空则根据target_os选择
//	}
func CreateCommandTask(c *gin.Context) {
	var req struct {
		Command       string   `json:"command" binding:"required"`
		TargetOS      string   `json:"target_os"`      // "windows", "linux", or empty for all
		TargetClients []string `json:"target_clients"` // specific UUIDs, or empty for all matching OS
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		log.Printf("[ERROR] CreateCommandTask - Failed to bind JSON: %v", err)
		resp.RespondError(c, 400, "Invalid request: "+err.Error())
		return
	}

	log.Printf("[INFO] CreateCommandTask - Request: command=%s, target_os=%s, target_clients=%v", req.Command, req.TargetOS, req.TargetClients)

	// 生成任务ID
	taskID := utils.GenerateRandomString(16)

	// 获取所有在线客户端
	connectedClients := ws.GetConnectedClients()
	log.Printf("[INFO] CreateCommandTask - Connected clients count: %d", len(connectedClients))
	if len(connectedClients) == 0 {
		log.Printf("[ERROR] CreateCommandTask - No clients are currently online")
		resp.RespondError(c, 400, "No clients are currently online")
		return
	}

	// 确定目标客户端列表
	var targetClients []string
	var clientDetails []models.Client

	db := dbcore.GetDBInstance()

	if len(req.TargetClients) > 0 {
		// 使用指定的客户端列表
		targetClients = req.TargetClients
	} else {
		// 根据操作系统过滤
		var allClients []models.Client
		if err := db.Find(&allClients).Error; err != nil {
			resp.RespondError(c, 500, "Failed to query clients: "+err.Error())
			return
		}

		for _, client := range allClients {
			// 检查是否在线
			if _, online := connectedClients[client.UUID]; !online {
				continue
			}

			// 根据target_os过滤
			if req.TargetOS == "" {
				targetClients = append(targetClients, client.UUID)
				clientDetails = append(clientDetails, client)
			} else {
				osLower := strings.ToLower(client.OS)
				targetOSLower := strings.ToLower(req.TargetOS)

				if (targetOSLower == "windows" && strings.Contains(osLower, "windows")) ||
					(targetOSLower == "linux" && strings.Contains(osLower, "linux")) {
					targetClients = append(targetClients, client.UUID)
					clientDetails = append(clientDetails, client)
				}
			}
		}
	}

	if len(targetClients) == 0 {
		log.Printf("[ERROR] CreateCommandTask - No matching online clients found. target_os=%s, target_clients=%v", req.TargetOS, req.TargetClients)
		resp.RespondError(c, 400, "No matching online clients found")
		return
	}

	log.Printf("[INFO] CreateCommandTask - Target clients determined: %v (count: %d)", targetClients, len(targetClients))

	// 创建命令任务记录
	userUUID, _ := c.Get("uuid")
	task := models.CommandTask{
		TaskID:        taskID,
		Command:       req.Command,
		TargetOS:      req.TargetOS,
		TargetClients: models.StringArray(targetClients),
		Status:        "running",
		CreatedBy:     userUUID.(string),
		TotalClients:  len(targetClients),
		SuccessCount:  0,
		FailedCount:   0,
		CreatedAt:     models.LocalTime(time.Now()),
		UpdatedAt:     models.LocalTime(time.Now()),
	}

	if err := db.Create(&task).Error; err != nil {
		resp.RespondError(c, 500, "Failed to create task: "+err.Error())
		return
	}

	// 为每个目标客户端创建结果记录
	for _, clientUUID := range targetClients {
		result := models.CommandResult{
			TaskID:     taskID,
			ClientUUID: clientUUID,
			Executed:   false,
			CreatedAt:  models.LocalTime(time.Now()),
		}
		if err := db.Create(&result).Error; err != nil {
			// 记录错误但继续
			log.Printf("Failed to create result record for client %s: %v", clientUUID, err)
		}
	}

	// 通过WebSocket下发命令到各个客户端
	var sentCount int
	var failedClients []string

	for _, clientUUID := range targetClients {
		client := connectedClients[clientUUID]
		if client == nil {
			failedClients = append(failedClients, clientUUID)
			continue
		}

		message := gin.H{
			"message": "exec_command",
			"task_id": taskID,
			"command": req.Command,
		}

		payload, _ := json.Marshal(message)
		if err := client.WriteMessage(websocket.TextMessage, payload); err != nil {
			log.Printf("Failed to send command to client %s: %v", clientUUID, err)
			failedClients = append(failedClients, clientUUID)
		} else {
			sentCount++
		}
	}

	// 记录审计日志
	auditlog.Log(c.ClientIP(), userUUID.(string), "Command task created: "+taskID, "info")

	resp.RespondSuccess(c, gin.H{
		"task_id":        taskID,
		"command":        req.Command,
		"target_os":      req.TargetOS,
		"total_clients":  len(targetClients),
		"sent_count":     sentCount,
		"failed_clients": failedClients,
		"status":         "running",
	})
}

// GetCommandTask 查询命令任务详情
// GET /api/admin/command/:task_id
func GetCommandTask(c *gin.Context) {
	taskID := c.Param("task_id")
	if taskID == "" {
		resp.RespondError(c, 400, "Missing task_id parameter")
		return
	}

	db := dbcore.GetDBInstance()
	var task models.CommandTask

	if err := db.Preload("Results.ClientInfo").Where("task_id = ?", taskID).First(&task).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			resp.RespondError(c, 404, "Task not found")
			return
		}
		resp.RespondError(c, 500, "Failed to query task: "+err.Error())
		return
	}

	resp.RespondSuccess(c, task)
}

// ListCommandTasks 查询命令任务列表
// GET /api/admin/command/list?page=1&page_size=20&status=running
func ListCommandTasks(c *gin.Context) {
	var page, pageSize int = 1, 20
	var status string

	if p := c.Query("page"); p != "" {
		if pInt, err := parseInt(p); err == nil && pInt >= 1 {
			page = pInt
		}
	}

	if ps := c.Query("page_size"); ps != "" {
		if psInt, err := parseInt(ps); err == nil && psInt >= 1 && psInt <= 100 {
			pageSize = psInt
		}
	}

	status = c.Query("status")

	db := dbcore.GetDBInstance()
	query := db.Model(&models.CommandTask{})

	if status != "" {
		query = query.Where("status = ?", status)
	}

	var total int64
	if err := query.Count(&total).Error; err != nil {
		resp.RespondError(c, 500, "Failed to count tasks: "+err.Error())
		return
	}

	var tasks []models.CommandTask
	offset := (page - 1) * pageSize
	if err := query.Order("created_at DESC").Limit(pageSize).Offset(offset).Find(&tasks).Error; err != nil {
		resp.RespondError(c, 500, "Failed to query tasks: "+err.Error())
		return
	}

	resp.RespondSuccess(c, gin.H{
		"tasks":     tasks,
		"total":     total,
		"page":      page,
		"page_size": pageSize,
	})
}

// DeleteCommandTask 删除命令任务
// DELETE /api/admin/command/:task_id
func DeleteCommandTask(c *gin.Context) {
	taskID := c.Param("task_id")
	if taskID == "" {
		resp.RespondError(c, 400, "Missing task_id parameter")
		return
	}

	db := dbcore.GetDBInstance()

	// 删除任务（级联删除结果）
	if err := db.Where("task_id = ?", taskID).Delete(&models.CommandTask{}).Error; err != nil {
		resp.RespondError(c, 500, "Failed to delete task: "+err.Error())
		return
	}

	userUUID, _ := c.Get("uuid")
	auditlog.Log(c.ClientIP(), userUUID.(string), "Command task deleted: "+taskID, "warn")

	resp.RespondSuccess(c, gin.H{
		"message": "Task deleted successfully",
		"task_id": taskID,
	})
}

// ReceiveCommandResult 接收客户端执行结果
// POST /api/clients/command/result
// Request Body:
//
//	{
//	  "task_id": "xxx",
//	  "executed": true,
//	  "output": "command output",
//	  "exit_code": 0,
//	  "error_message": ""
//	}
func ReceiveCommandResult(c *gin.Context) {
	var req struct {
		TaskID       string `json:"task_id" binding:"required"`
		Executed     bool   `json:"executed"`
		Output       string `json:"output"`
		ExitCode     *int   `json:"exit_code"`
		ErrorMessage string `json:"error_message"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		resp.RespondError(c, 400, "Invalid request: "+err.Error())
		return
	}

	// 获取客户端UUID（从token解析）
	clientUUID, exists := c.Get("client_uuid")
	if !exists {
		resp.RespondError(c, 401, "Client UUID not found in context")
		return
	}

	db := dbcore.GetDBInstance()

	// 更新结果记录
	now := models.LocalTime(time.Now())
	updates := map[string]interface{}{
		"executed":      req.Executed,
		"output":        req.Output,
		"exit_code":     req.ExitCode,
		"error_message": req.ErrorMessage,
		"executed_at":   &now,
	}

	result := db.Model(&models.CommandResult{}).
		Where("task_id = ? AND client_uuid = ?", req.TaskID, clientUUID).
		Updates(updates)

	if result.Error != nil {
		resp.RespondError(c, 500, "Failed to update result: "+result.Error.Error())
		return
	}

	if result.RowsAffected == 0 {
		resp.RespondError(c, 404, "Result record not found")
		return
	}

	// 更新任务统计
	var task models.CommandTask
	if err := db.Where("task_id = ?", req.TaskID).First(&task).Error; err == nil {
		// 重新统计成功和失败数
		var successCount, failedCount int64
		db.Model(&models.CommandResult{}).
			Where("task_id = ? AND executed = ? AND (exit_code = 0 OR exit_code IS NULL)", req.TaskID, true).
			Count(&successCount)
		db.Model(&models.CommandResult{}).
			Where("task_id = ? AND (executed = ? OR exit_code != 0)", req.TaskID, false).
			Count(&failedCount)

		// 检查是否所有客户端都已完成
		var totalResults int64
		db.Model(&models.CommandResult{}).Where("task_id = ?", req.TaskID).Count(&totalResults)

		var executedResults int64
		db.Model(&models.CommandResult{}).Where("task_id = ? AND executed = ?", req.TaskID, true).Count(&executedResults)

		taskStatus := "running"
		if executedResults == totalResults {
			taskStatus = "completed"
		}

		db.Model(&models.CommandTask{}).Where("task_id = ?", req.TaskID).Updates(map[string]interface{}{
			"success_count": successCount,
			"failed_count":  failedCount,
			"status":        taskStatus,
			"updated_at":    time.Now(),
		})
	}

	resp.RespondSuccess(c, gin.H{
		"message": "Result received successfully",
		"task_id": req.TaskID,
	})
}

// GetPlatformInfo 获取当前服务器平台信息（用于测试）
func GetPlatformInfo(c *gin.Context) {
	resp.RespondSuccess(c, gin.H{
		"os":   runtime.GOOS,
		"arch": runtime.GOARCH,
	})
}
