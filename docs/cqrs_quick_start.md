# CQRS 架构快速开始

本文档帮助你快速理解和使用 CQRS 架构的数据库设计。

## 🎯 核心概念（3分钟理解）

### 什么是 CQRS？

**CQRS = Command Query Responsibility Segregation（命令查询职责分离）**

简单来说：
- **写操作** → 写入标准化的表（写入侧）
- **读操作** → 读取优化过的表（读取侧）
- **同步机制** → 保证两侧数据一致

### 为什么需要 CQRS？

在分库分表场景下：

❌ **传统方案的问题**：
```sql
-- 查询会话列表需要JOIN多张表
SELECT 
    uc.channel_id,
    c.channel_name,    -- 来自 channel 表（不同分表）
    u.nickname,        -- 来自 user 表（不同分表）
    m.content          -- 来自 message 表（不同分表）
FROM user_channel uc
LEFT JOIN channel c ON uc.channel_id = c.id
LEFT JOIN user u ON uc.peer_user_id = u.id
LEFT JOIN message m ON uc.last_message_id = m.id
WHERE uc.user_id = ?
```
**问题**：分库分表后，跨表JOIN不可行！

✅ **CQRS方案**：
```sql
-- 单表查询，所有数据都在一个表
SELECT 
    channel_id,
    conversation_name,    -- 冗余存储
    peer_nickname,        -- 冗余存储
    last_message_content  -- 冗余存储
FROM user_conversation_view
WHERE user_id = ?
ORDER BY last_message_time DESC
```
**优点**：1次查询，毫秒级响应！

---

## 📊 架构图示

```
┌─────────────────────────────────────────────────────────┐
│                      应用层                              │
└────────┬────────────────────────────────────────┬───────┘
         │                                        │
         │ 写操作                                  │ 读操作
         ▼                                        ▼
┌──────────────────┐                    ┌──────────────────┐
│  写入侧 (标准化)  │                    │  读取侧 (冗余)    │
├──────────────────┤                    ├──────────────────┤
│ channel          │                    │ conversation_    │
│ channel_member   │ ────同步───>       │   view           │
│ friendship       │                    │ contact_view     │
│                  │                    │                  │
│ ✅ 无冗余         │                    │ ✅ 完全冗余       │
│ ✅ 强一致性       │                    │ ✅ 查询极快       │
│ ❌ 查询需JOIN     │                    │ ❌ 需要同步       │
└──────────────────┘                    └──────────────────┘
```

---

## 🗂️ 表结构概览

### 写入侧（5张表）

| 表名 | 职责 | 分表键 | 说明 |
|------|------|--------|------|
| `channel` | 频道（群聊/单聊） | channel_id % 64 | 核心表，无冗余 |
| `channel_member` | 频道成员关系 | channel_id % 64 | 标准化关系 |
| `channel_read_record` | 已读记录 | user_id % 256 | 记录用户已读位置 |
| `friendship` | 好友关系 | user_id % 256 | 单独管理好友关系 |
| `channel_application` | 好友/入群申请 | target_id % 256 | 申请记录 |

### 读取侧（2张表）

| 表名 | 职责 | 分表键 | 说明 |
|------|------|--------|------|
| `user_conversation_view` | 用户会话视图 | user_id % 256 | **会话列表专用**，冗余所有展示字段 |
| `user_contact_view` | 用户联系人视图 | user_id % 256 | **通讯录专用**，冗余好友信息 |

### 反向索引（2张表）

| 表名 | 职责 | 分表键 | 说明 |
|------|------|--------|------|
| `conversation_reverse_index` | 会话反向索引 | peer_user_id % 256 | 快速找到"谁的会话中有我" |
| `contact_reverse_index` | 联系人反向索引 | contact_user_id % 256 | 快速找到"谁的联系人中有我" |

---

## 🚀 常见操作示例

### 1️⃣ 查询会话列表（读操作）

```sql
-- 直接查读取侧，性能极好
SELECT 
    channel_id,
    conversation_type,
    conversation_name,          -- 冗余字段
    conversation_avatar,        -- 冗余字段
    last_message_content,       -- 冗余字段
    last_message_sender_name,   -- 冗余字段
    last_message_time,
    unread_count,
    is_pinned,
    is_muted
FROM user_conversation_view_{user_id % 256}
WHERE user_id = 12345
    AND closed_at = 0
    AND is_hidden = FALSE
ORDER BY is_pinned DESC, last_message_time DESC
LIMIT 50;
```

**性能**：单表查询，< 10ms

### 2️⃣ 添加好友（写操作）

```sql
-- 伪代码，实际是事务中多条SQL

-- 1. 写入侧（标准化）
INSERT INTO channel ...              -- 创建单聊频道
INSERT INTO channel_member ...       -- 添加成员A
INSERT INTO channel_member ...       -- 添加成员B
INSERT INTO friendship ...           -- 添加好友关系（双向）

-- 2. 读取侧（冗余）
INSERT INTO user_conversation_view ... -- A的会话视图
INSERT INTO user_conversation_view ... -- B的会话视图
INSERT INTO user_contact_view ...      -- A的联系人视图
INSERT INTO user_contact_view ...      -- B的联系人视图

-- 3. 反向索引
INSERT INTO conversation_reverse_index ... -- B在A的会话中
INSERT INTO conversation_reverse_index ... -- A在B的会话中
INSERT INTO contact_reverse_index ...      -- B在A的联系人中
INSERT INTO contact_reverse_index ...      -- A在B的联系人中
```

### 3️⃣ 用户修改昵称（更新操作）

```sql
-- 1. 更新写入侧
UPDATE user 
SET nickname = '新昵称', profile_ver = profile_ver + 1
WHERE id = 12345;

-- 2. 查询反向索引：谁的会话中有我？
SELECT owner_user_id, channel_id
FROM conversation_reverse_index_{12345 % 256}
WHERE peer_user_id = 12345;
-- 结果：[{owner: 100, channel: 1001}, {owner: 200, channel: 1002}, ...]

-- 3. 批量更新这些人的会话视图
UPDATE user_conversation_view_{100 % 256}
SET peer_nickname = '新昵称',
    conversation_name = COALESCE(remark_name, '新昵称'),  -- 优先备注名
    peer_avatar = '新头像'
WHERE user_id = 100 AND channel_id = 1001;

UPDATE user_conversation_view_{200 % 256}
SET peer_nickname = '新昵称', ...
WHERE user_id = 200 AND channel_id = 1002;
```

**关键**：通过反向索引，精确找到需要更新的记录，避免全表扫描！

---

## 🔄 数据同步机制

### 方式1：应用层双写（推荐新手）

**特点**：
- ✅ 简单易懂
- ✅ 强一致性
- ❌ 业务代码耦合

**实现**：在同一个事务中，同时写入"写入侧"和"读取侧"

```go
tx.Begin()
// 写入侧
InsertChannel(...)
InsertChannelMember(...)
// 读取侧
InsertConversationView(...)
// 反向索引
InsertReverseIndex(...)
tx.Commit()
```

### 方式2：CDC + Kafka（推荐生产环境）

**特点**：
- ✅ 解耦
- ✅ 高性能
- ❌ 复杂度高
- ❌ 最终一致性

**实现**：
1. Debezium监听数据库变更（Binlog/WAL）
2. 变更事件推送到Kafka
3. 消费者订阅Kafka，更新读取侧

```
PostgreSQL (写入侧)
    │
    │ Debezium监听
    ▼
  Kafka
    │
    │ 消费者订阅
    ▼
PostgreSQL (读取侧)
```

---

## 📝 关键字段说明

### user_conversation_view 表（会话视图）

| 字段 | 类型 | 说明 | 来源 |
|------|------|------|------|
| `conversation_name` | varchar | 会话显示名称 | 冗余：单聊=对方昵称，群聊=群名 |
| `conversation_avatar` | varchar | 会话显示头像 | 冗余：单聊=对方头像，群聊=群头像 |
| `peer_user_id` | bigint | 单聊对方ID | 用于快速判断是否已存在会话 |
| `peer_nickname` | varchar | 对方昵称 | 冗余自user表 |
| `remark_name` | varchar | 好友备注 | 来自friendship表 |
| `last_message_*` | - | 最后消息快照 | 冗余自message表 |
| `unread_count` | int | 未读数 | 实时更新 |
| `conversation_info_ver` | int | 版本号 | 用于检测信息变更 |

### 为什么要冗余这么多字段？

**场景**：显示会话列表

传统方案（需要5次查询或JOIN）：
1. 查询user_channel → 得到channel_id列表
2. 查询channel → 得到群名、群头像
3. 查询user → 得到对方昵称、头像
4. 查询message → 得到最后消息
5. 计算未读数

CQRS方案（1次查询）：
```sql
SELECT * FROM user_conversation_view WHERE user_id = ?
```
所有信息都在！

---

## 🎓 最佳实践

### 1. 版本号机制

**目的**：检测信息是否变更，决定是否需要同步

```sql
-- channel表
channel_info_ver INT  -- 每次修改群名/头像时 +1

-- user表（需要在01_user_init.sql中添加）
profile_ver INT  -- 每次修改昵称/头像时 +1

-- conversation_view表
conversation_info_ver INT  -- 存储当前同步的版本号
```

**使用**：
```go
// 客户端定期检查版本
if conversation.InfoVer < channel.InfoVer {
    // 版本落后，需要更新
    UpdateConversationView(...)
}
```

### 2. 反向索引的作用

**问题**：用户A修改了头像，如何知道要更新哪些人的会话视图？

**方案1**：全表扫描（❌ 太慢）
```sql
UPDATE user_conversation_view
SET peer_avatar = '新头像'
WHERE peer_user_id = A  -- 全表扫描所有分表！
```

**方案2**：反向索引（✅ 快速）
```sql
-- 1. 查询反向索引
SELECT owner_user_id FROM conversation_reverse_index WHERE peer_user_id = A
-- 结果：[100, 200, 300, ...]

-- 2. 精确更新
UPDATE user_conversation_view_{100 % 256} SET ... WHERE user_id = 100
UPDATE user_conversation_view_{200 % 256} SET ... WHERE user_id = 200
```

### 3. 分表数量建议

| 表 | 分表数 | 原因 |
|----|--------|------|
| channel_* | 64 | 按channel_id分表，群聊相对较少 |
| user_* | 256 | 按user_id分表，用户量大 |
| *_view | 256 | 按user_id分表，查询都是按用户 |
| *_reverse_index | 256 | 按反向key分表，更新频繁 |

---

## 🔍 调试技巧

### 检查数据一致性

```sql
-- 检查会话视图是否与channel表一致
SELECT 
    cv.channel_id,
    cv.conversation_name AS view_name,
    c.channel_name AS channel_name,
    cv.conversation_info_ver AS view_ver,
    c.channel_info_ver AS channel_ver
FROM user_conversation_view cv
LEFT JOIN channel c ON cv.channel_id = c.id
WHERE cv.conversation_info_ver < c.channel_info_ver;
-- 结果：版本落后的记录
```

### 查看反向索引

```sql
-- 查看用户A在谁的会话中
SELECT 
    cri.owner_user_id,
    cri.channel_id,
    u.nickname AS owner_name
FROM conversation_reverse_index cri
LEFT JOIN user u ON cri.owner_user_id = u.id
WHERE cri.peer_user_id = 12345;
```

---

## 📚 下一步

1. **阅读完整实现指南**：`docs/cqrs_implementation_guide.md`
2. **查看SQL定义**：`scripts/sql/postgresql/02_channel_init.sql`
3. **开始编码**：参考实现指南中的Go代码示例

---

## ❓ 常见问题

### Q1: 读取侧数据损坏怎么办？

**A**: 从写入侧重建！

```sql
-- 重建会话视图（伪代码）
TRUNCATE user_conversation_view;

INSERT INTO user_conversation_view
SELECT 
    cm.user_id,
    cm.channel_id,
    c.channel_type,
    c.channel_name,
    c.channel_avatar,
    -- ... 从写入侧重新生成所有字段
FROM channel_member cm
LEFT JOIN channel c ON cm.channel_id = c.id
WHERE cm.left_at = 0;
```

### Q2: 延迟有多大？

| 同步方式 | 延迟 |
|---------|------|
| 应用层双写 | 0ms（强一致） |
| CDC + Kafka | 100-500ms（最终一致） |

### Q3: 存储成本增加多少？

大约**1.5-2倍**，因为读取侧冗余了大量数据。

但这是值得的：
- ✅ 查询性能提升10倍+
- ✅ 分库分表可行
- ✅ 扩展性极好

---

## 🎉 总结

**CQRS 架构 = 空间换时间**

- ✅ 查询性能：从 100ms+ → 10ms-
- ✅ 分库分表友好：无需跨表JOIN
- ✅ 可扩展性：读写独立扩展
- ❌ 存储成本：约2倍
- ❌ 实现复杂度：中等

**适用场景**：
- ✅ IM系统
- ✅ 电商订单列表
- ✅ 社交动态Feed
- ✅ 任何"读多写少"的场景

祝你成功！🚀
