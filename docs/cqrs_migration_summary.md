# CQRS 架构改造总结

## 📝 改造完成清单

### ✅ 已完成

#### 1. SQL 文件重构
- ✅ `scripts/sql/postgresql/02_channel_init.sql` 已完整重构为CQRS架构
- ✅ `scripts/sql/postgresql/01_user_init.sql` 已有版本号字段（info_ver）

#### 2. 新增表结构

**写入侧（标准化）：**
- ✅ `channel` - 频道表（已优化，添加了last_message_at字段）
- ✅ `channel_member` - 频道成员表（简化字段，添加joined_at/left_at）
- ✅ `channel_read_record` - 已读记录表
- ✅ `friendship` - 好友关系表（新增，独立管理好友）
- ✅ `channel_application` - 申请表（已优化索引）

**读取侧（冗余宽表）：**
- ✅ `user_conversation_view` - 用户会话视图表（替代原user_contact）
- ✅ `user_contact_view` - 用户联系人视图表（新增，用于通讯录）

**反向索引（加速同步）：**
- ✅ `conversation_reverse_index` - 会话反向索引
- ✅ `contact_reverse_index` - 联系人反向索引

#### 3. 文档完善
- ✅ `docs/cqrs_implementation_guide.md` - 详细实现指南（含代码示例）
- ✅ `docs/cqrs_quick_start.md` - 快速开始指南
- ✅ `docs/cqrs_migration_summary.md` - 本文档

---

## 🔄 主要变更对比

### 原表 vs 新表

| 原表名 | 新表名 | 变化说明 |
|--------|--------|---------|
| `user_contact` | `user_conversation_view` | ✅ 重命名，增强语义<br>✅ 新增单聊字段（peer_user_id, peer_nickname等）<br>✅ 新增消息快照（last_message_*）<br>✅ 新增mention_count字段 |
| - | `user_contact_view`（新增） | ✅ 通讯录专用表<br>✅ 支持分组、标签、星标 |
| - | `friendship`（新增） | ✅ 独立的好友关系表<br>✅ 支持备注名、来源、分组 |
| - | `conversation_reverse_index`（新增） | ✅ 会话反向索引<br>✅ 加速数据同步 |
| - | `contact_reverse_index`（新增） | ✅ 联系人反向索引<br>✅ 加速数据同步 |

### 字段变更详情

#### channel 表
```diff
+ last_message_at BIGINT  -- 新增：最后消息时间
- creator BIGINT
+ creator_id BIGINT  -- 重命名：语义更清晰
```

#### channel_member 表
```diff
- user_profile_ver INT
- user_avatar VARCHAR(256)
- user_alias VARCHAR(64)
- user_nickname VARCHAR(64)
- priority_order INT
+ nickname VARCHAR(64)  -- 简化：只保留群昵称
+ joined_at BIGINT      -- 新增：加入时间
+ left_at BIGINT        -- 新增：退出时间
```

#### user_conversation_view 表（原user_contact）
```diff
+ peer_user_id BIGINT            -- 新增：单聊对方ID
+ peer_nickname VARCHAR(64)      -- 新增：对方昵称（冗余）
+ peer_avatar VARCHAR(256)       -- 新增：对方头像（冗余）
+ remark_name VARCHAR(64)        -- 新增：备注名
+ is_starred BOOLEAN             -- 新增：星标
+ last_message_type VARCHAR(32)  -- 新增：消息类型
+ last_message_sender_name VARCHAR(64)  -- 新增：发送者昵称
+ mention_count INT              -- 新增：@我的消息数
+ conversation_info_ver INT      -- 重命名：原contact_info_ver
```

---

## 🗂️ 分表策略

### 推荐分表配置

