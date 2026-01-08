# CQRS 架构文档导航

欢迎使用 Hermet IM 系统的 CQRS 架构！本文档帮助你快速找到所需资料。

---

## 📚 文档目录

### 🚀 新手入门（按顺序阅读）

1. **[CQRS 快速开始](./cqrs_quick_start.md)** ⭐⭐⭐
   - ⏱️ 阅读时间：10分钟
   - 📖 内容：核心概念、架构图、快速示例
   - 👥 适合：所有人

2. **[改造总结](./cqrs_migration_summary.md)** ⭐⭐
   - ⏱️ 阅读时间：5分钟
   - 📖 内容：变更清单、后续步骤、验收标准
   - 👥 适合：项目负责人

3. **[完整实现指南](./cqrs_implementation_guide.md)** ⭐⭐⭐
   - ⏱️ 阅读时间：30分钟
   - 📖 内容：详细代码实现、数据流、最佳实践
   - 👥 适合：开发人员

---

## 🗂️ 按主题查找

### 架构设计

| 文档 | 内容 |
|------|------|
| [cqrs_quick_start.md](./cqrs_quick_start.md) | CQRS核心概念、架构图 |
| [02_channel_init.sql](../scripts/sql/postgresql/02_channel_init.sql) | 完整表结构定义（含详细注释） |

### 代码实现

| 文档 | 内容 |
|------|------|
| [cqrs_implementation_guide.md](./cqrs_implementation_guide.md) | 应用层双写、CDC+Kafka、完整代码示例 |

### 运维部署

| 文档 | 内容 |
|------|------|
| [cqrs_migration_summary.md](./cqrs_migration_summary.md) | 分表策略、数据迁移、监控指标 |

---

## 🎯 快速查询

### 我想了解...

#### "什么是CQRS？为什么要用？"
👉 阅读：[cqrs_quick_start.md](./cqrs_quick_start.md) - 第1章

#### "表结构是怎样的？有哪些字段？"
👉 查看：[02_channel_init.sql](../scripts/sql/postgresql/02_channel_init.sql)
👉 阅读：[cqrs_quick_start.md](./cqrs_quick_start.md) - 表结构概览

#### "如何在代码中实现双写？"
👉 阅读：[cqrs_implementation_guide.md](./cqrs_implementation_guide.md) - 方案1：应用层双写

#### "如何用CDC+Kafka同步数据？"
👉 阅读：[cqrs_implementation_guide.md](./cqrs_implementation_guide.md) - 方案2：CDC+Kafka

#### "如何迁移现有数据？"
👉 阅读：[cqrs_migration_summary.md](./cqrs_migration_summary.md) - 第3步：数据迁移

#### "反向索引是什么？怎么用？"
👉 阅读：[cqrs_quick_start.md](./cqrs_quick_start.md) - 最佳实践
👉 查看：[02_channel_init.sql](../scripts/sql/postgresql/02_channel_init.sql) - 反向索引定义

#### "分表策略是什么？"
👉 阅读：[cqrs_migration_summary.md](./cqrs_migration_summary.md) - 分表策略

---

## 📊 核心表关系图

```
【写入侧】标准化设计
┌──────────────┐
│   channel    │ ← 频道表（群聊/单聊）
└──────┬───────┘
       │ 1:N
       ▼
┌──────────────┐
│channel_member│ ← 频道成员
└──────────────┘

┌──────────────┐
│  friendship  │ ← 好友关系（独立）
└──────────────┘


【读取侧】冗余宽表
┌──────────────────────┐
│user_conversation_view│ ← 会话视图（冗余所有展示字段）
└──────────────────────┘

┌──────────────────────┐
│  user_contact_view   │ ← 联系人视图（冗余好友信息）
└──────────────────────┘


【反向索引】加速同步
┌──────────────────────────┐
│conversation_reverse_index│ ← 谁的会话中有我
└──────────────────────────┘

┌──────────────────────────┐
│  contact_reverse_index   │ ← 谁的联系人中有我
└──────────────────────────┘
```

---

## 🔍 常见操作速查

### 查询会话列表

```sql
SELECT * FROM user_conversation_view_{user_id % 256}
WHERE user_id = ? AND closed_at = 0 AND is_hidden = FALSE
ORDER BY is_pinned DESC, last_message_time DESC;
```

详见：[cqrs_quick_start.md](./cqrs_quick_start.md) - 常见操作示例

### 添加好友（双写）

```go
tx.Begin()
// 1. 写入侧
CreateChannel(...)
CreateChannelMember(...)
CreateFriendship(...)
// 2. 读取侧
CreateConversationView(...)
CreateContactView(...)
// 3. 反向索引
CreateReverseIndex(...)
tx.Commit()
```

