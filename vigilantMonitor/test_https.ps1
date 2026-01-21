# vigilantMonitor Agent HTTPS 连接测试脚本

Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "vigilantMonitor Agent HTTPS 连接测试" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host ""

# 检查编译后的可执行文件
if (-not (Test-Path ".\vigilantMonitor.exe")) {
    Write-Host "❌ 错误: 找不到 vigilantMonitor.exe" -ForegroundColor Red
    Write-Host "   请先编译: go build -o vigilantMonitor.exe" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ 找到 vigilantMonitor.exe" -ForegroundColor Green
Write-Host ""

# 配置参数
$ServerUrl = "https://127.0.0.1:25774"
$Token = "test-token-12345"  # 请替换为实际的 token

Write-Host "配置信息:" -ForegroundColor Cyan
Write-Host "  服务器地址: $ServerUrl" -ForegroundColor White
Write-Host "  Token: $Token" -ForegroundColor White
Write-Host "  心跳间隔: 10秒" -ForegroundColor White
Write-Host "  数据上报间隔: 1秒" -ForegroundColor White
Write-Host ""

# 提示用户
Write-Host "⚠️  注意事项:" -ForegroundColor Yellow
Write-Host "  1. 确保 vigilantMonitorServer 已启动并监听 HTTPS (25774端口)" -ForegroundColor White
Write-Host "  2. 确保 SSL 证书存在于 vigilantMonitorServer\data\ssl\" -ForegroundColor White
Write-Host "  3. Agent 将自动忽略自签名证书错误" -ForegroundColor White
Write-Host ""

# 询问是否继续
$continue = Read-Host "是否开始测试? (Y/N)"
if ($continue -ne "Y" -and $continue -ne "y") {
    Write-Host "测试已取消" -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "🚀 启动 vigilantMonitor Agent..." -ForegroundColor Green
Write-Host "   (按 Ctrl+C 停止测试)" -ForegroundColor Gray
Write-Host ""
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host ""

# 启动 agent（会自动使用 HTTPS 并忽略证书错误）
.\vigilantMonitor.exe `
    --endpoint $ServerUrl `
    --token $Token `
    --interval 1 `
    --disable-auto-update

Write-Host ""
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "测试结束" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan
