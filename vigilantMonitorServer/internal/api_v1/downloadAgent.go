package api_v1

import (
	"net/http"
	"path/filepath"
	"strings"

	"github.com/gin-gonic/gin"
)

const AgentFileDirectory = "./agentfile"

// DownloadAgent 处理 agent 文件下载请求
// 这是一个公开路由，用于在目标主机上部署 agent 时下载可执行文件
func DownloadAgent(c *gin.Context) {
	filename := c.Param("filename")

	// 安全检查1: 文件名不能为空
	if filename == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Filename is required"})
		return
	}

	// 安全检查2: 防止目录穿越攻击 - 检查是否包含路径分隔符
	if strings.Contains(filename, "..") ||
		strings.Contains(filename, "/") ||
		strings.Contains(filename, "\\") ||
		strings.Contains(filename, "\x00") {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid filename"})
		return
	}

	// 安全检查3: 只允许特定的文件扩展名
	ext := strings.ToLower(filepath.Ext(filename))
	allowedExtensions := map[string]bool{
		".exe": true, // Windows
		".sh":  true, // Shell script
		".ps1": true, // PowerShell script
		"":     true, // 无扩展名 (Linux/Unix 可执行文件)
	}

	if !allowedExtensions[ext] {
		c.JSON(http.StatusBadRequest, gin.H{"error": "File type not allowed"})
		return
	}

	// 构建安全的文件路径
	// filepath.Join 会自动清理路径，但我们仍需要验证
	filePath := filepath.Join(AgentFileDirectory, filename)

	// 安全检查4: 确保最终路径仍在允许的目录内
	absAgentDir, err := filepath.Abs(AgentFileDirectory)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal server error"})
		return
	}

	absFilePath, err := filepath.Abs(filePath)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal server error"})
		return
	}

	// 验证文件路径必须在 agentfile 目录下
	if !strings.HasPrefix(absFilePath, absAgentDir+string(filepath.Separator)) &&
		absFilePath != absAgentDir {
		c.JSON(http.StatusForbidden, gin.H{"error": "Access denied"})
		return
	}

	// 检查文件是否存在
	c.Header("Content-Description", "File Transfer")
	c.Header("Content-Transfer-Encoding", "binary")
	c.Header("Content-Disposition", "attachment; filename="+filename)
	c.Header("Content-Type", "application/octet-stream")

	// 使用 Gin 的 File 方法发送文件
	// 如果文件不存在，会自动返回 404
	c.File(absFilePath)
}
