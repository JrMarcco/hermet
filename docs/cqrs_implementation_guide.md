# CQRS 架构实现指南

本文档说明如何在应用层实现 CQRS（读写分离）架构的数据同步机制。

## 目录

- [架构概览](#架构概览)
- [实现方式对比](#实现方式对比)
- [方案1: 应用层双写](#方案1-应用层双写)
- [方案2: CDC + Kafka](#方案2-cdc--kafka)
- [常见业务场景实现](#常见业务场景实现)
- [性能优化建议](#性能优化建议)

---

## 架构概览

```
┌─────────────────────────────────────────────────────────────┐
│                        应用层                                │
└───────┬─────────────────────────────────────────────┬───────┘
        │                                             │
        ▼ 写操作                                      ▼ 读操作
┌──────────────────┐                        ┌──────────────────┐
│   写入侧 (Write)  │                        │  读取侧 (Read)    │
├──────────────────┤                        ├──────────────────┤
│ - channel        │                        │ - conversation_  │
│ - channel_member │    ──同步机制──>       │   view           │
│ - friendship     │                        │ - contact_view   │
│                  │                        │                  │
└──────────────────┘                        └──────────────────┘
        │                                             ▲
        │                                             │
        └─────────> Kafka/CDC ──────────────────────┘
```

**核心原则**：
- 所有写操作写入【写入侧】
- 所有读操作读取【读取侧】
- 通过同步机制保证数据一致性

---

## 实现方式对比

| 方式 | 实现复杂度 | 一致性 | 性能 | 可靠性 | 推荐场景 |
|------|-----------|--------|------|--------|----------|
| **应用层双写** | ⭐⭐ 中 | 强一致 | 高 | 中 | 中小型系统，快速迭代 |
| **CDC + Kafka** | ⭐⭐⭐ 高 | 最终一致 | 极高 | 高 | 大型系统，高并发 |

---

## 方案1: 应用层双写

### 优点
- ✅ 实现简单，无需额外组件
- ✅ 强一致性（事务保证）
- ✅ 调试方便

### 缺点
- ❌ 业务代码耦合
- ❌ 双写失败需要补偿机制
- ❌ 性能略低（同步写入）

### 实现示例

#### 1. 添加好友场景

```go
package service

import (
    "context"
    "database/sql"
    "time"
)

// AddFriend 添加好友（应用层双写）
func (s *UserService) AddFriend(ctx context.Context, userA, userB int64) error {
    tx, err := s.db.BeginTx(ctx, nil)
    if err != nil {
        return err
    }
    defer tx.Rollback()
    
    now := time.Now().UnixMilli()
    
    // ========================================
    // 【写入侧】标准化写入
    // ========================================
    
    // 1. 创建单聊频道
    channelID := s.idgen.GenerateChannelID()
    if err := s.createChannel(tx, channelID, now); err != nil {
        return err
    }
    
    // 2. 添加频道成员（双向）
    if err := s.addChannelMember(tx, channelID, userA, now); err != nil {
        return err
    }
    if err := s.addChannelMember(tx, channelID, userB, now); err != nil {
        return err
    }
    
    // 3. 创建好友关系（双向）
    if err := s.createFriendship(tx, userA, userB, now); err != nil {
        return err
    }
    if err := s.createFriendship(tx, userB, userA, now); err != nil {
        return err
    }
    
    // ========================================
    // 【读取侧】冗余写入
    // ========================================
    
    // 4. 获取用户信息（用于冗余）
    userAInfo, err := s.getUserInfo(tx, userA)
    if err != nil {
        return err
    }
    userBInfo, err := s.getUserInfo(tx, userB)
    if err != nil {
        return err
    }
    
    // 5. 创建会话视图（双向）
    if err := s.createConversationView(tx, userA, channelID, userB, userBInfo, now); err != nil {
        return err
    }
    if err := s.createConversationView(tx, userB, channelID, userA, userAInfo, now); err != nil {
        return err
    }
    
    // 6. 创建联系人视图（双向）
    if err := s.createContactView(tx, userA, userB, userBInfo, now); err != nil {
        return err
    }
    if err := s.createContactView(tx, userB, userA, userAInfo, now); err != nil {
        return err
    }
    
    // ========================================
    // 【反向索引】加速同步
    // ========================================
    
    // 7. 创建反向索引
    if err := s.createReverseIndex(tx, userB, userA, channelID, now); err != nil {
        return err
    }
    if err := s.createReverseIndex(tx, userA, userB, channelID, now); err != nil {
        return err
    }
    
    return tx.Commit()
}

// 辅助方法
func (s *UserService) createChannel(tx *sql.Tx, channelID, now int64) error {
    _, err := tx.Exec(`
        INSERT INTO channel (id, channel_type, channel_status, channel_info_ver, 
                           channel_member_count, creator_id, created_at, updated_at)
        VALUES (?, 'single', 'active', 1, 2, 0, ?, ?)
    `, channelID, now, now)
    return err
}

func (s *UserService) createConversationView(tx *sql.Tx, ownerID, channelID, peerID int64, 
                                            peerInfo *UserInfo, now int64) error {
    shardKey := ownerID % 256
    _, err := tx.Exec(`
        INSERT INTO user_conversation_view_%d 
        (id, user_id, channel_id, conversation_type, conversation_name, conversation_avatar,
         conversation_info_ver, peer_user_id, peer_nickname, peer_avatar, opened_at, created_at, updated_at)
        VALUES (?, ?, ?, 'single', ?, ?, 1, ?, ?, ?, ?, ?, ?)
    `, shardKey, s.idgen.GenerateID(), ownerID, channelID, peerInfo.Nickname, 
       peerInfo.Avatar, peerID, peerInfo.Nickname, peerInfo.Avatar, now, now, now)
    return err
}

func (s *UserService) createReverseIndex(tx *sql.Tx, peerID, ownerID, channelID, now int64) error {
    shardKey := peerID % 256
    _, err := tx.Exec(`
        INSERT INTO conversation_reverse_index_%d 
        (peer_user_id, owner_user_id, channel_id, created_at)
        VALUES (?, ?, ?, ?)
    `, shardKey, peerID, ownerID, channelID, now)
    return err
}
```

#### 2. 发送消息场景

```go
// SendMessage 发送消息
func (s *MessageService) SendMessage(ctx context.Context, senderID, channelID int64, 
                                     content string) error {
    tx, err := s.db.BeginTx(ctx, nil)
    if err != nil {
        return err
    }
    defer tx.Rollback()
    
    now := time.Now().UnixMilli()
    
    // 1. 保存消息（写入侧）
    messageID := s.idgen.GenerateMessageID()
    if err := s.saveMessage(tx, messageID, channelID, senderID, content, now); err != nil {
        return err
    }
    
    // 2. 查询频道成员
    members, err := s.getChannelMembers(tx, channelID)
    if err != nil {
        return err
    }
    
    // 3. 获取发送者信息
    senderInfo, err := s.getUserInfo(tx, senderID)
    if err != nil {
        return err
    }
    
    // 4. 更新所有成员的会话视图（读取侧）
    for _, member := range members {
        shardKey := member.UserID % 256
        unreadIncr := 0
        if member.UserID != senderID {
            unreadIncr = 1 // 非发送者，未读+1
        }
        
        _, err := tx.Exec(`
            UPDATE user_conversation_view_%d
            SET last_message_id = ?,
                last_message_type = 'text',
                last_message_content = ?,
                last_message_sender_id = ?,
                last_message_sender_name = ?,
                last_message_time = ?,
                unread_count = unread_count + ?,
                updated_at = ?
            WHERE user_id = ? AND channel_id = ?
        `, shardKey, messageID, s.truncateContent(content), senderID, 
           senderInfo.Nickname, now, unreadIncr, now, member.UserID, channelID)
        
        if err != nil {
            return err
        }
    }
    
    return tx.Commit()
}
```

#### 3. 用户修改资料场景

```go
// UpdateUserProfile 修改用户资料（昵称/头像）
func (s *UserService) UpdateUserProfile(ctx context.Context, userID int64, 
                                       nickname, avatar string) error {
    tx, err := s.db.BeginTx(ctx, nil)
    if err != nil {
        return err
    }
    defer tx.Rollback()
    
    now := time.Now().UnixMilli()
    
    // 1. 更新用户表（写入侧）
    newVersion := 0
    err = tx.QueryRow(`
        UPDATE user 
        SET nickname = ?, avatar = ?, profile_ver = profile_ver + 1, updated_at = ?
        WHERE id = ?
        RETURNING profile_ver
    `, nickname, avatar, now, userID).Scan(&newVersion)
    if err != nil {
        return err
    }
    
    // ========================================
    // 2. 通过反向索引更新会话视图
    // ========================================
    shardKey := userID % 256
    rows, err := tx.Query(`
        SELECT owner_user_id, channel_id
        FROM conversation_reverse_index_%d
        WHERE peer_user_id = ?
    `, shardKey, userID)
    if err != nil {
        return err
    }
    defer rows.Close()
    
    type ConvUpdate struct {
        OwnerID   int64
        ChannelID int64
    }
    var updates []ConvUpdate
    for rows.Next() {
        var u ConvUpdate
        if err := rows.Scan(&u.OwnerID, &u.ChannelID); err != nil {
            return err
        }
        updates = append(updates, u)
    }
    
    // 批量更新会话视图
    for _, u := range updates {
        ownerShardKey := u.OwnerID % 256
        _, err := tx.Exec(`
            UPDATE user_conversation_view_%d
            SET peer_nickname = ?,
                peer_avatar = ?,
                conversation_name = COALESCE(NULLIF(remark_name, ''), ?),  -- 优先备注名
                conversation_avatar = ?,
                conversation_info_ver = ?,
                updated_at = ?
            WHERE user_id = ? AND channel_id = ?
        `, ownerShardKey, nickname, avatar, nickname, avatar, newVersion, 
           now, u.OwnerID, u.ChannelID)
        if err != nil {
            return err
        }
    }
    
    // ========================================
    // 3. 通过反向索引更新联系人视图
    // ========================================
    rows2, err := tx.Query(`
        SELECT owner_user_id
        FROM contact_reverse_index_%d
        WHERE contact_user_id = ?
    `, shardKey, userID)
    if err != nil {
        return err
    }
    defer rows2.Close()
    
    var ownerIDs []int64
    for rows2.Next() {
        var ownerID int64
        if err := rows2.Scan(&ownerID); err != nil {
            return err
        }
        ownerIDs = append(ownerIDs, ownerID)
    }
    
    // 批量更新联系人视图
    for _, ownerID := range ownerIDs {
        ownerShardKey := ownerID % 256
        _, err := tx.Exec(`
            UPDATE user_contact_view_%d
            SET contact_nickname = ?,
                contact_avatar = ?,
                contact_info_ver = ?,
                updated_at = ?
            WHERE user_id = ? AND contact_id = ?
        `, ownerShardKey, nickname, avatar, newVersion, now, ownerID, userID)
        if err != nil {
            return err
        }
    }
    
    return tx.Commit()
}
```

---

## 方案2: CDC + Kafka

### 优点
- ✅ 业务代码解耦
- ✅ 异步处理，性能极高
- ✅ 可扩展性好
- ✅ 事件溯源，便于审计

### 缺点
- ❌ 实现复杂度高
- ❌ 最终一致性（有延迟）
- ❌ 需要额外组件（Debezium/Kafka）

### 架构图

```
┌──────────────┐
│ PostgreSQL   │
│  (写入侧)    │
└──────┬───────┘
       │
       │ Binlog/WAL
       ▼
┌──────────────┐      ┌──────────────┐
│  Debezium    │─────>│    Kafka     │
│  Connector   │      │   Topics     │
└──────────────┘      └──────┬───────┘
                             │
              ┌──────────────┼──────────────┐
              ▼              ▼              ▼
       ┌───────────┐  ┌───────────┐  ┌───────────┐
       │Consumer 1 │  │Consumer 2 │  │Consumer 3 │
       │更新会话表  │  │更新联系人  │  │推送通知   │
       └───────────┘  └───────────┘  └───────────┘
              │              │
              ▼              ▼
       ┌─────────────────────────┐
       │  PostgreSQL (读取侧)     │
       │  - conversation_view    │
       │  - contact_view         │
       └─────────────────────────┘
```

### 实现步骤

#### 1. Debezium 配置

```json
{
  "name": "hermet-cdc-connector",
  "config": {
    "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
    "database.hostname": "localhost",
    "database.port": "5432",
    "database.user": "postgres",
    "database.password": "password",
    "database.dbname": "hermet",
    "table.include.list": "public.user,public.channel,public.friendship",
    "topic.prefix": "hermet",
    "plugin.name": "pgoutput",
    "slot.name": "hermet_slot",
    "publication.name": "hermet_publication",
    "transforms": "route",
    "transforms.route.type": "org.apache.kafka.connect.transforms.RegexRouter",
    "transforms.route.regex": "hermet\\.public\\.(.*)",
    "transforms.route.replacement": "$1.changed"
  }
}
```

#### 2. Kafka 消费者

```go
package consumer

import (
    "context"
    "encoding/json"
    "github.com/segmentio/kafka-go"
)

type UserChangedEvent struct {
    Op        string `json:"op"` // c=create, u=update, d=delete
    After     *User  `json:"after"`
    Before    *User  `json:"before"`
    Timestamp int64  `json:"ts_ms"`
}

type User struct {
    ID         int64  `json:"id"`
    Nickname   string `json:"nickname"`
    Avatar     string `json:"avatar"`
    ProfileVer int    `json:"profile_ver"`
}

// ConsumeUserChanged 消费用户变更事件
func (c *Consumer) ConsumeUserChanged(ctx context.Context) error {
    reader := kafka.NewReader(kafka.ReaderConfig{
        Brokers:  []string{"localhost:9092"},
        Topic:    "user.changed",
        GroupID:  "conversation-view-updater",
        MinBytes: 10e3, // 10KB
        MaxBytes: 10e6, // 10MB
    })
    defer reader.Close()
    
    for {
        msg, err := reader.ReadMessage(ctx)
        if err != nil {
            return err
        }
        
        var event UserChangedEvent
        if err := json.Unmarshal(msg.Value, &event); err != nil {
            log.Errorf("unmarshal error: %v", err)
            continue
        }
        
        // 只处理更新事件
        if event.Op != "u" || event.After == nil {
            continue
        }
        
        // 更新会话视图和联系人视图
        if err := c.updateViews(ctx, event.After); err != nil {
            log.Errorf("update views error: %v", err)
            // 重试机制
            continue
        }
    }
}

func (c *Consumer) updateViews(ctx context.Context, user *User) error {
    // 1. 查询反向索引
    conversations, err := c.getConversationsByPeerUserID(user.ID)
    if err != nil {
        return err
    }
    
    // 2. 批量更新会话视图
    for _, conv := range conversations {
        shardKey := conv.OwnerUserID % 256
        _, err := c.db.ExecContext(ctx, `
            UPDATE user_conversation_view_%d
            SET peer_nickname = $1,
                peer_avatar = $2,
                conversation_name = COALESCE(NULLIF(remark_name, ''), $1),
                conversation_avatar = $3,
                conversation_info_ver = $4,
                updated_at = $5
            WHERE user_id = $6 AND channel_id = $7
        `, shardKey, user.Nickname, user.Avatar, user.Avatar, 
           user.ProfileVer, time.Now().UnixMilli(), 
           conv.OwnerUserID, conv.ChannelID)
        if err != nil {
            return err
        }
    }
    
    // 3. 更新联系人视图（类似逻辑）
    // ...
    
    return nil
}
```

---

## 常见业务场景实现

### 1. 查询会话列表

```go
// GetConversationList 获取会话列表（直接查读取侧）
func (s *ConversationService) GetConversationList(ctx context.Context, userID int64, 
                                                  limit int) ([]*Conversation, error) {
    shardKey := userID % 256
    
    rows, err := s.db.QueryContext(ctx, `
        SELECT 
            channel_id,
            conversation_type,
            conversation_name,
            conversation_avatar,
            last_message_content,
            last_message_sender_name,
            last_message_time,
            unread_count,
            is_pinned,
            is_muted
        FROM user_conversation_view_%d
        WHERE user_id = $1
            AND closed_at = 0
            AND is_hidden = FALSE
        ORDER BY is_pinned DESC, last_message_time DESC
        LIMIT $2
    `, shardKey, userID, limit)
    
    if err != nil {
        return nil, err
    }
    defer rows.Close()
    
    var conversations []*Conversation
    for rows.Next() {
        var c Conversation
        err := rows.Scan(
            &c.ChannelID,
            &c.Type,
            &c.Name,
            &c.Avatar,
            &c.LastMessage,
            &c.LastSenderName,
            &c.LastMessageTime,
            &c.UnreadCount,
            &c.IsPinned,
            &c.IsMuted,
        )
        if err != nil {
            return nil, err
        }
        conversations = append(conversations, &c)
    }
    
    return conversations, nil
}
```

### 2. 查询通讯录列表

```go
// GetContactList 获取通讯录列表（直接查读取侧）
func (s *ContactService) GetContactList(ctx context.Context, userID int64) ([]*Contact, error) {
    shardKey := userID % 256
    
    rows, err := s.db.QueryContext(ctx, `
        SELECT 
            contact_id,
            contact_nickname,
            contact_avatar,
            remark_name,
            group_name,
            is_starred
        FROM user_contact_view_%d
        WHERE user_id = $1
            AND deleted_at = 0
        ORDER BY is_starred DESC, contact_nickname
    `, shardKey, userID)
    
    if err != nil {
        return nil, err
    }
    defer rows.Close()
    
    var contacts []*Contact
    for rows.Next() {
        var c Contact
        err := rows.Scan(
            &c.ContactID,
            &c.Nickname,
            &c.Avatar,
            &c.RemarkName,
            &c.GroupName,
            &c.IsStarred,
        )
        if err != nil {
            return nil, err
        }
        contacts = append(contacts, &c)
    }
    
    return contacts, nil
}
```

---

## 性能优化建议

### 1. 批量更新优化

```go
// 批量更新会话视图（使用UNNEST）
func (s *ConversationService) BatchUpdateConversations(ctx context.Context, 
                                                      updates []ConversationUpdate) error {
    if len(updates) == 0 {
        return nil
    }
    
    // 按分片分组
    shardGroups := make(map[int][]ConversationUpdate)
    for _, u := range updates {
        shardKey := u.UserID % 256
        shardGroups[shardKey] = append(shardGroups[shardKey], u)
    }
    
    // 每个分片批量更新
    for shardKey, group := range shardGroups {
        userIDs := make([]int64, len(group))
        channelIDs := make([]int64, len(group))
        contents := make([]string, len(group))
        
        for i, u := range group {
            userIDs[i] = u.UserID
            channelIDs[i] = u.ChannelID
            contents[i] = u.Content
        }
        
        _, err := s.db.ExecContext(ctx, `
            UPDATE user_conversation_view_%d AS v
            SET last_message_content = u.content,
                updated_at = $1
            FROM UNNEST($2::bigint[], $3::bigint[], $4::text[]) 
                AS u(user_id, channel_id, content)
            WHERE v.user_id = u.user_id AND v.channel_id = u.channel_id
        `, shardKey, time.Now().UnixMilli(), 
           pq.Array(userIDs), pq.Array(channelIDs), pq.Array(contents))
        
        if err != nil {
            return err
        }
    }
    
    return nil
}
```

### 2. 缓存层优化

```go
// 添加Redis缓存层
func (s *ConversationService) GetConversationListWithCache(ctx context.Context, 
                                                          userID int64) ([]*Conversation, error) {
    // 1. 先查缓存
    cacheKey := fmt.Sprintf("conversation_list:%d", userID)
    cached, err := s.redis.Get(ctx, cacheKey).Result()
    if err == nil {
        var conversations []*Conversation
        if err := json.Unmarshal([]byte(cached), &conversations); err == nil {
            return conversations, nil
        }
    }
    
    // 2. 缓存未命中，查数据库
    conversations, err := s.GetConversationList(ctx, userID, 50)
    if err != nil {
        return nil, err
    }
    
    // 3. 写入缓存
    data, _ := json.Marshal(conversations)
    s.redis.Set(ctx, cacheKey, data, 5*time.Minute)
    
    return conversations, nil
}
```

### 3. 异步更新优化

```go
// 发送消息后，异步更新会话视图
func (s *MessageService) SendMessageAsync(ctx context.Context, senderID, channelID int64, 
                                         content string) error {
    // 1. 保存消息（同步）
    messageID, err := s.saveMessage(ctx, channelID, senderID, content)
    if err != nil {
        return err
    }
    
    // 2. 异步更新会话视图
    go func() {
        ctx := context.Background()
        if err := s.updateConversationViews(ctx, messageID, channelID, senderID, content); err != nil {
            log.Errorf("async update conversation views error: %v", err)
            // 失败重试机制
        }
    }()
    
    return nil
}
```

---

## 总结

### 选择建议

- **中小型系统（< 100万用户）**：推荐**应用层双写**
  - 实现简单，快速上线
  - 强一致性，用户体验好
  - 维护成本低

- **大型系统（> 100万用户）**：推荐**CDC + Kafka**
  - 性能极高，支持海量并发
  - 解耦设计，易于扩展
  - 事件驱动，灵活性强

### 关键指标监控

1. **同步延迟**：写入侧更新 -> 读取侧可见的时间
2. **数据一致性率**：读取侧与写入侧的一致性比例
3. **更新失败率**：反向索引更新失败的比例
4. **查询性能**：P99延迟应 < 50ms

### 故障恢复

如果读取侧数据损坏：
1. 从写入侧全量重建读取侧
2. 通过反向索引定向修复
3. 使用Kafka Offset回溯重放事件
