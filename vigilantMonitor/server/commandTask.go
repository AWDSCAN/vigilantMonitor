package server

import (
	"bytes"
	"context"
	"encoding/json"
	"log"
	"net/http"
	"os/exec"
	"runtime"
	"strings"
	"time"
)

// ExecuteCommandTask 异步执行命令任务并将结果发送给服务端
// 这个函数会立即返回，命令在后台异步执行，避免阻塞agent进程
func ExecuteCommandTask(taskID, command string) {
	// 记录任务开始时间
	startedAt := time.Now()

	// 验证任务ID和命令
	if taskID == "" {
		log.Println("Error: Task ID is empty")
		return
	}
	if command == "" {
		sendCommandResult(taskID, false, "", nil, "No command provided", startedAt)
		return
	}

	// 检查是否禁用远程控制
	if flags.DisableWebSsh {
		sendCommandResult(taskID, false, "", nil, "Remote control is disabled", startedAt)
		return
	}

	log.Printf("Starting command task %s: %s", taskID, command)

	// 创建带超时的上下文（默认30分钟超时）
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Minute)
	defer cancel()

	// 根据操作系统选择命令执行方式
	var cmd *exec.Cmd
	if runtime.GOOS == "windows" {
		// Windows: 使用PowerShell执行
		cmd = exec.CommandContext(ctx, "powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command",
			"[Console]::OutputEncoding = [System.Text.Encoding]::UTF8; "+command)
	} else {
		// Linux/Unix: 使用sh执行
		cmd = exec.CommandContext(ctx, "sh", "-c", command)
	}

	// 创建输出缓冲区
	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr

	// 异步执行命令
	err := cmd.Run()
	executedAt := time.Now()

	// 组合输出结果
	output := stdout.String()
	if stderr.Len() > 0 {
		if output != "" {
			output += "\n"
		}
		output += stderr.String()
	}

	// 规范化换行符
	output = strings.ReplaceAll(output, "\r\n", "\n")

	// 获取退出码
	var exitCode *int
	var errorMessage string

	if err != nil {
		if ctx.Err() == context.DeadlineExceeded {
			errorMessage = "Command execution timeout (30 minutes)"
			code := -1
			exitCode = &code
		} else if exitError, ok := err.(*exec.ExitError); ok {
			code := exitError.ExitCode()
			exitCode = &code
		} else {
			errorMessage = err.Error()
			code := -1
			exitCode = &code
		}
	} else {
		code := 0
		exitCode = &code
	}

	// 发送执行结果到服务端
	executed := true
	sendCommandResult(taskID, executed, output, exitCode, errorMessage, executedAt)

	log.Printf("Command task %s completed with exit code %v", taskID, exitCode)
}

// sendCommandResult 将命令执行结果发送给服务端
func sendCommandResult(taskID string, executed bool, output string, exitCode *int, errorMessage string, executedAt time.Time) {
	// 构造JSON payload
	payload := map[string]interface{}{
		"task_id":       taskID,
		"executed":      executed,
		"output":        output,
		"exit_code":     exitCode,
		"error_message": errorMessage,
		"executed_at":   executedAt.Format(time.RFC3339),
	}

	jsonData, err := json.Marshal(payload)
	if err != nil {
		log.Printf("Failed to marshal command result: %v", err)
		return
	}

	// 构造API端点
	endpoint := flags.Endpoint + "/api/clients/command/result?token=" + flags.Token

	// 创建HTTP请求
	req, err := http.NewRequest("POST", endpoint, bytes.NewBuffer(jsonData))
	if err != nil {
		log.Printf("Failed to create command result request: %v", err)
		return
	}

	req.Header.Set("Content-Type", "application/json")

	// 添加Cloudflare Access头部（如果配置了）
	if flags.CFAccessClientID != "" && flags.CFAccessClientSecret != "" {
		req.Header.Set("CF-Access-Client-Id", flags.CFAccessClientID)
		req.Header.Set("CF-Access-Client-Secret", flags.CFAccessClientSecret)
	}

	// 发送请求，带重试机制
	client := &http.Client{
		Timeout: 10 * time.Second,
	}

	maxRetry := flags.MaxRetries
	var resp *http.Response

	for i := 0; i <= maxRetry; i++ {
		if i > 0 {
			log.Printf("Retrying command result upload (%d/%d) for task %s", i, maxRetry, taskID)
			time.Sleep(2 * time.Second)
		}

		resp, err = client.Do(req)

		if err == nil && resp != nil && resp.StatusCode == http.StatusOK {
			break
		}

		if resp != nil {
			resp.Body.Close()
		}
	}

	if err != nil {
		log.Printf("Failed to upload command result for task %s: %v", taskID, err)
		return
	}

	if resp != nil {
		defer resp.Body.Close()
		if resp.StatusCode != http.StatusOK {
			log.Printf("Server returned non-OK status for task %s: %s", taskID, resp.Status)
		} else {
			log.Printf("Command result for task %s uploaded successfully", taskID)
		}
	}
}
