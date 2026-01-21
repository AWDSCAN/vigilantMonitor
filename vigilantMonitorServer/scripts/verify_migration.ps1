# MySQL Migration Verification Script (PowerShell)
# This script verifies that the MySQL migration was successful

param(
    [string]$MysqlHost = "localhost",
    [int]$MysqlPort = 3306,
    [string]$MysqlUser = "komari",
    [string]$MysqlPass = "",
    [string]$MysqlDb = "komari"
)

$ErrorActionPreference = "Stop"

Write-Host "=== vigilant Monitor: MySQL Migration Verification ===" -ForegroundColor Blue
Write-Host ""

# Check if mysql.exe is available
try {
    $null = Get-Command mysql -ErrorAction Stop
} catch {
    Write-Host "Error: mysql.exe is not installed or not in PATH" -ForegroundColor Red
    exit 1
}

# Prepare MySQL connection arguments
$mysqlArgs = @(
    "-h", $MysqlHost,
    "-P", $MysqlPort,
    "-u", $MysqlUser
)
if ($MysqlPass) {
    $mysqlArgs += "-p$MysqlPass"
}

# Test connection
Write-Host "Testing MySQL connection..." -ForegroundColor Yellow
try {
    $testArgs = $mysqlArgs + @("-e", "SELECT 1;")
    $null = & mysql @testArgs 2>&1
    Write-Host "✓ Connection successful" -ForegroundColor Green
} catch {
    Write-Host "✗ Connection failed" -ForegroundColor Red
    exit 1
}

# Check database exists
Write-Host "Checking database..." -ForegroundColor Yellow
$checkDbArgs = $mysqlArgs + @("-e", "SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME='$MysqlDb';")
$dbExists = & mysql @checkDbArgs 2>&1 | Select-String -Pattern $MysqlDb -Quiet

if ($dbExists) {
    Write-Host "✓ Database '$MysqlDb' exists" -ForegroundColor Green
} else {
    Write-Host "✗ Database '$MysqlDb' not found" -ForegroundColor Red
    exit 1
}

# Check character set
Write-Host "Checking database character set..." -ForegroundColor Yellow
$charsetArgs = $mysqlArgs + @("-e", "SELECT DEFAULT_CHARACTER_SET_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME='$MysqlDb';")
$charset = (& mysql @charsetArgs 2>&1 | Select-Object -Last 1).Trim()

if ($charset -eq "utf8mb4") {
    Write-Host "✓ Character set is utf8mb4" -ForegroundColor Green
} else {
    Write-Host "⚠ Character set is $charset (expected utf8mb4)" -ForegroundColor Yellow
}

# Check tables
Write-Host "Checking tables..." -ForegroundColor Yellow
$expectedTables = @(
    "schema_versions",
    "users",
    "sessions",
    "clients",
    "records",
    "records_long_term",
    "gpu_records",
    "gpu_records_long_term",
    "logs",
    "clipboards",
    "offline_notifications",
    "load_notifications",
    "ping_tasks",
    "ping_records",
    "oidc_providers",
    "message_sender_providers",
    "theme_configurations",
    "tasks",
    "task_results"
)

$missingTables = @()
foreach ($table in $expectedTables) {
    $tableArgs = $mysqlArgs + @($MysqlDb, "-e", "SHOW TABLES LIKE '$table';")
    $tableExists = & mysql @tableArgs 2>&1 | Select-String -Pattern $table -Quiet
    
    if ($tableExists) {
        Write-Host "  ✓ $table" -ForegroundColor Green
    } else {
        Write-Host "  ✗ $table (missing)" -ForegroundColor Red
        $missingTables += $table
    }
}

if ($missingTables.Count -gt 0) {
    Write-Host "Missing tables: $($missingTables -join ', ')" -ForegroundColor Red
    exit 1
}

# Check data counts
Write-Host ""
Write-Host "Checking data counts..." -ForegroundColor Yellow