```yaml
# 写入侧
channel:
  shard_count: 64
  shard_key: channel_id % 64

channel_member:
  shard_count: 64
  shard_key: channel_id % 64

friendship:
  shard_count: 256
  shard_key: user_id % 256

channel_read_record:
  shard_count: 256
  shard_key: user_id % 256

channel_application:
  shard_count: 256
  shard_key: target_id % 256

# 读取侧
user_conversation_view:
  shard_count: 256
  shard_key: user_id % 256

user_contact_view:
  shard_count: 256
  shard_key: user_id % 256

# 反向索引
conversation_reverse_index:
  shard_count: 256
  shard_key: peer_user_id % 256

contact_reverse_index:
  shard_count: 256
  shard_key: contact_user_id % 256
```

---

## 🚀 接下来的步骤

### 第1步：执行SQL脚本

```bash
# 1. 备份现有数据库（重要！）
pg_dump -U postgres -d hermet > backup_$(date +%Y%m%d).sql

# 2. 执行新的SQL脚本
psql -U postgres -d hermet -f scripts/sql/postgresql/02_channel_init.sql

# 3. 验证表结构
psql -U postgres -d hermet -c "\d+ user_conversation_view"
```

### 第2步：修改应用代码

#### 2.1 更新数据访问层（DAO）

需要修改的文件：
- `internal/repo/dao/channel_dao.go`
- `internal/repo/dao/channel_member_dao.go`

需要新增的文件：
- `internal/repo/dao/conversation_view_dao.go` ⭐
- `internal/repo/dao/contact_view_dao.go` ⭐
- `internal/repo/dao/friendship_dao.go` ⭐
- `internal/repo/dao/reverse_index_dao.go` ⭐

#### 2.2 更新仓储层（Repo）

需要修改的文件：
- `internal/repo/channel_repo.go`

#### 2.3 更新服务层（Service）

需要重点修改：
- `internal/service/channel_service.go`
- `internal/service/user_service.go`

实现双写逻辑：
```go
// 示例：添加好友
func (s *UserService) AddFriend(ctx context.Context, userA, userB int64) error {
    tx := s.db.BeginTx(ctx, nil)
    defer tx.Rollback()
    
    // 1. 写入侧
    s.channelDAO.CreateChannel(tx, ...)
    s.channelMemberDAO.AddMember(tx, ...)
    s.friendshipDAO.CreateFriendship(tx, ...)
    
    // 2. 读取侧
    s.conversationViewDAO.CreateView(tx, ...)
    s.contactViewDAO.CreateView(tx, ...)
    
    // 3. 反向索引
    s.reverseIndexDAO.CreateIndex(tx, ...)
    
    return tx.Commit()
}
```

### 第3步：数据迁移（如果已有数据）

```sql
-- 从旧表迁移到新表
INSERT INTO user_conversation_view (
    id, user_id, channel_id, conversation_type, 
    conversation_name, conversation_avatar, peer_user_id,
    last_message_id, last_message_content, last_message_sender_id,
    last_message_time, unread_count, is_muted, is_pinned, is_hidden,
    opened_at, created_at, updated_at
)
SELECT 
    id, user_id, channel_id, contact_type,
    contact_name, contact_avatar, peer_user_id,
    last_message_id, last_message_content, last_message_sender_id,
    last_message_time, unread_count, is_muted, is_pinned, is_hidden,
    joined_at, created_at, updated_at
FROM user_contact
WHERE left_at = 0;

-- 生成反向索引
INSERT INTO conversation_reverse_index (
    peer_user_id, owner_user_id, channel_id, created_at
)
SELECT 
    peer_user_id, user_id, channel_id, created_at
FROM user_conversation_view
WHERE conversation_type = 'single' AND peer_user_id IS NOT NULL;
```

### 第4步：测试验证

#### 4.1 单元测试

```bash
# 测试会话视图CRUD
go test -v ./internal/repo/dao/conversation_view_dao_test.go

# 测试反向索引
go test -v ./internal/repo/dao/reverse_index_dao_test.go
```

#### 4.2 集成测试

测试场景：
- ✅ 添加好友 → 验证双侧数据一致性
- ✅ 发送消息 → 验证会话视图更新
- ✅ 修改昵称 → 验证反向索引同步
- ✅ 查询会话列表 → 验证性能提升

#### 4.3 性能测试

