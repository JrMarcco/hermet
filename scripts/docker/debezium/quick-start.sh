#!/bin/bash

################################################################################
# Debezium CDC 快速部署脚本
# 用途：一键部署完整的 Debezium + CQRS 架构
################################################################################

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
DEBEZIUM_DIR="$SCRIPT_DIR/.."

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

# 打印标题
print_banner() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║                                                          ║"
    echo "║     Debezium CDC + CQRS 架构快速部署脚本                  ║"
    echo "║                                                          ║"
    echo "║     Author: Hermet Team                                 ║"
    echo "║     Version: 1.0.0                                      ║"
    echo "║                                                          ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo ""
}

# 检查前置条件
check_prerequisites() {
    log_step "检查前置条件..."

    local missing=0

    # 检查 Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed"
        missing=1
    else
        log_success "Docker: $(docker --version)"
    fi

    # 检查 Docker Compose
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        log_error "Docker Compose is not installed"
        missing=1
    else
        log_success "Docker Compose: OK"
    fi

    # 检查 curl
    if ! command -v curl &> /dev/null; then
        log_error "curl is not installed"
        missing=1
    else
        log_success "curl: OK"
    fi

    # 检查 jq
    if ! command -v jq &> /dev/null; then
        log_warn "jq is not installed (optional, but recommended)"
    else
        log_success "jq: OK"
    fi

    # 检查网络
    if ! docker network ls | grep -q jrmarcco_net; then
        log_warn "Docker network 'jrmarcco_net' not found, will create it"
        docker network create jrmarcco_net
        log_success "Network created"
    else
        log_success "Docker network: jrmarcco_net"
    fi

    if [ $missing -eq 1 ]; then
        log_error "Missing required tools, please install them first"
        exit 1
    fi

    echo ""
}

# 检查环境变量文件
check_env_file() {
    log_step "检查环境变量配置..."

    if [ ! -f "$DEBEZIUM_DIR/.env" ]; then
        log_warn ".env file not found"

        if [ -f "$DEBEZIUM_DIR/env.template" ]; then
            log_info "Copying env.template to .env"
            cp "$DEBEZIUM_DIR/env.template" "$DEBEZIUM_DIR/.env"

            echo ""
            log_error "Please edit .env file and fill in the actual values:"
            echo "  vim $DEBEZIUM_DIR/.env"
            echo ""
            log_info "Required fields:"
            echo "  - DEBEZIUM_CLIENT_SECRET"
            echo "  - KAFKA_KEY_PASSWORD"
            echo "  - POSTGRES_DB0_PASSWORD"
            echo "  - POSTGRES_DB1_PASSWORD"
            echo ""

            read -p "Press Enter after editing .env file..." -r
        else
            log_error "env.template not found"
            exit 1
        fi
    else
        log_success ".env file exists"
    fi

    # 加载环境变量
    source "$DEBEZIUM_DIR/.env"

    # 验证关键变量
    local missing_vars=0

    if [ -z "$DEBEZIUM_CLIENT_SECRET" ] || [ "$DEBEZIUM_CLIENT_SECRET" = "your-debezium-client-secret" ]; then
        log_error "DEBEZIUM_CLIENT_SECRET is not set"
        missing_vars=1
    fi

    if [ -z "$KAFKA_KEY_PASSWORD" ] || [ "$KAFKA_KEY_PASSWORD" = "your-keystore-password" ]; then
        log_error "KAFKA_KEY_PASSWORD is not set"
        missing_vars=1
    fi

    if [ $missing_vars -eq 1 ]; then
        log_error "Please update .env file with actual values"
        exit 1
    fi

    log_success "Environment variables validated"
    echo ""
}

# 检查依赖服务
check_dependencies() {
    log_step "检查依赖服务..."

    # 检查 Kafka
    if ! docker ps | grep -q kafka-1; then
        log_error "Kafka cluster is not running"
        log_info "Please start Kafka first:"
        echo "  cd $PROJECT_ROOT/scripts/docker/kafka"
        echo "  docker-compose up -d"
        exit 1
    else
        log_success "Kafka cluster is running"
    fi

    # 检查 PostgreSQL
    local pg_running=0
    if docker ps | grep -q pgsql-hermet-0; then
        log_success "PostgreSQL DB0 is running"
        pg_running=$((pg_running + 1))
    else
        log_warn "PostgreSQL DB0 is not running"
    fi

    if docker ps | grep -q pgsql-hermet-1; then
        log_success "PostgreSQL DB1 is running"
        pg_running=$((pg_running + 1))
    else
        log_warn "PostgreSQL DB1 is not running"
    fi

    if [ $pg_running -eq 0 ]; then
        log_error "No PostgreSQL instances running"
        log_info "Please start PostgreSQL first:"
        echo "  cd $PROJECT_ROOT/scripts/docker/postgresql"
        echo "  docker-compose up -d"
        exit 1
    fi

    echo ""
}