详见：[cqrs_implementation_guide.md](./cqrs_implementation_guide.md) - 添加好友场景

### 用户改昵称（反向索引）

```go
// 1. 更新user表
UPDATE user SET nickname = ?, info_ver = info_ver + 1
// 2. 查反向索引
SELECT owner_user_id FROM conversation_reverse_index WHERE peer_user_id = ?
// 3. 批量更新会话视图
UPDATE user_conversation_view SET peer_nickname = ? WHERE ...
```

详见：[cqrs_implementation_guide.md](./cqrs_implementation_guide.md) - 修改资料场景

---

## 🛠️ 开发工具

### SQL 脚本

```bash
# 创建所有表
psql -U postgres -d hermet -f scripts/sql/postgresql/02_channel_init.sql

# 查看表结构
psql -U postgres -d hermet -c "\d+ user_conversation_view"

# 数据迁移
psql -U postgres -d hermet -f scripts/migrate_to_cqrs.sql
```

### 代码生成

```bash
# 根据表结构生成DAO代码
go run tools/gen_dao.go --table=user_conversation_view

# 生成分表配置
go run tools/gen_sharding_config.go
```

---

## 📈 性能对比

| 操作 | 旧方案 | CQRS方案 | 提升 |
|------|--------|---------|------|
| 会话列表查询 | 100-200ms | 5-10ms | **20倍** |
| 通讯录查询 | 150-300ms | 10-20ms | **15倍** |
| 分库分表支持 | ❌ | ✅ | - |

详见：[cqrs_migration_summary.md](./cqrs_migration_summary.md) - 性能提升预期

---

## ⚡ 快速命令

```bash
# 查看文档
cd docs/
ls -la cqrs_*

# 执行SQL
psql -U postgres -d hermet -f scripts/sql/postgresql/02_channel_init.sql

# 运行测试
go test -v ./internal/repo/dao/...

# 检查数据一致性
./scripts/check_cqrs_consistency.sh

# 性能测试
ab -n 10000 -c 100 http://localhost:8080/api/conversations
```

---

## 📞 获取帮助

### 文档内容

| 问题类型 | 查看文档 |
|---------|---------|
| 概念不理解 | [cqrs_quick_start.md](./cqrs_quick_start.md) |
| 不知道怎么实现 | [cqrs_implementation_guide.md](./cqrs_implementation_guide.md) |
| 部署遇到问题 | [cqrs_migration_summary.md](./cqrs_migration_summary.md) |
| SQL语法问题 | [02_channel_init.sql](../scripts/sql/postgresql/02_channel_init.sql) |

### 其他资源

- 项目 Issue：https://github.com/your-repo/hermet/issues
- 技术文章：参考 Martin Fowler 的 CQRS Pattern
- 社区讨论：加入项目 Discord/Slack

---

## ✅ 验收清单

改造完成后，确认以下项目：

**SQL层面：**
- [ ] 所有表创建成功
- [ ] 索引创建正确
- [ ] 分表配置符合建议

**代码层面：**
- [ ] DAO层实现完整
- [ ] 双写逻辑正确
- [ ] 反向索引维护正确
- [ ] 单元测试通过

**性能层面：**
- [ ] 会话列表查询 < 10ms
- [ ] 通讯录查询 < 20ms
- [ ] 数据一致性 > 99.9%

**运维层面：**
- [ ] 监控指标配置完成
- [ ] 告警规则设置完成
- [ ] 数据备份策略制定

详见：[cqrs_migration_summary.md](./cqrs_migration_summary.md) - 验收标准

---

## 🎓 学习路径

### 初级（1天）
1. 阅读 [cqrs_quick_start.md](./cqrs_quick_start.md)
2. 查看 [02_channel_init.sql](../scripts/sql/postgresql/02_channel_init.sql)
3. 理解核心概念和表结构

### 中级（3天）
1. 阅读 [cqrs_implementation_guide.md](./cqrs_implementation_guide.md)
2. 实现简单的双写逻辑
3. 跑通添加好友、查询会话等场景

### 高级（1周）
1. 实现完整的双写逻辑
2. 配置CDC+Kafka
3. 进行性能测试和优化

---

## 📝 更新记录

| 日期 | 版本 | 内容 |
|------|------|------|
| 2026-01-08 | v1.0 | 初始版本，完整CQRS架构 |

---

## 🙏 致谢

感谢以下资源的启发：
- Martin Fowler - CQRS Pattern
- Microsoft - CQRS Journey
- Debezium - CDC Platform

---

**祝你改造顺利！如有问题，随时查阅文档。** 🚀

---

<p align="center">
  Made with ❤️ by Hermet Team
</p>
