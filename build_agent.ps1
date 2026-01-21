# Build vigilantMonitor agent
Set-Location E:\devops\vigilantMonitor

# Create build directory
New-Item -ItemType Directory -Force -Path build | Out-Null

# Get version
$version = git describe --tags --abbrev=0 2>$null
if (-not $version) { $version = "dev" }

Write-Host "Building vigilantMonitor agent version: $version" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

# Build configurations
$builds = @(
    @{OS='windows'; ARCH='amd64'; EXT='.exe'},
    @{OS='windows'; ARCH='arm64'; EXT='.exe'},
    @{OS='linux'; ARCH='amd64'; EXT=''},
    @{OS='linux'; ARCH='arm64'; EXT=''},
    @{OS='linux'; ARCH='386'; EXT=''},
    @{OS='darwin'; ARCH='amd64'; EXT=''},
    @{OS='darwin'; ARCH='arm64'; EXT=''}
)

$success = 0
$failed = 0

foreach ($build in $builds) {
    $outputFile = "build/vigilantMonitor-agent-$($build.OS)-$($build.ARCH)$($build.EXT)"
    Write-Host "Building $($build.OS)/$($build.ARCH)..." -ForegroundColor Yellow
    
    $env:GOOS = $build.OS
    $env:GOARCH = $build.ARCH
    $env:CGO_ENABLED = '0'
    
    $ldflags = "-s -w -X vigilantMonitor/update.CurrentVersion=$version"
    
    go build -trimpath -ldflags=$ldflags -o $outputFile main.go 2>&1 | Out-Null
    
    if ($LASTEXITCODE -eq 0 -and (Test-Path $outputFile)) {
        $size = [math]::Round((Get-Item $outputFile).Length / 1MB, 2)
        Write-Host "  ✓ $outputFile ($size MB)" -ForegroundColor Green
        $success++
    } else {
        Write-Host "  ✗ Failed to build $($build.OS)/$($build.ARCH)" -ForegroundColor Red
        $failed++
    }
}

Write-Host "`n=================================================" -ForegroundColor Cyan
Write-Host "Build Summary: $success successful, $failed failed" -ForegroundColor $(if ($failed -eq 0) { 'Green' } else { 'Yellow' })
Write-Host "Output directory: $(Resolve-Path build)" -ForegroundColor Cyan

# List all built files
Write-Host "`nBuilt files:" -ForegroundColor Cyan
Get-ChildItem build -File | ForEach-Object {
    Write-Host "  $($_.Name) - $([math]::Round($_.Length/1MB, 2)) MB" -ForegroundColor White
}
