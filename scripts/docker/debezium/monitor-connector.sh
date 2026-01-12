#!/bin/bash

################################################################################
# Debezium Connector 监控脚本
# 用途：监控 Connector 状态、延迟、吞吐量等指标
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

# 默认配置
CONNECT_HOST=${CONNECT_HOST:-localhost}
CONNECT_PORT=${CONNECT_PORT:-18083}
CONNECTOR_NAME=${1:-""}

# 显示使用方法
usage() {
    echo "Usage: $0 [connector-name]"
    echo ""
    echo "Example:"
    echo "  $0 hermet-postgres-db0-connector"
    echo "  $0  # List all connectors"
    echo ""
    exit 1
}

# 列出所有 Connectors
list_connectors() {
    log_info "Available connectors:"
    echo ""

    local connectors=$(curl -s "http://${CONNECT_HOST}:${CONNECT_PORT}/connectors")

    if [ -z "$connectors" ] || [ "$connectors" = "[]" ]; then
        log_warn "No connectors found"
        return
    fi

    echo "$connectors" | jq -r '.[]' | while read -r name; do
        local status=$(curl -s "http://${CONNECT_HOST}:${CONNECT_PORT}/connectors/${name}/status")
        local state=$(echo "$status" | jq -r '.connector.state')

        if [ "$state" = "RUNNING" ]; then
            echo -e "  ${GREEN}●${NC} $name (${GREEN}$state${NC})"
        elif [ "$state" = "FAILED" ]; then
            echo -e "  ${RED}●${NC} $name (${RED}$state${NC})"
        else
            echo -e "  ${YELLOW}●${NC} $name (${YELLOW}$state${NC})"
        fi
    done

    echo ""
}

# 显示 Connector 详细状态
show_connector_status() {
    local name=$1

    log_info "Connector: $name"
    echo ""

    local status=$(curl -s "http://${CONNECT_HOST}:${CONNECT_PORT}/connectors/${name}/status")

    # Connector 状态
    local connector_state=$(echo "$status" | jq -r '.connector.state')
    local connector_worker=$(echo "$status" | jq -r '.connector.worker_id')

    echo "Connector Status:"
    if [ "$connector_state" = "RUNNING" ]; then
        echo -e "  State:  ${GREEN}$connector_state${NC}"
    else
        echo -e "  State:  ${RED}$connector_state${NC}"
    fi
    echo "  Worker: $connector_worker"
    echo ""

    # Tasks 状态
    echo "Tasks:"
    echo "$status" | jq -r '.tasks[] | "  Task \(.id): \(.state) (Worker: \(.worker_id))"' | while read -r line; do
        if echo "$line" | grep -q "RUNNING"; then
            echo -e "$line" | sed "s/RUNNING/${GREEN}RUNNING${NC}/"
        elif echo "$line" | grep -q "FAILED"; then
            echo -e "$line" | sed "s/FAILED/${RED}FAILED${NC}/"
        else
            echo "$line"
        fi
    done
    echo ""

    # 如果有失败的任务，显示错误信息
    if echo "$status" | jq -e '.tasks[] | select(.state == "FAILED")' > /dev/null; then
        log_error "Task errors:"
        echo "$status" | jq -r '.tasks[] | select(.state == "FAILED") | .trace'
    fi
}

# 显示 Connector 配置
show_connector_config() {
    local name=$1

    log_info "Configuration:"
    echo ""

    local config=$(curl -s "http://${CONNECT_HOST}:${CONNECT_PORT}/connectors/${name}")
    echo "$config" | jq '.config' | jq 'to_entries | .[] | "  \(.key): \(.value)"' -r
    echo ""
}

# 显示 Connector 指标
show_connector_metrics() {
    local name=$1

    log_info "Checking topics created by this connector..."
    echo ""

    # 注意：这需要 Kafka 可访问
    # 这里只是示例，实际需要根据环境调整
    log_warn "Metrics monitoring requires Prometheus/JMX integration"
    log_warn "Please check Kafka UI or Prometheus for detailed metrics"
    echo ""
}

# 暂停 Connector
pause_connector() {
    local name=$1

    log_info "Pausing connector: $name"

    curl -s -X PUT "http://${CONNECT_HOST}:${CONNECT_PORT}/connectors/${name}/pause"

    log_info "Connector paused"
}

# 恢复 Connector
resume_connector() {
    local name=$1

    log_info "Resuming connector: $name"

    curl -s -X PUT "http://${CONNECT_HOST}:${CONNECT_PORT}/connectors/${name}/resume"

    log_info "Connector resumed"
}

# 重启 Connector
restart_connector() {
    local name=$1

    log_info "Restarting connector: $name"

    curl -s -X POST "http://${CONNECT_HOST}:${CONNECT_PORT}/connectors/${name}/restart"

    log_info "Connector restarted"
}

# 删除 Connector
delete_connector() {
    local name=$1

    read -p "Are you sure you want to delete connector '$name'? (y/N) " -n 1 -r
    echo

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Cancelled"
        return
    fi

    log_info "Deleting connector: $name"

    curl -s -X DELETE "http://${CONNECT_HOST}:${CONNECT_PORT}/connectors/${name}"

    log_info "Connector deleted"
}

# 主函数
main() {
    echo "==============================================="
    echo "  Debezium Connector Monitor"
    echo "==============================================="
    echo ""

    if [ -z "$CONNECTOR_NAME" ]; then
        list_connectors
        exit 0
    fi

    # 检查 connector 是否存在
    if ! curl -s -f "http://${CONNECT_HOST}:${CONNECT_PORT}/connectors/${CONNECTOR_NAME}" > /dev/null 2>&1; then
        log_error "Connector '$CONNECTOR_NAME' not found"
        echo ""
        list_connectors
        exit 1
    fi

    show_connector_status "$CONNECTOR_NAME"
    show_connector_config "$CONNECTOR_NAME"
    show_connector_metrics "$CONNECTOR_NAME"

    # 交互式菜单
    echo "Actions:"
    echo "  1) Pause connector"
    echo "  2) Resume connector"
    echo "  3) Restart connector"
    echo "  4) Delete connector"
    echo "  5) Exit"
    echo ""
    read -p "Select action: " action

    case $action in
        1)
            pause_connector "$CONNECTOR_NAME"
            ;;
        2)
            resume_connector "$CONNECTOR_NAME"
            ;;
        3)
            restart_connector "$CONNECTOR_NAME"
            ;;
        4)
            delete_connector "$CONNECTOR_NAME"
            ;;
        5)
            log_info "Exiting..."
            ;;
        *)
            log_warn "Invalid action"
            ;;
    esac

    echo ""
}

# 运行主函数
main "$@"
