# Test script to verify SSL certificate bypass
Write-Host "Testing SSL certificate bypass..." -ForegroundColor Cyan

# Test URL
$TestUrl = "https://vite.localhost:5173/api/agent/download/vigilantMonitor-agent-windows-amd64.exe"
$OutputFile = "$env:TEMP\test-agent.exe"

Write-Host "Test URL: $TestUrl" -ForegroundColor Yellow

# Method 1: Check if TrustAllCertsPolicy already exists
if (-not ([System.Management.Automation.PSTypeName]'TrustAllCertsPolicy').Type) {
    Write-Host "Adding TrustAllCertsPolicy type..." -ForegroundColor Cyan
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
} else {
    Write-Host "TrustAllCertsPolicy already exists, reusing..." -ForegroundColor Green
}

# Set the policy
$originalPolicy = [System.Net.ServicePointManager]::CertificatePolicy
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

try {
    Write-Host "Attempting download..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $TestUrl -OutFile $OutputFile -UseBasicParsing
    
    if (Test-Path $OutputFile) {
        $size = [math]::Round((Get-Item $OutputFile).Length / 1MB, 2)
        Write-Host "SUCCESS! Downloaded $size MB" -ForegroundColor Green
        Remove-Item $OutputFile -Force
    }
} catch {
    Write-Host "ERROR: $_" -ForegroundColor Red
} finally {
    # Restore original policy
    [System.Net.ServicePointManager]::CertificatePolicy = $originalPolicy
}

Write-Host "`nTest completed." -ForegroundColor Cyan
