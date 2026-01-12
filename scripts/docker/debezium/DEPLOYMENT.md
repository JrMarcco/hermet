# Debezium CDC 部署指南

## 📦 部署方式

### 方式一：一键部署（推荐）

使用自动化脚本快速部署整个架构：

```bash
cd scripts/docker/debezium

# 运行快速部署脚本
chmod +x scripts/quick-start.sh
./scripts/quick-start.sh
```

脚本会自动完成：
1. ✅ 检查前置条件
2. ✅ 验证环境配置
3. ✅ 配置 PostgreSQL WAL
4. ✅ 启动 Debezium Connect 集群
5. ✅ 注册 Connectors
6. ✅ 验证部署状态

---

### 方式二：手动部署

适合需要精细控制的场景。

#### 步骤 1: 准备环境配置

```bash
cd scripts/docker/debezium

# 复制环境变量模板
cp env.template .env

# 编辑配置文件
vim .env
```

**必填配置项**：

```bash
# Keycloak 配置
KC_URL=http://keycloak:8080
DEBEZIUM_CLIENT_ID=debezium-connect
DEBEZIUM_CLIENT_SECRET=<在 Keycloak 中创建并获取>

# Kafka 配置
KAFKA_KEY_PASSWORD=<Kafka 密钥库密码>

# PostgreSQL DB0
POSTGRES_DB0_HOST=pgsql-hermet-0
POSTGRES_DB0_PORT=5432
POSTGRES_DB0_USER=hermet_0
POSTGRES_DB0_PASSWORD=<数据库密码>
POSTGRES_DB0_DBNAME=hermet_db0

# PostgreSQL DB1
POSTGRES_DB1_HOST=pgsql-hermet-1
POSTGRES_DB1_PORT=5432
POSTGRES_DB1_USER=hermet_1
POSTGRES_DB1_PASSWORD=<数据库密码>
POSTGRES_DB1_DBNAME=hermet_db1
```

#### 步骤 2: 在 Keycloak 中创建 Client

1. 访问 Keycloak 管理界面: http://localhost:18080
2. 进入 `kafka` Realm
3. 点击 `Clients` -> `Create`
4. 填写信息：
   - Client ID: `debezium-connect`
   - Client Protocol: `openid-connect`
   - Access Type: `confidential`
5. 点击 `Save`
6. 进入 `Credentials` 标签页
7. 复制 `Secret` 值到 `.env` 文件的 `DEBEZIUM_CLIENT_SECRET`

#### 步骤 3: 配置 PostgreSQL WAL

**选项 A: 使用自动化脚本**

```bash
# 配置 DB0
export POSTGRES_HOST=localhost
export POSTGRES_PORT=15432
export POSTGRES_USER=hermet_0
export POSTGRES_PASSWORD=<passwd>
export POSTGRES_DB=hermet_db0
export PUBLICATION_NAME=debezium_db0_publication

chmod +x scripts/setup-postgres-wal.sh
./scripts/setup-postgres-wal.sh

# 配置 DB1
export POSTGRES_HOST=localhost
export POSTGRES_PORT=25432
export POSTGRES_USER=hermet_1
export POSTGRES_PASSWORD=<passwd>
export POSTGRES_DB=hermet_db1
export PUBLICATION_NAME=debezium_db1_publication

./scripts/setup-postgres-wal.sh
```

**选项 B: 手动配置**

```bash
# 1. 连接到 PostgreSQL 容器
docker exec -it pgsql-hermet-0 bash

# 2. 修改配置文件
cat >> /var/lib/postgresql/data/postgresql.conf <<EOF
wal_level = logical
max_wal_senders = 10
max_replication_slots = 10
EOF

# 3. 退出容器
exit

# 4. 重启 PostgreSQL
docker restart pgsql-hermet-0

# 5. 等待启动（约 10 秒）
sleep 10

# 6. 创建 Publication
docker exec -it pgsql-hermet-0 psql -U hermet_0 -d hermet_db0 <<-EOSQL
    CREATE PUBLICATION debezium_db0_publication FOR TABLE 
        public.biz_user,
        public.channel,
        public.channel_member,
        public.friendship;
EOSQL

# 7. 创建心跳表
docker exec -it pgsql-hermet-0 psql -U hermet_0 -d hermet_db0 <<-EOSQL
    CREATE TABLE IF NOT EXISTS public.heartbeat (
        id SERIAL PRIMARY KEY,
        ts TIMESTAMP DEFAULT NOW()
    );
    INSERT INTO public.heartbeat (id, ts) VALUES (1, NOW())
    ON CONFLICT (id) DO NOTHING;
EOSQL
```

