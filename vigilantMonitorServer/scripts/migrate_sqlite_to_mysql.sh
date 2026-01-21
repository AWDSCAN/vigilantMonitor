#!/bin/bash
#
# SQLite to MySQL Migration Script for Komari Monitor
# This script migrates data from SQLite to MySQL while preserving all data
#
# Usage: ./migrate_sqlite_to_mysql.sh
#

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
SQLITE_DB="${SQLITE_DB:-./data/komari.db}"
MYSQL_HOST="${MYSQL_HOST:-localhost}"
MYSQL_PORT="${MYSQL_PORT:-3306}"
MYSQL_USER="${MYSQL_USER:-root}"
MYSQL_PASS="${MYSQL_PASS:-}"
MYSQL_DB="${MYSQL_DB:-komari}"

echo -e "${GREEN}=== Komari Monitor: SQLite to MySQL Migration ===${NC}"
echo ""

# Check if SQLite database exists
if [ ! -f "$SQLITE_DB" ]; then
    echo -e "${RED}Error: SQLite database not found at $SQLITE_DB${NC}"
    exit 1
fi

# Check if mysql client is installed
if ! command -v mysql &> /dev/null; then
    echo -e "${RED}Error: mysql client is not installed${NC}"
    exit 1
fi

# Check if sqlite3 is installed
if ! command -v sqlite3 &> /dev/null; then
    echo -e "${RED}Error: sqlite3 is not installed${NC}"
    exit 1
fi

echo -e "${YELLOW}Configuration:${NC}"
echo "  SQLite DB: $SQLITE_DB"
echo "  MySQL Host: $MYSQL_HOST:$MYSQL_PORT"
echo "  MySQL User: $MYSQL_USER"
echo "  MySQL Database: $MYSQL_DB"
echo ""

read -p "Do you want to proceed? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Migration cancelled."
    exit 0
fi

# Create MySQL database if not exists
echo -e "${GREEN}Step 1: Creating MySQL database...${NC}"
mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" ${MYSQL_PASS:+-p"$MYSQL_PASS"} -e "CREATE DATABASE IF NOT EXISTS \`$MYSQL_DB\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

# Import MySQL schema
echo -e "${GREEN}Step 2: Creating MySQL schema...${NC}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" ${MYSQL_PASS:+-p"$MYSQL_PASS"} "$MYSQL_DB" < "$SCRIPT_DIR/mysql_schema.sql"

# Export and import data for each table
echo -e "${GREEN}Step 3: Migrating data...${NC}"

# Tables to migrate (in order to respect foreign keys)
TABLES=(
    "schema_versions"
    "users"
    "sessions"
    "clients"
    "records"
    "records_long_term"
    "gpu_records"
    "gpu_records_long_term"
    "logs"
    "clipboards"
    "offline_notifications"
    "load_notifications"
    "ping_tasks"
    "ping_records"
    "oidc_providers"
    "message_sender_providers"
    "theme_configurations"
    "tasks"
    "task_results"
)

for table in "${TABLES[@]}"; do
    # Check if table exists in SQLite
    if sqlite3 "$SQLITE_DB" "SELECT name FROM sqlite_master WHERE type='table' AND name='$table';" | grep -q "$table"; then
        echo -e "${YELLOW}  Migrating table: $table${NC}"
        
        # Get row count
        ROW_COUNT=$(sqlite3 "$SQLITE_DB" "SELECT COUNT(*) FROM $table;")
        
        if [ "$ROW_COUNT" -gt 0 ]; then
            # Export to CSV with proper escaping
            sqlite3 -csv "$SQLITE_DB" "SELECT * FROM $table;" > "/tmp/${table}.csv"
            
            # Disable foreign key checks temporarily
            mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" ${MYSQL_PASS:+-p"$MYSQL_PASS"} "$MYSQL_DB" -e "SET FOREIGN_KEY_CHECKS=0;"
            
            # Import CSV into MySQL
            mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" ${MYSQL_PASS:+-p"$MYSQL_PASS"} "$MYSQL_DB" \
                --local-infile=1 \
                -e "LOAD DATA LOCAL INFILE '/tmp/${table}.csv'
                    INTO TABLE \`$table\`
                    FIELDS TERMINATED BY ',' 
                    ENCLOSED BY '\"'
                    LINES TERMINATED BY '\n'
                    IGNORE 0 LINES;"
            
            # Re-enable foreign key checks
            mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" ${MYSQL_PASS:+-p"$MYSQL_PASS"} "$MYSQL_DB" -e "SET FOREIGN_KEY_CHECKS=1;"
            
            # Clean up
            rm "/tmp/${table}.csv"
            
            echo -e "${GREEN}    ✓ Migrated $ROW_COUNT rows${NC}"
        else
            echo -e "${YELLOW}    ⊘ Table is empty, skipping${NC}"
        fi
    else
        echo -e "${YELLOW}    ⊘ Table does not exist in SQLite, skipping${NC}"
    fi
done

echo ""
echo -e "${GREEN}=== Migration completed successfully! ===${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Update your configuration to use MySQL:"
echo "     export KOMARI_DB_TYPE=mysql"
echo "     export KOMARI_DB_HOST=$MYSQL_HOST"
echo "     export KOMARI_DB_PORT=$MYSQL_PORT"
echo "     export KOMARI_DB_USER=$MYSQL_USER"
echo "     export KOMARI_DB_PASS=your_password"
echo "     export KOMARI_DB_NAME=$MYSQL_DB"
echo ""
echo "  2. Restart Komari Monitor"
echo ""
echo -e "${YELLOW}Note: Keep your SQLite backup until you verify everything works correctly${NC}"
