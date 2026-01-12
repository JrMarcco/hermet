#!/bin/bash

################################################################################
# PostgreSQL WAL ( Write-Ahead Log ) 配置脚本
# 为 Debezium CDC 启用必要的 PostgreSQL 配置
################################################################################

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查必需的环境变量。
check_env() {
    local missing=0

    if [ -z "$POSTGRES_HOST" ]; then
        log_error "POSTGRES_HOST is not set"
        missing=1
    fi

    if [ -z "$POSTGRES_PORT" ]; then
        log_error "POSTGRES_PORT is not set"
        missing=1
    fi

    if [ -z "$POSTGRES_USER" ]; then
        log_error "POSTGRES_USER is not set"
        missing=1
    fi

    if [ -z "$POSTGRES_PASSWORD" ]; then
        log_error "POSTGRES_PASSWORD is not set"
        missing=1
    fi

    if [ -z "$POSTGRES_DB" ]; then
        log_error "POSTGRES_DB is not set"
        missing=1
    fi

    if [ $missing -eq 1 ]; then
        log_error "Missing required environment variables"
        exit 1
    fi
}

# 检查 PostgreSQL 连接。
check_connection() {
    log_info "Checking PostgreSQL connection..."

    if ! PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d $POSTGRES_DB -c "SELECT 1" > /dev/null 2>&1; then
        log_error "Cannot connect to PostgreSQL"
        exit 1
    fi

    log_info "PostgreSQL connection successful"
}

# 启用 WAL。
enable_wal() {
    log_info "Enabling WAL (Write-Ahead Logging)..."

    # 检查是否已经启用。
    local wal_level=$(PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d $POSTGRES_DB -tAc "SHOW wal_level")

    if [ "$wal_level" = "logical" ]; then
        log_info "WAL level is already set to 'logical'"
    else
        log_warn "WAL level is '$wal_level', need to be 'logical'"
        log_warn "Please update postgresql.conf with the following settings:"
        echo ""
        echo "  wal_level = logical"
        echo "  max_wal_senders = 10"
        echo "  max_replication_slots = 10"
        echo ""
        log_warn "Then restart PostgreSQL container"
        return 1
    fi
}

# 创建 replication user ( 如果不存在 )。
create_replication_user() {
    log_info "Creating replication user..."

    local repl_user="${POSTGRES_USER}_repl"
    local repl_password="${POSTGRES_PASSWORD}_repl"

    # 检查用户是否存在。
    local user_exists=$(PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d $POSTGRES_DB -tAc "SELECT 1 FROM pg_roles WHERE rolname='$repl_user'")

    if [ "$user_exists" = "1" ]; then
        log_info "Replication user '$repl_user' already exists"
    else
        PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d $POSTGRES_DB <<-EOSQL
            CREATE USER $repl_user WITH REPLICATION PASSWORD '$repl_password';
            GRANT SELECT ON ALL TABLES IN SCHEMA public TO $repl_user;
            ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO $repl_user;
EOSQL
        log_info "Replication user '$repl_user' created"
    fi

    echo ""
    log_info "Replication credentials:"
    echo "  Username: $repl_user"
    echo "  Password: $repl_password"
    echo ""
}

# 创建 Publication。
create_publication() {
    log_info "Creating publication..."

    local pub_name="${PUBLICATION_NAME:-debezium_publication}"

    # 检查 publication 是否存在。
    local pub_exists=$(PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d $POSTGRES_DB -tAc "SELECT 1 FROM pg_publication WHERE pubname='$pub_name'")

    if [ "$pub_exists" = "1" ]; then
        log_info "Publication '$pub_name' already exists"
    else
        PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d $POSTGRES_DB <<-EOSQL
            CREATE PUBLICATION $pub_name FOR TABLE
                public.biz_user,
                public.channel,
                public.channel_member,
                public.friendship;
EOSQL
        log_info "Publication '$pub_name' created"
    fi
}

# 创建心跳表。
create_heartbeat_table() {
    log_info "Creating heartbeat table..."

    PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d $POSTGRES_DB <<-EOSQL
        CREATE TABLE IF NOT EXISTS public.heartbeat (
            id SERIAL PRIMARY KEY,
            ts TIMESTAMP DEFAULT NOW()
        );

        INSERT INTO public.heartbeat (id, ts) VALUES (1, NOW())
        ON CONFLICT (id) DO NOTHING;
EOSQL

    log_info "Heartbeat table created"
}

# 验证配置。
verify_config() {
    log_info "Verifying configuration..."

    # 检查 wal_level。
    local wal_level=$(PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d $POSTGRES_DB -tAc "SHOW wal_level")
    log_info "  wal_level: $wal_level"

    # 检查 max_wal_senders。
    local max_wal_senders=$(PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d $POSTGRES_DB -tAc "SHOW max_wal_senders")
    log_info "  max_wal_senders: $max_wal_senders"

    # 检查 max_replication_slots。
    local max_replication_slots=$(PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d $POSTGRES_DB -tAc "SHOW max_replication_slots")
    log_info "  max_replication_slots: $max_replication_slots"

    # 检查 publication。
    local pub_count=$(PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d $POSTGRES_DB -tAc "SELECT COUNT(*) FROM pg_publication")
    log_info "  publications: $pub_count"

    echo ""
    log_info "Configuration verified successfully!"
}

main() {
    echo "==============================================="
    echo "  PostgreSQL WAL Setup for Debezium CDC"
    echo "==============================================="
    echo ""

    check_env
    check_connection

    if ! enable_wal; then
        log_error "Failed to enable WAL. Please check postgresql.conf"
        exit 1
    fi

    create_replication_user
    create_publication
    create_heartbeat_table
    verify_config

    echo ""
    log_info "PostgreSQL WAL setup completed successfully!"
    echo ""
}

main "$@"