**重复以上步骤配置 DB1**（将 `pgsql-hermet-0` 替换为 `pgsql-hermet-1`）。

#### 步骤 4: 启动 Debezium Connect 集群

```bash
# 确保在 debezium 目录
cd scripts/docker/debezium

# 启动服务
docker-compose up -d

# 查看状态
docker-compose ps

# 查看日志（等待服务完全启动）
docker-compose logs -f debezium-connect-1
```

**等待服务就绪**（约 60 秒）：

```bash
# 测试 API 是否可用
curl http://localhost:18083/

# 预期输出: {"version":"3.0.0","commit":"..."}
```

#### 步骤 5: 注册 Connectors

```bash
# 加载环境变量
source .env

# 注册 DB0 Connector
chmod +x scripts/register-connector.sh
./scripts/register-connector.sh connectors/postgres-db0-connector.json

# 注册 DB1 Connector
./scripts/register-connector.sh connectors/postgres-db1-connector.json
```

#### 步骤 6: 验证部署

```bash
# 查看所有 Connectors
curl http://localhost:18083/connectors | jq '.'

# 查看 DB0 Connector 状态
curl http://localhost:18083/connectors/hermet-postgres-db0-connector/status | jq '.'

# 使用监控脚本
chmod +x scripts/monitor-connector.sh
./scripts/monitor-connector.sh hermet-postgres-db0-connector
```

**检查 Kafka Topics**：

```bash
# 访问 Kafka UI
open http://localhost:18081

# 预期看到以下 Topics:
# - cqrs.biz_user.changed
# - cqrs.channel.changed
# - cqrs.channel_member.changed
# - cqrs.friendship.changed
```

---

## 🧪 测试部署

### 测试 CDC 流程

```bash
# 1. 连接到 PostgreSQL
docker exec -it pgsql-hermet-0 psql -U hermet_0 -d hermet_db0

# 2. 插入测试数据
INSERT INTO biz_user (id, nickname, avatar, created_at, updated_at)
VALUES (999999, 'TestUser', 'avatar.jpg', NOW(), NOW());

# 3. 更新测试数据
UPDATE biz_user SET nickname = 'UpdatedUser' WHERE id = 999999;

# 4. 退出
\q
```

**查看事件**：

```bash
# 访问 Kafka UI
open http://localhost:18081

# 进入 Topic: cqrs.biz_user.changed
# 应该能看到 2 条消息：
# - 第一条: INSERT 操作 (op: "c")
# - 第二条: UPDATE 操作 (op: "u")
```

**消息格式示例**：

```json
{
  "before": null,
  "after": {
    "id": 999999,
    "nickname": "UpdatedUser",
    "avatar": "avatar.jpg",
    "created_at": 1234567890,
    "updated_at": 1234567891
  },
  "source": {
    "version": "3.0.0.Final",
    "connector": "postgresql",
    "name": "hermet.db0",
    "ts_ms": 1234567891000,
    "db": "hermet_db0",
    "table": "biz_user"
  },
  "op": "u",
  "ts_ms": 1234567891234
}
```

---

## 🔧 常见问题排查

### 问题 1: Connector 启动失败

**症状**: Connector 状态为 `FAILED`

**检查**:

```bash
# 查看错误信息
curl http://localhost:18083/connectors/hermet-postgres-db0-connector/status | jq '.connector.trace'

# 查看日志
docker logs debezium-connect-1 | tail -50
```

**常见原因**:

1. PostgreSQL WAL 未启用
   ```bash
   # 验证 WAL 配置
   docker exec pgsql-hermet-0 psql -U hermet_0 -d hermet_db0 -c "SHOW wal_level"
   # 应该输出: logical
   ```

