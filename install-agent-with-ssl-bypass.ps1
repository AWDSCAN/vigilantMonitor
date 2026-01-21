# Complete installation command with SSL certificate bypass
# This script downloads and executes the install.ps1 with proper SSL handling

$ServerUrl = "https://vite.localhost:5173"
$Token = "EZlOwmkeZIzfnoEbSEASz5"
$InstallDir = "E:\isntalltext"

Write-Host "=== vigilantMonitor Agent Installation with SSL Bypass ===" -ForegroundColor Cyan
Write-Host "Server: $ServerUrl" -ForegroundColor Yellow
Write-Host "Install Dir: $InstallDir" -ForegroundColor Yellow
Write-Host ""

# Step 1: Setup SSL certificate bypass
Write-Host "[1/3] Setting up SSL certificate bypass..." -ForegroundColor Cyan
if (-not ([System.Management.Automation.PSTypeName]'TrustAllCertsPolicy').Type) {
    Add-Type @"
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy {
    public bool CheckValidationResult(
        ServicePoint srvPoint, X509Certificate certificate,
        WebRequest request, int certificateProblem) {
        return true;
    }
}
"@
}
$originalPolicy = [System.Net.ServicePointManager]::CertificatePolicy
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

try {
    # Step 2: Download install script
    Write-Host "[2/3] Downloading installation script..." -ForegroundColor Cyan
    $scriptUrl = "$ServerUrl/api/agent/download/install.ps1"
    $scriptPath = Join-Path $InstallDir "install.ps1"
    
    New-Item -ItemType Directory -Path $InstallDir -Force -ErrorAction SilentlyContinue | Out-Null
    
    Invoke-WebRequest -Uri $scriptUrl -OutFile $scriptPath -UseBasicParsing
    Write-Host "    Downloaded to: $scriptPath" -ForegroundColor Green
    
    # Step 3: Execute installation
    Write-Host "[3/3] Executing installation..." -ForegroundColor Cyan
    Write-Host ""
    
    & $scriptPath `
        -e $ServerUrl `
        -t $Token `
        --disable-auto-update `
        --ignore-unsafe-cert `
        --memory-include-cache `
        --install-dir $InstallDir
    
} catch {
    Write-Host "ERROR: $_" -ForegroundColor Red
    exit 1
} finally {
    # Restore original certificate policy
    [System.Net.ServicePointManager]::CertificatePolicy = $originalPolicy
}

Write-Host ""
Write-Host "=== Installation Complete ===" -ForegroundColor Green