# 配置 PostgreSQL WAL
setup_postgresql_wal() {
    log_step "配置 PostgreSQL WAL..."

    # DB0
    if docker ps | grep -q pgsql-hermet-0; then
        log_info "Configuring PostgreSQL DB0..."

        export POSTGRES_HOST=localhost
        export POSTGRES_PORT=15432
        export POSTGRES_USER=${POSTGRES_DB0_USER}
        export POSTGRES_PASSWORD=${POSTGRES_DB0_PASSWORD}
        export POSTGRES_DB=${POSTGRES_DB0_DBNAME}
        export PUBLICATION_NAME=debezium_db0_publication

        if "$SCRIPT_DIR/setup-postgres-wal.sh"; then
            log_success "PostgreSQL DB0 configured"
        else
            log_error "Failed to configure PostgreSQL DB0"
            exit 1
        fi
    fi

    echo ""

    # DB1
    if docker ps | grep -q pgsql-hermet-1; then
        log_info "Configuring PostgreSQL DB1..."

        export POSTGRES_HOST=localhost
        export POSTGRES_PORT=25432
        export POSTGRES_USER=${POSTGRES_DB1_USER}
        export POSTGRES_PASSWORD=${POSTGRES_DB1_PASSWORD}
        export POSTGRES_DB=${POSTGRES_DB1_DBNAME}
        export PUBLICATION_NAME=debezium_db1_publication

        if "$SCRIPT_DIR/setup-postgres-wal.sh"; then
            log_success "PostgreSQL DB1 configured"
        else
            log_error "Failed to configure PostgreSQL DB1"
            exit 1
        fi
    fi

    echo ""
}

# 启动 Debezium Connect
start_debezium() {
    log_step "启动 Debezium Connect 集群..."

    cd "$DEBEZIUM_DIR"

    # 启动服务
    docker-compose up -d

    # 等待服务启动
    log_info "Waiting for Debezium Connect to be ready (max 180s)..."

    local max_wait=180
    local waited=0

    while [ $waited -lt $max_wait ]; do
        if curl -s -f http://localhost:18083/ > /dev/null 2>&1; then
            log_success "Debezium Connect is ready"
            break
        fi

        sleep 5
        waited=$((waited + 5))
        echo -n "."
    done

    echo ""

    if [ $waited -ge $max_wait ]; then
        log_error "Debezium Connect failed to start within ${max_wait}s"
        log_info "Check logs with: docker-compose logs debezium-connect-1"
        exit 1
    fi

    echo ""
}

# 注册 Connectors
register_connectors() {
    log_step "注册 Debezium Connectors..."

    # 加载环境变量
    source "$DEBEZIUM_DIR/.env"

    # DB0 Connector
    if docker ps | grep -q pgsql-hermet-0; then
        log_info "Registering DB0 Connector..."

        if "$SCRIPT_DIR/register-connector.sh" "$DEBEZIUM_DIR/connectors/postgres-db0-connector.json"; then
            log_success "DB0 Connector registered"
        else
            log_error "Failed to register DB0 Connector"
            exit 1
        fi
    fi

    echo ""

    # DB1 Connector
    if docker ps | grep -q pgsql-hermet-1; then
        log_info "Registering DB1 Connector..."

        if "$SCRIPT_DIR/register-connector.sh" "$DEBEZIUM_DIR/connectors/postgres-db1-connector.json"; then
            log_success "DB1 Connector registered"
        else
            log_error "Failed to register DB1 Connector"
            exit 1
        fi
    fi

    echo ""
}

# 验证部署
verify_deployment() {
    log_step "验证部署状态..."

    # 检查容器状态
    log_info "Container status:"
    docker-compose ps

    echo ""

    # 检查 Connector 状态
    log_info "Connector status:"
    curl -s http://localhost:18083/connectors | jq -r '.[]' | while read -r name; do
        local state=$(curl -s "http://localhost:18083/connectors/${name}/status" | jq -r '.connector.state')
        if [ "$state" = "RUNNING" ]; then
            echo -e "  ${GREEN}●${NC} $name: $state"
        else
            echo -e "  ${RED}●${NC} $name: $state"
        fi
    done

    echo ""
}

# 显示访问信息
show_access_info() {
    log_step "部署完成！"

    echo ""
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║                   访问信息                                ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo ""
    echo "Debezium Connect API:"
    echo "  - Node 1: http://localhost:18083"
    echo "  - Node 2: http://localhost:28083"
    echo "  - Node 3: http://localhost:38083"
    echo ""
    echo "Debezium UI:"
    echo "  - URL: http://localhost:18084"
    echo ""
    echo "Kafka UI:"
    echo "  - URL: http://localhost:18081"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "常用命令:"
    echo ""
    echo "  # 查看所有 Connectors"
    echo "  ./scripts/monitor-connector.sh"
    echo ""
    echo "  # 查看特定 Connector 状态"
    echo "  ./scripts/monitor-connector.sh hermet-postgres-db0-connector"
    echo ""
    echo "  # 查看日志"
    echo "  docker-compose logs -f debezium-connect-1"
    echo ""
    echo "  # 停止服务"
    echo "  docker-compose down"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "预期的 Kafka Topics:"
    echo "  - cqrs.biz_user.changed"
    echo "  - cqrs.channel.changed"
    echo "  - cqrs.channel_member.changed"
    echo "  - cqrs.friendship.changed"
    echo ""
    echo "在 Kafka UI 中查看: http://localhost:18081"
    echo ""
}

# 主函数
main() {
    print_banner

    check_prerequisites
    check_env_file
    check_dependencies

    # 询问是否配置 WAL
    echo ""
    read -p "是否需要配置 PostgreSQL WAL? (如果已配置，选择 N) [Y/n]: " -r
    echo ""
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        setup_postgresql_wal
    else
        log_info "Skipping PostgreSQL WAL configuration"
        echo ""
    fi

    start_debezium
    register_connectors
    verify_deployment
    show_access_info

    log_success "部署完成！"
}

# 错误处理
trap 'log_error "An error occurred. Exiting..."; exit 1' ERR

# 运行主函数
main "$@"