2. Publication 不存在
   ```bash
   # 检查 Publication
   docker exec pgsql-hermet-0 psql -U hermet_0 -d hermet_db0 -c "SELECT * FROM pg_publication"
   ```

3. 数据库连接失败
   ```bash
   # 测试连接
   docker exec pgsql-hermet-0 psql -U hermet_0 -d hermet_db0 -c "SELECT 1"
   ```

### 问题 2: Kafka 连接失败

**症状**: 日志中出现 "Cannot connect to Kafka"

**检查**:

```bash
# 确认 Kafka 正在运行
docker ps | grep kafka

# 测试 Kafka 连接
docker exec debezium-connect-1 curl -f http://kafka-1:9092

# 检查证书挂载
docker inspect debezium-connect-1 | grep -A 10 Mounts
```

**解决方案**:

1. 确保 Kafka 集群已启动
2. 检查 `DEBEZIUM_CLIENT_SECRET` 是否正确
3. 验证证书路径: `../kafka/certs`

### 问题 3: 没有事件发送到 Kafka

**症状**: 数据库有变更，但 Kafka Topic 无消息

**检查**:

```bash
# 1. 检查 Replication Slot
docker exec pgsql-hermet-0 psql -U hermet_0 -d hermet_db0 -c \
  "SELECT * FROM pg_replication_slots WHERE slot_name = 'debezium_db0_slot'"

# 2. 检查 Publication 包含的表
docker exec pgsql-hermet-0 psql -U hermet_0 -d hermet_db0 -c \
  "SELECT * FROM pg_publication_tables WHERE pubname = 'debezium_db0_publication'"

# 3. 触发测试变更
docker exec pgsql-hermet-0 psql -U hermet_0 -d hermet_db0 -c \
  "UPDATE biz_user SET updated_at = NOW() WHERE id = 1"
```

---

## 📊 监控和运维

### 查看服务状态

```bash
# 容器状态
docker-compose ps

# 服务健康检查
docker-compose ps | grep healthy

# 资源使用
docker stats debezium-connect-1 debezium-connect-2 debezium-connect-3
```

### 查看日志

```bash
# 实时日志
docker-compose logs -f

# 特定服务日志
docker-compose logs -f debezium-connect-1

# 最近 100 行
docker logs --tail 100 debezium-connect-1

# 搜索错误
docker logs debezium-connect-1 2>&1 | grep -i error
```

### 管理 Connectors

```bash
# 列出所有 Connectors
./scripts/monitor-connector.sh

# 查看特定 Connector
./scripts/monitor-connector.sh hermet-postgres-db0-connector

# 暂停 Connector
curl -X PUT http://localhost:18083/connectors/hermet-postgres-db0-connector/pause

# 恢复 Connector
curl -X PUT http://localhost:18083/connectors/hermet-postgres-db0-connector/resume

# 重启 Connector
curl -X POST http://localhost:18083/connectors/hermet-postgres-db0-connector/restart

# 删除 Connector
curl -X DELETE http://localhost:18083/connectors/hermet-postgres-db0-connector
```

---

## 🚀 下一步

部署完成后，您需要：

1. **开发 Consumer 服务**
   - 参考: `docs/cqrs_implementation_guide.md`
   - 消费 Kafka 事件并更新读取侧视图表

2. **配置监控告警**
   - 使用 Prometheus 监控 Connector 指标
   - 配置延迟告警

3. **性能测试**
   - 压测 CDC 捕获能力
   - 优化批处理参数

4. **生产环境部署**
   - 调整副本数
   - 配置备份策略
   - 实施灾难恢复计划

---

## 📚 相关文档

- [README.md](README.md) - 完整架构指南
- [CQRS 实现指南](../../../docs/cqrs_implementation_guide.md)
- [Debezium 官方文档](https://debezium.io/documentation/)

---

## 🆘 获取帮助

如遇问题：

1. 查看 [README.md#故障排查](README.md#故障排查)
2. 检查日志: `docker-compose logs -f`
3. 提交 Issue 或联系团队
