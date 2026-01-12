# Debezium CDC 实现 CQRS 架构 - 生产就绪部署指南

> **完整的 CDC (Change Data Capture) + CQRS 解决方案**
> 
> 本指南提供使用 Debezium、Kafka 和 PostgreSQL 构建生产级 CQRS 架构的完整步骤。

## 📋 目录

- [架构概览](#架构概览)
- [核心组件](#核心组件)
- [前置要求](#前置要求)
- [快速开始](#快速开始)
- [详细部署步骤](#详细部署步骤)
- [配置说明](#配置说明)
- [运维管理](#运维管理)
- [监控告警](#监控告警)
- [故障排查](#故障排查)
- [性能优化](#性能优化)
- [最佳实践](#最佳实践)

---

## 🏗️ 架构概览

### 整体架构图

```
┌──────────────────────────────────────────────────────────────────┐
│                      Application Layer                           │
│                    (Go Service - Hermet)                         │
└────────┬─────────────────────────────────────────────────────────┘
         │
         │ Write Operations
         ▼
┌────────────────────────────────────────────────────────────────────┐
│                     Write Side (PostgreSQL)                        │
│  ┌──────────────┐                              ┌──────────────┐    │
│  │  DB0 (Shard) │                              │  DB1 (Shard) │    │
│  │  - biz_user  │                              │  - biz_user  │    │
│  │  - channel   │                              │  - channel   │    │
│  │  - friendship│                              │  - friendship│    │
│  └─────┬────────┘                              └──────┬───────┘    │
└────────┼──────────────────────────────────────────────┼────────────┘
         │                                              │
         │ WAL (Write-Ahead Log)                        │
         │                                              │
┌────────▼──────────────────────────────────────────────▼───────────┐
│                     Debezium Connectors                           │
│  ┌──────────────────────┐         ┌──────────────────────┐        │
│  │  DB0 Connector       │         │  DB1 Connector       │        │
│  │  - Captures changes  │         │  - Captures changes  │        │
│  │  - Transforms events │         │  - Transforms events │        │
│  └──────────┬───────────┘         └──────────┬───────────┘        │
└─────────────┼────────────────────────────────┼────────────────────┘
              │                                │
              │ Change Events                  │
              ▼                                ▼
┌──────────────────────────────────────────────────────────────────┐
│                    Kafka Cluster (3 nodes)                       │
│  ┌─────────────────────────────────────────────────────────┐     │
│  │  Topics:                                                │     │
│  │  - cqrs.biz_user.changed                                │     │
│  │  - cqrs.channel.changed                                 │     │
│  │  - cqrs.channel_member.changed                          │     │
│  │  - cqrs.friendship.changed                              │     │
│  └─────────────────────────────────────────────────────────┘     │
└────────┬─────────────────────────────────────────────────────────┘
         │
         │ Consume Events
         ▼
┌──────────────────────────────────────────────────────────────────┐
│                    Consumer Services (Go)                        │
│  ┌──────────────┐   ┌──────────────┐   ┌──────────────┐          │
│  │ Conversation │   │   Contact    │   │    Push      │          │
│  │   Updater    │   │   Updater    │   │  Notifier    │          │
│  └──────┬───────┘   └──────┬───────┘   └──────┬───────┘          │
└─────────┼──────────────────┼──────────────────┼──────────────────┘
          │                  │                  │
          │ Update           │ Update           │ Send
          ▼                  ▼                  ▼
┌──────────────────────┐  ┌──────────────────┐  ┌────────────┐
│  Read Side (PG)      │  │  Read Side (PG)  │  │   WebSocket│
│  - conversation_view │  │  - contact_view  │  │   / Push   │
└──────────────────────┘  └──────────────────┘  └────────────┘
          ▲
          │ Read Queries
          │
┌─────────┴────────────────────────────────────────────────────────┐
│                    Application Layer                             │   
│                    (Read Operations)                             │
└──────────────────────────────────────────────────────────────────┘
```

### 数据流说明

1. **写入流程**：
   - 应用写入 PostgreSQL 写入侧（标准表）
   - PostgreSQL WAL 记录所有变更

2. **CDC 捕获**：
   - Debezium 监听 WAL
   - 实时捕获数据变更（INSERT/UPDATE/DELETE）
   - 转换为 JSON 事件并发送到 Kafka

3. **事件传输**：
   - Kafka 集群保存变更事件
   - 保证高可用和持久化（3 副本）

4. **消费处理**：
   - Consumer 服务订阅相应 Topic
   - 处理事件并更新读取侧（视图表）

5. **读取流程**：
   - 应用直接查询读取侧（优化后的视图表）
   - 极低延迟，无需 JOIN

---

## 🧩 核心组件

### 1. PostgreSQL (Write Side)

- **版本**: PostgreSQL 16+
- **配置**: 启用 WAL (logical replication)
- **分片**: 2 个数据库实例 (db0, db1)
- **端口**: 
  - DB0: 15432
  - DB1: 25432

### 2. Debezium Connect

- **版本**: Debezium 3.0
- **集群**: 3 节点（高可用）
- **端口**: 
  - Node 1: 18083
  - Node 2: 28083
  - Node 3: 38083
- **功能**:
  - CDC 捕获
  - 事件转换
  - 故障恢复

### 3. Kafka Cluster

- **版本**: Apache Kafka 3.x (KRaft)
- **集群**: 3 节点
- **认证**: OAuth2 (Keycloak)
- **加密**: SASL_SSL
- **端口**: 19092, 29092, 39092

### 4. Consumer Services

- **语言**: Go
- **框架**: 基于项目现有代码
- **功能**:
  - 监听 Kafka Topics
  - 更新读取侧视图表
  - 错误处理和重试

---

## 📦 前置要求

### 1. 运行环境

- Docker 20.10+
- Docker Compose 2.0+
- 至少 8GB RAM
- 至少 20GB 磁盘空间

### 2. 已部署服务

- ✅ Kafka 集群 (见 `scripts/docker/kafka/`)
- ✅ Keycloak (OAuth2 认证)
- ✅ PostgreSQL 分片实例 (见 `scripts/docker/postgresql/`)

### 3. 网络配置

- 确保 `jrmarcco_net` Docker 网络已创建
- 所有服务在同一网络中

```bash
# 检查网络
docker network ls | grep jrmarcco_net

# 如果不存在，创建网络
docker network create jrmarcco_net
```

---

## 🚀 快速开始

### 1. 配置环境变量

```bash
cd scripts/docker/debezium

# 复制环境变量模板
cp .env.example .env

# 编辑 .env 文件
vim .env
```

**.env 配置示例**：

```bash
# Keycloak
KC_URL=http://keycloak:8080
DEBEZIUM_CLIENT_ID=debezium-connect
DEBEZIUM_CLIENT_SECRET=your-secret-here

# Kafka SSL
KAFKA_KEY_PASSWORD=your-keystore-password

# PostgreSQL DB0
POSTGRES_DB0_HOST=pgsql-hermet-0
POSTGRES_DB0_PORT=5432
POSTGRES_DB0_USER=hermet_0
POSTGRES_DB0_PASSWORD=<passwd>
POSTGRES_DB0_DBNAME=hermet_db0

# PostgreSQL DB1
POSTGRES_DB1_HOST=pgsql-hermet-1
POSTGRES_DB1_PORT=5432
POSTGRES_DB1_USER=hermet_1
POSTGRES_DB1_PASSWORD=<passwd>
POSTGRES_DB1_DBNAME=hermet_db1
```

### 2. 在 Keycloak 中创建 Client

访问 Keycloak 管理界面: http://localhost:18080

1. 进入 `kafka` Realm
2. 创建新 Client:
   - Client ID: `debezium-connect`
   - Client Protocol: `openid-connect`
   - Access Type: `confidential`
3. 在 `Credentials` 标签页获取 Secret
4. 更新 `.env` 文件中的 `DEBEZIUM_CLIENT_SECRET`

### 3. 配置 PostgreSQL WAL

**为 DB0 配置 WAL**:

```bash
# 连接到 PostgreSQL 容器
docker exec -it pgsql-hermet-0 bash

# 编辑 postgresql.conf
echo "wal_level = logical" >> /var/lib/postgresql/data/postgresql.conf
echo "max_wal_senders = 10" >> /var/lib/postgresql/data/postgresql.conf
echo "max_replication_slots = 10" >> /var/lib/postgresql/data/postgresql.conf

# 退出容器
exit

# 重启 PostgreSQL
docker restart pgsql-hermet-0
```

**使用脚本自动配置**:

```bash
# 设置环境变量
export POSTGRES_HOST=localhost
export POSTGRES_PORT=15432
export POSTGRES_USER=hermet_0
export POSTGRES_PASSWORD=<passwd>
export POSTGRES_DB=hermet_db0
export PUBLICATION_NAME=debezium_db0_publication

# 运行脚本
chmod +x scripts/setup-postgres-wal.sh
./scripts/setup-postgres-wal.sh
```

**为 DB1 重复上述步骤** (端口 25432)。

### 4. 启动 Debezium Connect 集群

```bash
# 启动服务
docker-compose up -d

# 检查状态
docker-compose ps

# 查看日志
docker-compose logs -f debezium-connect-1
```

### 5. 注册 Connector

```bash
# 加载环境变量
source .env

# 注册 DB0 Connector
chmod +x scripts/register-connector.sh
./scripts/register-connector.sh connectors/postgres-db0-connector.json

# 注册 DB1 Connector
./scripts/register-connector.sh connectors/postgres-db1-connector.json
```

### 6. 验证部署

```bash
# 检查 Connector 状态
./scripts/monitor-connector.sh hermet-postgres-db0-connector

# 访问 Debezium UI
open http://localhost:18084

# 访问 Kafka UI 查看 Topics
open http://localhost:18081
```

**预期的 Kafka Topics**:

- `cqrs.biz_user.changed`
- `cqrs.channel.changed`
- `cqrs.channel_member.changed`
- `cqrs.friendship.changed`

---

## ⚙️ 配置说明

### Debezium Connector 配置详解

#### 核心配置

```json
{
  "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
  "tasks.max": "1",  // 单任务模式，保证顺序
  
  // 数据库连接
  "database.hostname": "pgsql-hermet-0",
  "database.port": "5432",
  "database.dbname": "hermet_db0",
  
  // 逻辑复制
  "plugin.name": "pgoutput",  // PostgreSQL 原生插件
  "slot.name": "debezium_db0_slot",
  "publication.name": "debezium_db0_publication"
}
```

#### 监听表配置

```json
{
  "table.include.list": "public.biz_user,public.channel,public.channel_member,public.friendship"
}
```

#### 快照模式

```json
{
  // initial: 首次启动时全量快照
  // schema_only: 仅快照 schema
  // never: 不快照
  "snapshot.mode": "initial",
  
  // 快照时不锁表（减少对写入影响）
  "snapshot.locking.mode": "none"
}
```

#### 事件转换

```json
{
  "transforms": "unwrap,route",
  
  // unwrap: 提取新记录状态
  "transforms.unwrap.type": "io.debezium.transforms.ExtractNewRecordState",
  "transforms.unwrap.add.fields": "op,source.ts_ms,source.db,source.table",
  
  // route: Topic 路由
  "transforms.route.type": "org.apache.kafka.connect.transforms.RegexRouter",
  "transforms.route.regex": "hermet\\.cqrs\\.hermet\\.db0\\.public\\.(.*)",
  "transforms.route.replacement": "cqrs.$1.changed"
}
```

#### 性能调优

```json
{
  // 批处理大小
  "max.batch.size": "2048",
  "max.queue.size": "8192",
  
  // 轮询间隔
  "poll.interval.ms": "1000",
  
  // 心跳检测（检测连接是否存活）
  "heartbeat.interval.ms": "10000"
}
```

#### 错误处理

```json
{
  // 重试配置
  "errors.retry.timeout": "300000",  // 5分钟
  "errors.retry.delay.initial.ms": "1000",
  "errors.retry.delay.max.ms": "30000",
  
  // 日志记录
  "errors.log.enable": "true",
  "errors.log.include.messages": "true"
}
```

### Topic 命名规则

| 原始表 | Connector 输出 Topic | 最终 Topic (经过转换) |
|--------|---------------------|----------------------|
| `public.biz_user` | `hermet.cqrs.hermet.db0.public.biz_user` | `cqrs.biz_user.changed` |
| `public.channel` | `hermet.cqrs.hermet.db0.public.channel` | `cqrs.channel.changed` |
| `public.channel_member` | `hermet.cqrs.hermet.db0.public.channel_member` | `cqrs.channel_member.changed` |
| `public.friendship` | `hermet.cqrs.hermet.db0.public.friendship` | `cqrs.friendship.changed` |

---

## 🔍 运维管理

### Connector 管理

#### 查看所有 Connectors

```bash
./scripts/monitor-connector.sh
```

#### 查看特定 Connector 状态

```bash
./scripts/monitor-connector.sh hermet-postgres-db0-connector
```

#### 暂停 Connector

```bash
curl -X PUT http://localhost:18083/connectors/hermet-postgres-db0-connector/pause
```

#### 恢复 Connector

```bash
curl -X PUT http://localhost:18083/connectors/hermet-postgres-db0-connector/resume
```

#### 重启 Connector

```bash
curl -X POST http://localhost:18083/connectors/hermet-postgres-db0-connector/restart
```

#### 删除 Connector

```bash
curl -X DELETE http://localhost:18083/connectors/hermet-postgres-db0-connector
```

### 日志管理

#### 查看 Connector 日志

```bash
# 实时日志
docker logs -f debezium-connect-1

# 最近 100 行
docker logs --tail 100 debezium-connect-1

# 搜索错误
docker logs debezium-connect-1 2>&1 | grep ERROR
```

#### 修改日志级别

编辑 `docker-compose.yaml`:

```yaml
environment:
  CONNECT_LOG4J_ROOT_LOGLEVEL: DEBUG
  CONNECT_LOG4J_LOGGERS: org.apache.kafka.connect=DEBUG,io.debezium=DEBUG
```

重启服务:

```bash
docker-compose restart debezium-connect-1
```

### 数据管理

#### 查看 Replication Slot

```bash
# 连接到 PostgreSQL
docker exec -it pgsql-hermet-0 psql -U hermet_0 -d hermet_db0

# 查看 Slots
SELECT * FROM pg_replication_slots;

# 查看 Slot 延迟
SELECT 
    slot_name,
    pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn)) AS replication_lag
FROM pg_replication_slots;
```

#### 清理旧 Slot (谨慎操作)

```sql
-- 仅在 Connector 已删除时执行
SELECT pg_drop_replication_slot('debezium_db0_slot');
```

---

## 📊 监控告警

### 关键指标

#### 1. Connector 健康状态

```bash
# 检查 Connector 状态
curl http://localhost:18083/connectors/hermet-postgres-db0-connector/status | jq '.connector.state'

# 期望输出: "RUNNING"
```

#### 2. 任务状态

```bash
# 检查 Task 状态
curl http://localhost:18083/connectors/hermet-postgres-db0-connector/status | jq '.tasks[].state'

# 期望输出: "RUNNING"
```

#### 3. 延迟监控

```sql
-- PostgreSQL 查询 (WAL 延迟)
SELECT 
    slot_name,
    pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn)) AS lag
FROM pg_replication_slots
WHERE slot_name LIKE 'debezium%';
```

#### 4. Kafka 消费延迟

通过 Kafka UI 监控:

- 访问: http://localhost:18081
- 查看 Consumer Group: `debezium-cluster`
- 检查 Lag

### 告警规则 (Prometheus)

```yaml
groups:
  - name: debezium
    rules:
      # Connector 停止
      - alert: DebeziumConnectorDown
        expr: debezium_connector_state != 0
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Debezium Connector is down"
          
      # Replication Lag 过高
      - alert: DebeziumReplicationLag
        expr: debezium_replication_lag_bytes > 10485760  # 10MB
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "Replication lag is too high"
```

---

## 🐛 故障排查

### 常见问题

#### 1. Connector 无法启动

**症状**: Connector 状态为 `FAILED`

**检查**:

```bash
# 查看错误日志
curl http://localhost:18083/connectors/hermet-postgres-db0-connector/status | jq '.connector.trace'

# 常见原因:
# - PostgreSQL 连接失败
# - 认证失败
# - WAL 未启用
# - Publication 不存在
```

**解决方案**:

```bash
# 1. 检查 PostgreSQL 连接
docker exec pgsql-hermet-0 psql -U hermet_0 -d hermet_db0 -c "SELECT 1"

# 2. 检查 WAL 配置
docker exec pgsql-hermet-0 psql -U hermet_0 -d hermet_db0 -c "SHOW wal_level"
# 应该输出: logical

# 3. 检查 Publication
docker exec pgsql-hermet-0 psql -U hermet_0 -d hermet_db0 -c "SELECT * FROM pg_publication"

# 4. 重新运行配置脚本
./scripts/setup-postgres-wal.sh
```

#### 2. Kafka 连接失败

**症状**: 日志中出现 "Cannot connect to Kafka"

**检查**:

```bash
# 测试 Kafka 连接
docker exec debezium-connect-1 kafka-topics --bootstrap-server kafka-1:9093 --list \
  --command-config /tmp/client.properties

# 检查证书
docker exec debezium-connect-1 ls -la /etc/kafka/certs/
```

**解决方案**:

```bash
# 1. 确保证书已挂载
docker inspect debezium-connect-1 | grep -A 5 Mounts

# 2. 测试 OAuth Token 获取
curl -X POST "${KC_URL}/realms/kafka/protocol/openid-connect/token" \
  -d "client_id=${DEBEZIUM_CLIENT_ID}" \
  -d "client_secret=${DEBEZIUM_CLIENT_SECRET}" \
  -d "grant_type=client_credentials"

# 3. 检查 Keycloak Client 配置
# - Client 必须存在
# - Access Type 必须是 confidential
# - Service Accounts Enabled 必须启用
```

#### 3. 事件未发送到 Kafka

**症状**: PostgreSQL 有数据变更，但 Kafka Topic 无消息

**检查**:

```bash
# 1. 检查 Replication Slot 是否活跃
docker exec pgsql-hermet-0 psql -U hermet_0 -d hermet_db0 -c \
  "SELECT * FROM pg_replication_slots WHERE slot_name = 'debezium_db0_slot'"

# 2. 检查 Publication 是否包含表
docker exec pgsql-hermet-0 psql -U hermet_0 -d hermet_db0 -c \
  "SELECT * FROM pg_publication_tables WHERE pubname = 'debezium_db0_publication'"

# 3. 触发测试变更
docker exec pgsql-hermet-0 psql -U hermet_0 -d hermet_db0 -c \
  "UPDATE biz_user SET updated_at = NOW() WHERE id = 1"

# 4. 检查 Kafka Topic
# 访问 Kafka UI: http://localhost:18081
```

**解决方案**:

```bash
# 如果 Publication 不包含表
docker exec pgsql-hermet-0 psql -U hermet_0 -d hermet_db0 <<-EOSQL
    ALTER PUBLICATION debezium_db0_publication ADD TABLE public.biz_user;
    ALTER PUBLICATION debezium_db0_publication ADD TABLE public.channel;
    ALTER PUBLICATION debezium_db0_publication ADD TABLE public.channel_member;
    ALTER PUBLICATION debezium_db0_publication ADD TABLE public.friendship;
EOSQL
```

#### 4. 延迟过高

**症状**: Replication Lag > 10MB

**检查**:

```sql
-- 查看延迟
SELECT 
    slot_name,
    pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn)) AS lag,
    active
FROM pg_replication_slots;
```

**解决方案**:

```bash
# 1. 增加 Connector 并行度
# 编辑 connector 配置，增加 tasks.max

# 2. 优化批处理大小
{
  "max.batch.size": "4096",  // 从 2048 增加到 4096
  "max.queue.size": "16384"  // 从 8192 增加到 16384
}

# 3. 减少不必要的表监听
# 移除不需要 CDC 的表

# 4. 检查 Consumer 消费速度
# 确保下游 Consumer 能够及时消费
```

---

## ⚡ 性能优化

### 1. PostgreSQL 优化

```sql
-- 调整 WAL 配置
ALTER SYSTEM SET wal_buffers = '16MB';
ALTER SYSTEM SET wal_writer_delay = '200ms';
ALTER SYSTEM SET max_wal_size = '2GB';
ALTER SYSTEM SET min_wal_size = '1GB';

-- 重启生效
SELECT pg_reload_conf();
```

### 2. Debezium 优化

```json
{
  // 批处理优化
  "max.batch.size": "4096",
  "max.queue.size": "16384",
  "poll.interval.ms": "500",
  
  // 并行任务 (根据表数量调整)
  "tasks.max": "2",
  
  // 快照优化
  "snapshot.fetch.size": "10240",
  "snapshot.max.threads": "2"
}
```

### 3. Kafka 优化

```yaml
# Producer 配置 (在 docker-compose.yaml 中)
CONNECT_PRODUCER_COMPRESSION_TYPE: snappy
CONNECT_PRODUCER_BATCH_SIZE: 32768
CONNECT_PRODUCER_LINGER_MS: 20
CONNECT_PRODUCER_BUFFER_MEMORY: 67108864  # 64MB
```

### 4. Consumer 优化 (Go 代码)

```go
// Kafka Consumer 配置
config := kafka.ReaderConfig{
    Brokers:  []string{"kafka-1:9093", "kafka-2:9093", "kafka-3:9093"},
    GroupID:  "cqrs-conversation-updater",
    Topic:    "cqrs.biz_user.changed",
    
    // 批量读取
    MinBytes: 10e3,  // 10KB
    MaxBytes: 10e6,  // 10MB
    MaxWait:  500 * time.Millisecond,
    
    // 并发配置
    Partition: 0,  // 多个实例处理不同分区
}

// 批量处理
func (c *Consumer) processBatch(messages []kafka.Message) error {
    // 批量更新数据库
    tx, _ := c.db.Begin()
    defer tx.Rollback()
    
    for _, msg := range messages {
        // 处理消息
    }
    
    return tx.Commit()
}
```

---

## 🎯 最佳实践

### 1. 数据一致性

✅ **推荐做法**:

- 使用幂等性操作（基于主键 UPSERT）
- 记录事件时间戳，处理乱序
- 实现补偿机制

```go
// 幂等更新示例
func (s *Service) updateConversationView(event *UserChangedEvent) error {
    _, err := s.db.Exec(`
        INSERT INTO user_conversation_view (id, user_id, peer_nickname, updated_at)
        VALUES ($1, $2, $3, $4)
        ON CONFLICT (id) 
        DO UPDATE SET 
            peer_nickname = EXCLUDED.peer_nickname,
            updated_at = EXCLUDED.updated_at
        WHERE user_conversation_view.updated_at < EXCLUDED.updated_at
    `, event.ID, event.UserID, event.Nickname, event.Timestamp)
    
    return err
}
```

### 2. 错误处理

✅ **推荐做法**:

- 实现重试机制（指数退避）
- 记录失败事件到 Dead Letter Queue
- 监控错误率

```go
func (c *Consumer) processWithRetry(msg kafka.Message, maxRetries int) error {
    var err error
    for i := 0; i < maxRetries; i++ {
        err = c.process(msg)
        if err == nil {
            return nil
        }
        
        // 指数退避
        time.Sleep(time.Duration(math.Pow(2, float64(i))) * time.Second)
    }
    
    // 发送到 DLQ
    c.sendToDLQ(msg, err)
    return err
}
```

### 3. 监控和告警

✅ **推荐做法**:

- 监控 Connector 状态
- 监控 Replication Lag
- 监控 Consumer Lag
- 设置告警阈值

### 4. 测试策略

✅ **推荐做法**:

- 单元测试: 测试事件处理逻辑
- 集成测试: 测试端到端流程
- 混沌测试: 模拟故障场景

```go
func TestUserChangedConsumer(t *testing.T) {
    // 1. 准备测试数据
    event := &UserChangedEvent{
        Op: "u",
        After: &User{
            ID:       1,
            Nickname: "TestUser",
            Avatar:   "avatar.jpg",
        },
    }
    
    // 2. 发送到 Kafka
    producer.WriteMessages(ctx, kafka.Message{
        Topic: "cqrs.biz_user.changed",
        Value: jsonEncode(event),
    })
    
    // 3. 等待处理
    time.Sleep(2 * time.Second)
    
    // 4. 验证结果
    var nickname string
    err := db.QueryRow(`
        SELECT peer_nickname 
        FROM user_conversation_view 
        WHERE peer_user_id = 1
    `).Scan(&nickname)
    
    assert.NoError(t, err)
    assert.Equal(t, "TestUser", nickname)
}
```

### 5. 容量规划

根据业务量估算资源需求:

| QPS | Kafka Partitions | Debezium Connect Nodes | Consumer Instances |
|-----|------------------|------------------------|-------------------|
| < 1K | 3 | 1 | 2 |
| 1K - 10K | 6 | 3 | 4-6 |
| 10K - 50K | 12 | 3 | 8-12 |
| > 50K | 24+ | 5+ | 16+ |

---

## 📚 相关文档

- [CQRS 实现指南](../../../docs/cqrs_implementation_guide.md)
- [CQRS 快速开始](../../../docs/cqrs_quick_start.md)
- [Debezium 官方文档](https://debezium.io/documentation/)
- [Kafka Connect 文档](https://docs.confluent.io/platform/current/connect/index.html)

---

## 🤝 贡献

如有问题或建议，请提交 Issue 或 Pull Request。

---

## 📄 License

MIT License
