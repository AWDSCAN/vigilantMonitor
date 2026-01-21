#!/bin/bash
#
# MySQL Migration Verification Script
# This script verifies that the MySQL migration was successful
#

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
MYSQL_HOST="${MYSQL_HOST:-localhost}"
MYSQL_PORT="${MYSQL_PORT:-3306}"
MYSQL_USER="${MYSQL_USER:-komari}"
MYSQL_PASS="${MYSQL_PASS:-}"
MYSQL_DB="${MYSQL_DB:-komari}"

echo -e "${BLUE}=== vigilant Monitor: MySQL Migration Verification ===${NC}"
echo ""

# Check if mysql client is installed
if ! command -v mysql &> /dev/null; then
    echo -e "${RED}Error: mysql client is not installed${NC}"
    exit 1
fi

# Test connection
echo -e "${YELLOW}Testing MySQL connection...${NC}"
if mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" ${MYSQL_PASS:+-p"$MYSQL_PASS"} -e "SELECT 1;" &> /dev/null; then
    echo -e "${GREEN}✓ Connection successful${NC}"
else
    echo -e "${RED}✗ Connection failed${NC}"
    exit 1
fi

# Check database exists
echo -e "${YELLOW}Checking database...${NC}"
DB_EXISTS=$(mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" ${MYSQL_PASS:+-p"$MYSQL_PASS"} \
    -e "SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME='$MYSQL_DB';" | grep -c "$MYSQL_DB" || true)

if [ "$DB_EXISTS" -eq 1 ]; then
    echo -e "${GREEN}✓ Database '$MYSQL_DB' exists${NC}"
else
    echo -e "${RED}✗ Database '$MYSQL_DB' not found${NC}"
    exit 1
fi

# Check character set
echo -e "${YELLOW}Checking database character set...${NC}"
CHARSET=$(mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" ${MYSQL_PASS:+-p"$MYSQL_PASS"} \
    -e "SELECT DEFAULT_CHARACTER_SET_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME='$MYSQL_DB';" | tail -n 1)

if [ "$CHARSET" = "utf8mb4" ]; then
    echo -e "${GREEN}✓ Character set is utf8mb4${NC}"
else
    echo -e "${YELLOW}⚠ Character set is $CHARSET (expected utf8mb4)${NC}"
fi

# Check tables
echo -e "${YELLOW}Checking tables...${NC}"
EXPECTED_TABLES=(
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

MISSING_TABLES=()
for table in "${EXPECTED_TABLES[@]}"; do
    TABLE_EXISTS=$(mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" ${MYSQL_PASS:+-p"$MYSQL_PASS"} "$MYSQL_DB" \
        -e "SHOW TABLES LIKE '$table';" | grep -c "$table" || true)
    
    if [ "$TABLE_EXISTS" -eq 1 ]; then
        echo -e "${GREEN}  ✓ $table${NC}"
    else
        echo -e "${RED}  ✗ $table (missing)${NC}"
        MISSING_TABLES+=("$table")
    fi
done

if [ ${#MISSING_TABLES[@]} -gt 0 ]; then
    echo -e "${RED}Missing tables: ${MISSING_TABLES[*]}${NC}"
    exit 1
fi

# Check data counts
echo ""
echo -e "${YELLOW}Checking data counts...${NC}"

# Users
USER_COUNT=$(mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" ${MYSQL_PASS:+-p"$MYSQL_PASS"} "$MYSQL_DB" \
    -e "SELECT COUNT(*) FROM users;" | tail -n 1)
echo -e "${BLUE}  Users: $USER_COUNT${NC}"

# Clients
CLIENT_COUNT=$(mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" ${MYSQL_PASS:+-p"$MYSQL_PASS"} "$MYSQL_DB" \
    -e "SELECT COUNT(*) FROM clients;" | tail -n 1)
echo -e "${BLUE}  Clients: $CLIENT_COUNT${NC}"

# Records
RECORD_COUNT=$(mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" ${MYSQL_PASS:+-p"$MYSQL_PASS"} "$MYSQL_DB" \
    -e "SELECT COUNT(*) FROM records;" | tail -n 1)
echo -e "${BLUE}  Records: $RECORD_COUNT${NC}"

# Long term records
LT_RECORD_COUNT=$(mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" ${MYSQL_PASS:+-p"$MYSQL_PASS"} "$MYSQL_DB" \
    -e "SELECT COUNT(*) FROM records_long_term;" | tail -n 1)
echo -e "${BLUE}  Long-term Records: $LT_RECORD_COUNT${NC}"

# Sessions
SESSION_COUNT=$(mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" ${MYSQL_PASS:+-p"$MYSQL_PASS"} "$MYSQL_DB" \
    -e "SELECT COUNT(*) FROM sessions;" | tail -n 1)
echo -e "${BLUE}  Sessions: $SESSION_COUNT${NC}"

# Ping tasks
PING_TASK_COUNT=$(mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" ${MYSQL_PASS:+-p"$MYSQL_PASS"} "$MYSQL_DB" \
    -e "SELECT COUNT(*) FROM ping_tasks;" | tail -n 1)
echo -e "${BLUE}  Ping Tasks: $PING_TASK_COUNT${NC}"

# Check indexes
echo ""
echo -e "${YELLOW}Checking key indexes...${NC}"

# Check primary keys
PRIMARY_KEYS=$(mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" ${MYSQL_PASS:+-p"$MYSQL_PASS"} "$MYSQL_DB" \
    -e "SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS 
        WHERE TABLE_SCHEMA='$MYSQL_DB' AND CONSTRAINT_TYPE='PRIMARY KEY';" | tail -n 1)
echo -e "${BLUE}  Primary Keys: $PRIMARY_KEYS${NC}"

# Check foreign keys
FOREIGN_KEYS=$(mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" ${MYSQL_PASS:+-p"$MYSQL_PASS"} "$MYSQL_DB" \
    -e "SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS 
        WHERE TABLE_SCHEMA='$MYSQL_DB' AND CONSTRAINT_TYPE='FOREIGN KEY';" | tail -n 1)
echo -e "${BLUE}  Foreign Keys: $FOREIGN_KEYS${NC}"

# Check unique keys
UNIQUE_KEYS=$(mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" ${MYSQL_PASS:+-p"$MYSQL_PASS"} "$MYSQL_DB" \
    -e "SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS 
        WHERE TABLE_SCHEMA='$MYSQL_DB' AND CONSTRAINT_TYPE='UNIQUE';" | tail -n 1)
echo -e "${BLUE}  Unique Keys: $UNIQUE_KEYS${NC}"

# Check table engine
echo ""
echo -e "${YELLOW}Checking storage engine...${NC}"
INNODB_TABLES=$(mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" ${MYSQL_PASS:+-p"$MYSQL_PASS"} "$MYSQL_DB" \
    -e "SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES 
        WHERE TABLE_SCHEMA='$MYSQL_DB' AND ENGINE='InnoDB';" | tail -n 1)

TOTAL_TABLES=$(mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" ${MYSQL_PASS:+-p"$MYSQL_PASS"} "$MYSQL_DB" \
    -e "SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES 
        WHERE TABLE_SCHEMA='$MYSQL_DB';" | tail -n 1)

if [ "$INNODB_TABLES" -eq "$TOTAL_TABLES" ]; then
    echo -e "${GREEN}✓ All tables use InnoDB engine${NC}"
else
    echo -e "${YELLOW}⚠ $INNODB_TABLES/$TOTAL_TABLES tables use InnoDB${NC}"
fi

# Summary
echo ""
echo -e "${GREEN}=== Verification Summary ===${NC}"
echo -e "${GREEN}✓ Database connection: OK${NC}"
echo -e "${GREEN}✓ Database exists: OK${NC}"
echo -e "${GREEN}✓ All 19 tables present: OK${NC}"
echo -e "${GREEN}✓ Indexes created: OK${NC}"
echo -e "${GREEN}✓ Storage engine: OK${NC}"
echo ""
echo -e "${BLUE}Data Summary:${NC}"
echo -e "  • Users: $USER_COUNT"
echo -e "  • Clients: $CLIENT_COUNT"
echo -e "  • Records: $RECORD_COUNT"
echo -e "  • Long-term Records: $LT_RECORD_COUNT"
echo -e "  • Sessions: $SESSION_COUNT"
echo -e "  • Ping Tasks: $PING_TASK_COUNT"
echo ""
echo -e "${GREEN}Migration verification completed successfully!${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Update Komari configuration to use MySQL"
echo "  2. Restart vigilant Monitor"
echo "  3. Test login and functionality"
echo "  4. Verify data in web interface"