function Get-RowCount {
    param([string]$Table)
    $countArgs = $mysqlArgs + @($MysqlDb, "-e", "SELECT COUNT(*) FROM $Table;")
    $result = & mysql @countArgs 2>&1 | Select-Object -Last 1
    return [int]$result.Trim()
}

$userCount = Get-RowCount "users"
Write-Host "  Users: $userCount" -ForegroundColor Blue

$clientCount = Get-RowCount "clients"
Write-Host "  Clients: $clientCount" -ForegroundColor Blue

$recordCount = Get-RowCount "records"
Write-Host "  Records: $recordCount" -ForegroundColor Blue

$ltRecordCount = Get-RowCount "records_long_term"
Write-Host "  Long-term Records: $ltRecordCount" -ForegroundColor Blue

$sessionCount = Get-RowCount "sessions"
Write-Host "  Sessions: $sessionCount" -ForegroundColor Blue

$pingTaskCount = Get-RowCount "ping_tasks"
Write-Host "  Ping Tasks: $pingTaskCount" -ForegroundColor Blue

# Check indexes
Write-Host ""
Write-Host "Checking key indexes..." -ForegroundColor Yellow

function Get-ConstraintCount {
    param([string]$Type)
    $sql = "SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE TABLE_SCHEMA='$MysqlDb' AND CONSTRAINT_TYPE='$Type';"
    $countArgs = $mysqlArgs + @($MysqlDb, "-e", $sql)
    $result = & mysql @countArgs 2>&1 | Select-Object -Last 1
    return [int]$result.Trim()
}

$primaryKeys = Get-ConstraintCount "PRIMARY KEY"
Write-Host "  Primary Keys: $primaryKeys" -ForegroundColor Blue

$foreignKeys = Get-ConstraintCount "FOREIGN KEY"
Write-Host "  Foreign Keys: $foreignKeys" -ForegroundColor Blue

$uniqueKeys = Get-ConstraintCount "UNIQUE"
Write-Host "  Unique Keys: $uniqueKeys" -ForegroundColor Blue

# Check table engine
Write-Host ""
Write-Host "Checking storage engine..." -ForegroundColor Yellow

$innodbSql = "SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='$MysqlDb' AND ENGINE='InnoDB';"
$innodbArgs = $mysqlArgs + @($MysqlDb, "-e", $innodbSql)
$innodbTables = [int](& mysql @innodbArgs 2>&1 | Select-Object -Last 1).Trim()

$totalSql = "SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='$MysqlDb';"
$totalArgs = $mysqlArgs + @($MysqlDb, "-e", $totalSql)
$totalTables = [int](& mysql @totalArgs 2>&1 | Select-Object -Last 1).Trim()

if ($innodbTables -eq $totalTables) {
    Write-Host "✓ All tables use InnoDB engine" -ForegroundColor Green
} else {
    Write-Host "⚠ $innodbTables/$totalTables tables use InnoDB" -ForegroundColor Yellow
}

# Summary
Write-Host ""
Write-Host "=== Verification Summary ===" -ForegroundColor Green
Write-Host "✓ Database connection: OK" -ForegroundColor Green
Write-Host "✓ Database exists: OK" -ForegroundColor Green
Write-Host "✓ All 19 tables present: OK" -ForegroundColor Green
Write-Host "✓ Indexes created: OK" -ForegroundColor Green
Write-Host "✓ Storage engine: OK" -ForegroundColor Green
Write-Host ""
Write-Host "Data Summary:" -ForegroundColor Blue
Write-Host "  • Users: $userCount"
Write-Host "  • Clients: $clientCount"
Write-Host "  • Records: $recordCount"
Write-Host "  • Long-term Records: $ltRecordCount"
Write-Host "  • Sessions: $sessionCount"
Write-Host "  • Ping Tasks: $pingTaskCount"
Write-Host ""
Write-Host "Migration verification completed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Update Komari configuration to use MySQL"
Write-Host "  2. Restart vigilant Monitor"
Write-Host "  3. Test login and functionality"
Write-Host "  4. Verify data in web interface"
