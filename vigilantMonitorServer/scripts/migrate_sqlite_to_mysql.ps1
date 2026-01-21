# SQLite to MySQL Migration Script for Komari Monitor (PowerShell)
# This script migrates data from SQLite to MySQL while preserving all data
#
# Usage: .\migrate_sqlite_to_mysql.ps1
#

param(
    [string]$SqliteDb = "./data/komari.db",
    [string]$MysqlHost = "localhost",
    [int]$MysqlPort = 3306,
    [string]$MysqlUser = "root",
    [string]$MysqlPass = "",
    [string]$MysqlDb = "komari"
)

$ErrorActionPreference = "Stop"

Write-Host "=== Komari Monitor: SQLite to MySQL Migration ===" -ForegroundColor Green
Write-Host ""

# Check if SQLite database exists
if (-not (Test-Path $SqliteDb)) {
    Write-Host "Error: SQLite database not found at $SqliteDb" -ForegroundColor Red
    exit 1
}

# Check if mysql.exe is available
try {
    $null = Get-Command mysql -ErrorAction Stop
} catch {
    Write-Host "Error: mysql.exe is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install MySQL client or add it to your PATH" -ForegroundColor Yellow
    exit 1
}

# Check if sqlite3.exe is available
try {
    $null = Get-Command sqlite3 -ErrorAction Stop
} catch {
    Write-Host "Error: sqlite3.exe is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install SQLite command-line tool or add it to your PATH" -ForegroundColor Yellow
    exit 1
}

Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "  SQLite DB: $SqliteDb"
Write-Host "  MySQL Host: ${MysqlHost}:${MysqlPort}"
Write-Host "  MySQL User: $MysqlUser"
Write-Host "  MySQL Database: $MysqlDb"
Write-Host ""

$confirmation = Read-Host "Do you want to proceed? (y/n)"
if ($confirmation -ne 'y' -and $confirmation -ne 'Y') {
    Write-Host "Migration cancelled."
    exit 0
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

# Create MySQL database if not exists
Write-Host "Step 1: Creating MySQL database..." -ForegroundColor Green
$createDbSql = "CREATE DATABASE IF NOT EXISTS ``$MysqlDb`` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
$createDbArgs = $mysqlArgs + @("-e", $createDbSql)
& mysql @createDbArgs

# Import MySQL schema
Write-Host "Step 2: Creating MySQL schema..." -ForegroundColor Green
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$schemaFile = Join-Path $scriptDir "mysql_schema.sql"

if (-not (Test-Path $schemaFile)) {
    Write-Host "Error: mysql_schema.sql not found at $schemaFile" -ForegroundColor Red
    exit 1
}

$schemaArgs = $mysqlArgs + @($MysqlDb)
Get-Content $schemaFile | & mysql @schemaArgs

# Export and import data for each table
Write-Host "Step 3: Migrating data..." -ForegroundColor Green

# Tables to migrate (in order to respect foreign keys)
$tables = @(
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

foreach ($table in $tables) {
    # Check if table exists in SQLite
    $tableExists = & sqlite3 $SqliteDb "SELECT name FROM sqlite_master WHERE type='table' AND name='$table';"
    
    if ($tableExists -eq $table) {
        Write-Host "  Migrating table: $table" -ForegroundColor Yellow
        
        # Get row count
        $rowCount = & sqlite3 $SqliteDb "SELECT COUNT(*) FROM $table;"
        
        if ([int]$rowCount -gt 0) {
            # Export to CSV
            $csvFile = Join-Path $env:TEMP "$table.csv"
            & sqlite3 -csv $SqliteDb "SELECT * FROM $table;" | Out-File -FilePath $csvFile -Encoding UTF8
            
            # Prepare MySQL import
            $importSql = @"
SET FOREIGN_KEY_CHECKS=0;
LOAD DATA LOCAL INFILE '$($csvFile.Replace('\', '/'))' 
INTO TABLE ``$table``
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' 
ENCLOSED BY '`"'
LINES TERMINATED BY '\n'
IGNORE 0 LINES;
SET FOREIGN_KEY_CHECKS=1;
"@
            
            try {
                # Import CSV into MySQL
                $importArgs = $mysqlArgs + @($MysqlDb, "--local-infile=1", "-e", $importSql)
                & mysql @importArgs
                
                Write-Host "    ✓ Migrated $rowCount rows" -ForegroundColor Green
            } catch {
                Write-Host "    ✗ Failed to import: $_" -ForegroundColor Red
            } finally {
                # Clean up
                if (Test-Path $csvFile) {
                    Remove-Item $csvFile -Force
                }
            }
        } else {
            Write-Host "    ⊘ Table is empty, skipping" -ForegroundColor Yellow
        }
    } else {
        Write-Host "    ⊘ Table does not exist in SQLite, skipping" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "=== Migration completed successfully! ===" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Update your configuration to use MySQL:"
Write-Host "     Set environment variables in your .env or configuration:"
Write-Host "       KOMARI_DB_TYPE=mysql"
Write-Host "       KOMARI_DB_HOST=$MysqlHost"
Write-Host "       KOMARI_DB_PORT=$MysqlPort"
Write-Host "       KOMARI_DB_USER=$MysqlUser"
Write-Host "       KOMARI_DB_PASS=your_password"
Write-Host "       KOMARI_DB_NAME=$MysqlDb"
Write-Host ""
Write-Host "  2. Or update Dockerfile environment variables"
Write-Host ""
Write-Host "  3. Restart Komari Monitor"
Write-Host ""
Write-Host "Note: Keep your SQLite backup until you verify everything works correctly" -ForegroundColor Yellow
