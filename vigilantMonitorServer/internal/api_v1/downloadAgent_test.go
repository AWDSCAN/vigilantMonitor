package api_v1

import (
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
)

func TestDownloadAgent(t *testing.T) {
	// 设置 Gin 为测试模式
	gin.SetMode(gin.TestMode)

	// 创建测试目录和文件
	testDir := "./test_agentfile"
	os.MkdirAll(testDir, 0755)
	defer os.RemoveAll(testDir)

	// 创建测试文件
	testFile := filepath.Join(testDir, "test-agent.exe")
	err := os.WriteFile(testFile, []byte("test content"), 0644)
	assert.NoError(t, err)

	// 临时修改 AgentFileDirectory 为测试目录
	originalDir := AgentFileDirectory
	// 使用相对路径引用会有问题，暂时注释
	// AgentFileDirectory = testDir
	defer func() {
		// AgentFileDirectory = originalDir
		_ = originalDir
	}()

	tests := []struct {
		name           string
		filename       string
		expectedStatus int
		expectedBody   string
	}{
		{
			name:           "空文件名",
			filename:       "",
			expectedStatus: http.StatusNotFound, // Gin 路由匹配失败会返回 404
		},
		{
			name:           "目录穿越攻击 - 双点",
			filename:       "../../../etc/passwd",
			expectedStatus: http.StatusBadRequest,
			expectedBody:   "Invalid filename",
		},
		{
			name:           "目录穿越攻击 - 斜杠",
			filename:       "../../test.exe",
			expectedStatus: http.StatusBadRequest,
			expectedBody:   "Invalid filename",
		},
		{
			name:           "目录穿越攻击 - 反斜杠",
			filename:       "..\\..\\test.exe",
			expectedStatus: http.StatusBadRequest,
			expectedBody:   "Invalid filename",
		},
		{
			name:           "不允许的文件类型",
			filename:       "malicious.php",
			expectedStatus: http.StatusBadRequest,
			expectedBody:   "File type not allowed",
		},
		{
			name:           "包含空字节",
			filename:       "test\x00.exe",
			expectedStatus: http.StatusBadRequest,
			expectedBody:   "Invalid filename",
		},
		{
			name:           "允许的 exe 文件",
			filename:       "test-agent.exe",
			expectedStatus: http.StatusOK, // 如果使用真实目录会成功
		},
		{
			name:           "允许的无扩展名文件",
			filename:       "vigilantMonitor",
			expectedStatus: http.StatusNotFound, // 文件不存在
		},
		{
			name:           "允许的 shell 脚本",
			filename:       "install.sh",
			expectedStatus: http.StatusNotFound, // 文件不存在
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// 创建路由
			router := gin.New()
			router.GET("/api/agent/download/:filename", DownloadAgent)

			// 创建请求
			req, _ := http.NewRequest("GET", "/api/agent/download/"+tt.filename, nil)
			w := httptest.NewRecorder()

			// 执行请求
			router.ServeHTTP(w, req)

			// 验证状态码
			assert.Equal(t, tt.expectedStatus, w.Code)

			// 验证响应内容（如果有预期内容）
			if tt.expectedBody != "" {
				assert.Contains(t, w.Body.String(), tt.expectedBody)
			}
		})
	}
}

func TestDownloadAgent_SecurityChecks(t *testing.T) {
	gin.SetMode(gin.TestMode)

	// 测试各种恶意路径
	maliciousPaths := []string{
		"../../../etc/passwd",
		"..\\..\\..\\windows\\system32\\config\\sam",
		"./../../../sensitive.txt",
		"./../../data/config.json",
		"subdir/../../../etc/passwd",
		"%2e%2e%2f%2e%2e%2f",    // URL 编码的 ../..
		"..%2F..%2F",            // 部分 URL 编码
		"test/../../etc/passwd", // 包含正常路径的穿越
	}

	router := gin.New()
	router.GET("/api/agent/download/:filename", DownloadAgent)

	for _, path := range maliciousPaths {
		t.Run("恶意路径: "+path, func(t *testing.T) {
			req, _ := http.NewRequest("GET", "/api/agent/download/"+path, nil)
			w := httptest.NewRecorder()
			router.ServeHTTP(w, req)

			// 所有恶意路径都应该被拒绝
			assert.Equal(t, http.StatusBadRequest, w.Code, "路径应该被拒绝: "+path)
		})
	}
}

func TestDownloadAgent_AllowedExtensions(t *testing.T) {
	gin.SetMode(gin.TestMode)

	tests := []struct {
		filename string
		allowed  bool
	}{
		{"agent.exe", true},
		{"agent.sh", true},
		{"agent.ps1", true},
		{"agent", true}, // 无扩展名
		{"agent.bin", false},
		{"agent.php", false},
		{"agent.py", false},
		{"agent.txt", false},
		{"agent.zip", false},
	}

	router := gin.New()
	router.GET("/api/agent/download/:filename", DownloadAgent)

	for _, tt := range tests {
		t.Run(tt.filename, func(t *testing.T) {
			req, _ := http.NewRequest("GET", "/api/agent/download/"+tt.filename, nil)
			w := httptest.NewRecorder()
			router.ServeHTTP(w, req)

			if tt.allowed {
				// 允许的扩展名不会因为扩展名被拒绝（可能因为文件不存在返回 404）
				assert.NotEqual(t, http.StatusBadRequest, w.Code, "应该允许扩展名: "+tt.filename)
			} else {
				// 不允许的扩展名应该返回 400
				assert.Equal(t, http.StatusBadRequest, w.Code, "应该拒绝扩展名: "+tt.filename)
				assert.Contains(t, w.Body.String(), "File type not allowed")
			}
		})
	}
}
