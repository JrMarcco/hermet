# Debezium CDC + CQRS 快速开始

> 🚀 **5 分钟部署完整的 CDC + CQRS 架构**

---

## 📁 目录结构

```
debezium/
├── README.md                          # 完整架构指南（必读）
├── DEPLOYMENT.md                      # 详细部署步骤
├── QUICKSTART.md                      # 本文件：快速开始
├── docker-compose.yaml                # Debezium Connect 集群配置
├── env.template                       # 环境变量模板
├── .gitignore                         # Git 忽略文件
│
├── connectors/                        # Connector 配置文件
│   ├── postgres-db0-connector.json   # DB0 连接器配置
│   └── postgres-db1-connector.json   # DB1 连接器配置
│
└── scripts/                           # 运维脚本
    ├── quick-start.sh                # 🌟 一键部署脚本
    ├── setup-postgres-wal.sh         # PostgreSQL WAL 配置
    ├── register-connector.sh         # Connector 注册脚本
    └── monitor-connector.sh          # Connector 监控脚本
```

---

## ⚡ 一键部署（推荐）

### 前置要求

✅ 以下服务必须已启动：
- Kafka 集群 (3 节点)
- Keycloak (OAuth2 认证)
- PostgreSQL (至少 1 个实例)

```bash
# 检查服务状态
docker ps | grep -E "kafka|keycloak|pgsql-hermet"
```

### 部署步骤

```bash
# 1. 进入 debezium 目录
cd scripts/docker/debezium

# 2. 配置环境变量
cp env.template .env
vim .env  # 填写必要的配置

# 3. 运行一键部署脚本
./scripts/quick-start.sh
```

**就这么简单！** 🎉

脚本会自动：
1. 检查前置条件
2. 配置 PostgreSQL WAL
3. 启动 Debezium Connect 集群
4. 注册 Connectors
5. 验证部署状态

---

## 🔧 必填配置

编辑 `.env` 文件，填写以下关键配置：

```bash
# Keycloak OAuth2
DEBEZIUM_CLIENT_SECRET=<在 Keycloak 中创建并获取>

# Kafka SSL
KAFKA_KEY_PASSWORD=<Kafka 密钥库密码>

# PostgreSQL DB0
POSTGRES_DB0_PASSWORD=<数据库密码>

# PostgreSQL DB1 (如果有第二个分片)
POSTGRES_DB1_PASSWORD=<数据库密码>
```

### 如何获取 `DEBEZIUM_CLIENT_SECRET`？

1. 访问 Keycloak: http://localhost:18080
2. 进入 `kafka` Realm
3. `Clients` -> `Create`
4. Client ID: `debezium-connect`
5. Access Type: `confidential`
6. 保存后，在 `Credentials` 标签获取 Secret

---

## 🧪 快速测试

### 1. 验证部署

```bash
# 查看 Connector 状态
./scripts/monitor-connector.sh

# 预期输出：
#   ● hermet-postgres-db0-connector (RUNNING)
#   ● hermet-postgres-db1-connector (RUNNING)
```

### 2. 访问 UI

- **Debezium UI**: http://localhost:18084
- **Kafka UI**: http://localhost:18081

### 3. 测试 CDC 流程

```bash
# 连接到 PostgreSQL
docker exec -it pgsql-hermet-0 psql -U hermet_0 -d hermet_db0

# 插入测试数据
INSERT INTO biz_user (id, nickname, avatar, created_at, updated_at)
VALUES (999999, 'TestUser', 'avatar.jpg', NOW(), NOW());

# 更新数据
UPDATE biz_user SET nickname = 'UpdatedUser' WHERE id = 999999;

# 退出
\q
```

**在 Kafka UI 中查看**:
- Topic: `cqrs.biz_user.changed`
- 应该能看到 2 条消息（INSERT + UPDATE）

---

## 📊 预期结果

### 1. 运行的容器

```bash
docker ps | grep debezium

# 预期输出：
# debezium-connect-1
# debezium-connect-2
# debezium-connect-3
# debezium-ui
```

### 2. 创建的 Kafka Topics

访问 http://localhost:18081，应该看到以下 Topics：

- ✅ `cqrs.biz_user.changed`
- ✅ `cqrs.channel.changed`
- ✅ `cqrs.channel_member.changed`
- ✅ `cqrs.friendship.changed`

### 3. Connector 状态

```bash
curl http://localhost:18083/connectors | jq '.'

# 预期输出：
# [
#   "hermet-postgres-db0-connector",
#   "hermet-postgres-db1-connector"
# ]
```

---

## 🔍 常用命令

### 查看状态

```bash
# 容器状态
docker-compose ps

# Connector 列表
./scripts/monitor-connector.sh

# 特定 Connector 状态
./scripts/monitor-connector.sh hermet-postgres-db0-connector
```

### 查看日志

```bash
# 实时日志
docker-compose logs -f debezium-connect-1

# 最近 100 行
docker logs --tail 100 debezium-connect-1

# 搜索错误
docker logs debezium-connect-1 2>&1 | grep ERROR
```

### 管理服务

```bash
# 停止服务
docker-compose down

# 重启服务
docker-compose restart

# 重新部署
docker-compose down && docker-compose up -d
```

---

## 🐛 快速排查

### 问题：Connector 无法启动

```bash
# 1. 检查 WAL 是否启用
docker exec pgsql-hermet-0 psql -U hermet_0 -d hermet_db0 -c "SHOW wal_level"
# 应该输出: logical

# 2. 如果不是，重新运行配置脚本
./scripts/setup-postgres-wal.sh
```

### 问题：Kafka 连接失败

```bash
# 1. 检查证书路径
ls -la ../kafka/certs/

# 2. 验证 Keycloak Client Secret
# 确保 .env 中的 DEBEZIUM_CLIENT_SECRET 正确
```

### 问题：没有事件发送到 Kafka

```bash
# 1. 检查 Replication Slot
docker exec pgsql-hermet-0 psql -U hermet_0 -d hermet_db0 -c \
  "SELECT * FROM pg_replication_slots"

# 2. 重启 Connector
curl -X POST http://localhost:18083/connectors/hermet-postgres-db0-connector/restart
```

---

## 📚 下一步

1. **阅读完整指南**: [README.md](README.md)
2. **开发 Consumer 服务**: 见 `docs/cqrs_implementation_guide.md`
3. **配置监控**: 设置 Prometheus + Grafana
4. **性能优化**: 调整批处理参数

---

## 🆘 获取帮助

遇到问题？

1. 📖 查看 [README.md#故障排查](README.md#故障排查)
2. 📋 查看 [DEPLOYMENT.md](DEPLOYMENT.md) 详细步骤
3. 📝 查看日志: `docker-compose logs -f`
4. 💬 联系团队或提交 Issue

---

## 🎯 架构示意图

```
PostgreSQL (Write) → Debezium → Kafka → Consumer → PostgreSQL (Read)
     ↓ WAL            ↓ CDC      ↓ Event   ↓ Process    ↓ View Tables
   [变更]           [捕获]      [传输]      [更新]        [查询]
```

**优势**:
- ✅ 读写分离
- ✅ 最终一致性
- ✅ 高性能查询
- ✅ 业务解耦
- ✅ 易于扩展

---

**Happy Coding!** 🚀