```bash
# 对比查询性能
# 旧方案：JOIN多表
# 新方案：单表查询

ab -n 10000 -c 100 http://localhost:8080/api/conversations
```

### 第5步：监控上线

#### 5.1 添加监控指标

```go
// 数据一致性监控
consistency_check_total{table="conversation_view", status="ok|fail"}

// 同步延迟监控
sync_latency_seconds{source="channel", target="conversation_view"}

// 查询性能监控
query_duration_seconds{endpoint="/api/conversations", quantile="0.99"}
```

#### 5.2 灰度发布

1. 10% 用户流量
2. 观察监控指标
3. 逐步增加到 100%

---

## 📊 性能提升预期

| 指标 | 旧方案 | 新方案 | 提升 |
|------|--------|--------|------|
| 会话列表查询 | 100-200ms | 5-10ms | **10-20倍** |
| 通讯录查询 | 150-300ms | 10-20ms | **10-15倍** |
| 数据库负载 | 高（多次JOIN） | 低（单表查询） | **降低60%** |
| 分库分表可行性 | ❌ 不可行 | ✅ 完全支持 | - |

---

## ⚠️ 注意事项

### 1. 数据一致性

- 应用层双写：使用数据库事务保证原子性
- CDC同步：允许短暂不一致（100-500ms）

### 2. 存储成本

- 读取侧冗余大量数据
- 存储成本增加约 **1.5-2倍**
- 但性能提升远超成本

### 3. 反向索引维护

- 添加好友/会话时，必须同步创建反向索引
- 删除好友/会话时，必须同步删除反向索引
- 定期校验反向索引完整性

### 4. 版本号机制

```go
// 每次修改用户资料
UPDATE biz_user 
SET nickname = ?, info_ver = info_ver + 1
WHERE id = ?;

// 每次修改群信息
UPDATE channel 
SET channel_name = ?, channel_info_ver = channel_info_ver + 1
WHERE id = ?;
```

### 5. 数据修复

如果读取侧数据出现问题：

```bash
# 方案1：从写入侧全量重建
./scripts/rebuild_conversation_view.sh

# 方案2：通过反向索引定向修复
./scripts/repair_conversation_view.sh --user-id=12345

# 方案3：Kafka回溯重放
./scripts/replay_events.sh --from-offset=1000
```

---

## 🎓 学习资源

### 内部文档
1. `docs/cqrs_quick_start.md` - 快速理解CQRS
2. `docs/cqrs_implementation_guide.md` - 详细代码实现
3. `scripts/sql/postgresql/02_channel_init.sql` - 完整SQL定义

### 外部资源
1. [CQRS Pattern - Martin Fowler](https://martinfowler.com/bliki/CQRS.html)
2. [Event Sourcing](https://martinfowler.com/eaaDev/EventSourcing.html)
3. [Debezium CDC](https://debezium.io/documentation/)

---

## 📞 问题反馈

如果遇到问题：

1. 检查日志：`/var/log/hermet/app.log`
2. 查看监控：Grafana Dashboard
3. 数据校验：运行 `scripts/check_consistency.sh`

---

## ✅ 验收标准

改造完成后，应满足：

- [ ] 所有表结构创建成功
- [ ] 分表配置正确（按建议的分表数）
- [ ] 应用代码双写逻辑完整
- [ ] 反向索引正确维护
- [ ] 查询会话列表 < 10ms
- [ ] 数据一致性 > 99.9%
- [ ] 单元测试通过率 100%
- [ ] 压力测试通过

---

## 🎉 总结

**CQRS架构改造完成后，你将获得：**

1. ✅ **极致查询性能**：会话列表查询从100ms+ → 10ms-
2. ✅ **分库分表能力**：支持水平扩展到千万级用户
3. ✅ **清晰的架构**：读写分离，职责明确
4. ✅ **易于维护**：写入侧标准化，读取侧可重建

**代价：**
- 存储成本增加 1.5-2倍
- 实现复杂度中等
- 需要维护数据一致性

但这是值得的！🚀

---

最后更新：{{ now() }}
作者：AI Assistant
项目：Hermet IM System
