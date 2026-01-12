#!/bin/bash

################################################################################
# Debezium Connector 注册脚本
# 用途：注册 PostgreSQL Connector 到 Kafka Connect
################################################################################

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

log_debug() {
    echo -e "${BLUE}[DEBUG]${NC} $1"
}

# 默认配置
CONNECT_HOST=${CONNECT_HOST:-localhost}
CONNECT_PORT=${CONNECT_PORT:-18083}
CONNECTOR_FILE=${1:-""}

# 显示使用方法
usage() {
    echo "Usage: $0 <connector-config-file.json>"
    echo ""
    echo "Example:"
    echo "  $0 connectors/postgres-db0-connector.json"
    echo ""
    echo "Environment variables:"
    echo "  CONNECT_HOST  - Kafka Connect host (default: localhost)"
    echo "  CONNECT_PORT  - Kafka Connect port (default: 18083)"
    exit 1
}

# 检查参数
if [ -z "$CONNECTOR_FILE" ]; then
    log_error "Connector configuration file is required"
    usage
fi

if [ ! -f "$CONNECTOR_FILE" ]; then
    log_error "Connector file not found: $CONNECTOR_FILE"
    exit 1
fi

# 检查 Kafka Connect 是否可用
check_connect() {
    log_info "Checking Kafka Connect availability..."

    local max_retries=30
    local retry=0

    while [ $retry -lt $max_retries ]; do
        if curl -s -f "http://${CONNECT_HOST}:${CONNECT_PORT}/" > /dev/null 2>&1; then
            log_info "Kafka Connect is available"
            return 0
        fi

        retry=$((retry + 1))
        log_warn "Kafka Connect not ready, retrying in 5s... ($retry/$max_retries)"
        sleep 5
    done

    log_error "Kafka Connect is not available after $max_retries retries"
    exit 1
}

# 替换环境变量
replace_env_vars() {
    local content=$(cat "$CONNECTOR_FILE")

    # 使用 envsubst 替换环境变量（如果可用）
    if command -v envsubst > /dev/null 2>&1; then
        content=$(echo "$content" | envsubst)
    else
        # 手动替换常见的环境变量
        content=$(echo "$content" | sed "s/\${POSTGRES_DB0_HOST}/$POSTGRES_DB0_HOST/g")
        content=$(echo "$content" | sed "s/\${POSTGRES_DB0_PORT}/$POSTGRES_DB0_PORT/g")
        content=$(echo "$content" | sed "s/\${POSTGRES_DB0_USER}/$POSTGRES_DB0_USER/g")
        content=$(echo "$content" | sed "s/\${POSTGRES_DB0_PASSWORD}/$POSTGRES_DB0_PASSWORD/g")
        content=$(echo "$content" | sed "s/\${POSTGRES_DB0_DBNAME}/$POSTGRES_DB0_DBNAME/g")
        content=$(echo "$content" | sed "s/\${POSTGRES_DB1_HOST}/$POSTGRES_DB1_HOST/g")
        content=$(echo "$content" | sed "s/\${POSTGRES_DB1_PORT}/$POSTGRES_DB1_PORT/g")
        content=$(echo "$content" | sed "s/\${POSTGRES_DB1_USER}/$POSTGRES_DB1_USER/g")
        content=$(echo "$content" | sed "s/\${POSTGRES_DB1_PASSWORD}/$POSTGRES_DB1_PASSWORD/g")
        content=$(echo "$content" | sed "s/\${POSTGRES_DB1_DBNAME}/$POSTGRES_DB1_DBNAME/g")
        content=$(echo "$content" | sed "s/\${DEBEZIUM_CLIENT_ID}/$DEBEZIUM_CLIENT_ID/g")
        content=$(echo "$content" | sed "s/\${DEBEZIUM_CLIENT_SECRET}/$DEBEZIUM_CLIENT_SECRET/g")
        content=$(echo "$content" | sed "s/\${KAFKA_KEY_PASSWORD}/$KAFKA_KEY_PASSWORD/g")
        content=$(echo "$content" | sed "s|\${KC_URL}|$KC_URL|g")
    fi

    echo "$content"
}

# 注册 Connector
register_connector() {
    log_info "Registering connector from: $CONNECTOR_FILE"

    # 读取并替换环境变量
    local config=$(replace_env_vars)

    # 提取 connector name
    local connector_name=$(echo "$config" | grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4)

    if [ -z "$connector_name" ]; then
        log_error "Cannot extract connector name from config file"
        exit 1
    fi

    log_info "Connector name: $connector_name"

    # 检查 connector 是否已存在
    if curl -s -f "http://${CONNECT_HOST}:${CONNECT_PORT}/connectors/${connector_name}" > /dev/null 2>&1; then
        log_warn "Connector '$connector_name' already exists, updating..."

        # 更新 connector
        local response=$(curl -s -X PUT \
            -H "Content-Type: application/json" \
            -d "$config" \
            "http://${CONNECT_HOST}:${CONNECT_PORT}/connectors/${connector_name}/config")

        if echo "$response" | grep -q "error_code"; then
            log_error "Failed to update connector:"
            echo "$response" | jq '.'
            exit 1
        fi

        log_info "Connector updated successfully"
    else
        # 创建新 connector
        local response=$(curl -s -X POST \
            -H "Content-Type: application/json" \
            -d "$config" \
            "http://${CONNECT_HOST}:${CONNECT_PORT}/connectors")

        if echo "$response" | grep -q "error_code"; then
            log_error "Failed to register connector:"
            echo "$response" | jq '.'
            exit 1
        fi

        log_info "Connector registered successfully"
    fi
}

# 检查 Connector 状态
check_connector_status() {
    log_info "Checking connector status..."

    local connector_name=$(cat "$CONNECTOR_FILE" | grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4)

    sleep 3

    local status=$(curl -s "http://${CONNECT_HOST}:${CONNECT_PORT}/connectors/${connector_name}/status")

    echo ""
    log_info "Connector Status:"
    echo "$status" | jq '.'

    # 检查是否有任务失败
    if echo "$status" | jq -e '.connector.state == "FAILED"' > /dev/null; then
        log_error "Connector is in FAILED state"
        exit 1
    fi

    if echo "$status" | jq -e '.tasks[] | select(.state == "FAILED")' > /dev/null; then
        log_error "Some tasks are in FAILED state"
        exit 1
    fi

    log_info "Connector is running successfully"
}

# 列出所有 Connectors
list_connectors() {
    log_info "Current connectors:"
    curl -s "http://${CONNECT_HOST}:${CONNECT_PORT}/connectors" | jq '.'
}

# 主函数
main() {
    echo "==============================================="
    echo "  Debezium Connector Registration"
    echo "==============================================="
    echo ""

    check_connect
    register_connector
    check_connector_status

    echo ""
    list_connectors

    echo ""
    log_info "Registration completed!"
    echo ""
}

# 运行主函数
main "$@"
