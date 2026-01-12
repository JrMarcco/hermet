-- ============================================================================
-- CQRS 架构设计说明
-- ============================================================================
-- 本文件采用 CQRS ( Command Query Responsibility Segregation ) 架构
--
-- 【 写入侧 Write Side 】标准化设计，保证数据一致性
--   - biz_user: 用户表
--   - channel: 频道表
--   - channel_member: 频道成员表
--   - channel_read_record: 已读记录表
--   - user_contact: 用户联系人表
--
-- 【 读取侧 Read Side 】宽表设计，冗余数据，优化查询性能
--   - user_conversation_view: 用户会话视图表 ( 按 user_id 分表 )
--   - user_contact_view: 用户联系人视图表 ( 按 user_id 分表 )
--
-- 【 反向索引 Reverse Index 】加速数据同步
--   - conversation_reverse_index: 会话反向索引 ( 谁的会话中有某个用户 )
--   - contact_reverse_index: 联系人反向索引 ( 谁的联系人中有某个用户 )
--
-- 【 数据同步 】
--   - 方式1: 应用层双写 ( 写入时同时更新读取侧 )
--   - 方式2: CDC + Kafka ( **推荐** 通过 Debezium 捕获变更 )
-- ============================================================================



-- ============================================================================
-- CQRS 数据流说明
-- ============================================================================

/*

【 数据流 1: 添加好友 】

    1. 写入侧:
    INSERT INTO channel ( 单聊 channel )
    INSERT INTO channel_member ( 两个成员记录 )
    INSERT INTO user_contact ( 双向联系人关系 )

    2. 读取侧 ( 应用层双写 或 CDC 同步 ):
    INSERT INTO user_conversation_view ( A 的会话视图 )
    INSERT INTO user_conversation_view ( B 的会话视图 )
    INSERT INTO user_contact_view ( A 的联系人视图 )
    INSERT INTO user_contact_view ( B 的联系人视图 )

    3. 反向索引:
    INSERT INTO conversation_reverse_index ( B, A, channel_id )  -- B 在 A 的会话中
    INSERT INTO conversation_reverse_index ( A, B, channel_id )  -- A 在 B 的会话中
    INSERT INTO contact_reverse_index ( B, A )  -- B 在 A 的联系人中
    INSERT INTO contact_reverse_index ( A, B )  -- A 在 B 的联系人中


【 数据流 2: 发送消息 】

    1. 写入消息表 ( message 表 - MongoDB )

    2. 更新会话视图 ( 通过 Kafka 异步更新 )
    查询频道所有成员: SELECT user_id FROM channel_member WHERE channel_id = ?
    批量更新会话视图:
    UPDATE user_conversation_view SET
        last_message_id = ?,
        last_message_content = ?,
        last_message_sender_id = ?,
        last_message_sender_name = ?,
        last_message_time = ?,
        unread_count = unread_count + 1
    WHERE user_id IN ( 成员列表 ) AND channel_id = ?


【 数据流 3: 用户修改资料 ( 昵称 / 头像 ) 】

    1. 写入侧:
    UPDATE user SET nickname = ?, avatar = ?, profile_ver = profile_ver + 1
    WHERE id = ?

    2. 通过反向索引找到需要更新的记录:
        a) 更新会话视图:
        SELECT owner_user_id, channel_id
        FROM conversation_reverse_index
        WHERE peer_user_id = ?

        对每条记录:
        UPDATE user_conversation_view_{shard} SET
            peer_nickname = ?,
            peer_avatar = ?,
            conversation_name = COALESCE(remark_name, ?),  -- 优先使用备注名
            conversation_avatar = ?,
            conversation_info_ver = conversation_info_ver + 1
        WHERE user_id = ? AND channel_id = ?

        b) 更新联系人视图:
        SELECT owner_user_id
        FROM contact_reverse_index
        WHERE contact_user_id = ?

        对每条记录:
        UPDATE user_contact_view_{shard} SET
            contact_nickname = ?,
            contact_avatar = ?,
            contact_info_ver = contact_info_ver + 1
        WHERE user_id = ? AND contact_id = ?


【 数据流 4: 群名称 / 头像修改 】

    1. 写入侧:
    UPDATE channel SET
        channel_name = ?,
        channel_avatar = ?,
        channel_info_ver = channel_info_ver + 1
    WHERE id = ?

    2. 更新所有成员的会话视图:
    查询群成员: SELECT user_id FROM channel_member WHERE channel_id = ?

    批量更新:
    UPDATE user_conversation_view_{shard} SET
        conversation_name = ?,
        conversation_avatar = ?,
        conversation_info_ver = ?
    WHERE user_id IN ( 成员列表 ) AND channel_id = ?


【 数据流 5: 软删除用户 】

    -- 注销用户账号 ( 软删除 )
    UPDATE biz_user
    SET user_status = 'deleted',
        deleted_at = ?,
        updated_at = ?
    WHERE id = ?;

    注意: 软删除后，需要同步 ( 读取侧 ):
        1. 删除 user_contact 关系
        2. 从好友的 user_contact_view 中移除
        3. 会话视图中标记为已删除用户 ( user_conversation_view )


【 查询示例 1: 获取会话列表 】

    -- 单表查询，性能极好
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
    FROM user_conversation_view_{shard}
    WHERE user_id = ?
        AND closed_at = 0
        AND is_hidden = FALSE
    ORDER BY is_pinned DESC, last_message_time DESC
    LIMIT 50;


【 查询示例 2: 获取通讯录列表 】

    -- 单表查询，性能极好
    SELECT
        contact_id,
        contact_nickname,
        contact_avatar,
        remark_name,
        group_name,
        is_starred
    FROM user_contact_view_{shard}
    WHERE user_id = ?
        AND deleted_at = 0
    ORDER BY is_starred DESC, contact_nickname
    LIMIT 1000;


【 查询示例 3: 搜索用户 】

    -- 按昵称搜索用户 ( 模糊匹配 )
    SELECT id, nickname, avatar, gender, tagline
    FROM biz_user
    WHERE nickname LIKE '%关键词%'
        AND deleted_at = 0
        AND user_status = 'active'
    ORDER BY info_ver DESC  -- 最近活跃的用户优先
    LIMIT 20;

`
【 版本号机制 】
    info_ver 字段的作用 ( 用于同步检测 )
    1. 检测数据是否需要同步
    if (view.conversation_info_ver < user.info_ver) {
        // 需要同步更新
    }

    2. 避免重复更新
    UPDATE user_conversation_view_{shard}
    SET peer_nickname = ?, conversation_info_ver = ?
    WHERE peer_user_id = ? AND conversation_info_ver < ?;

    3. 客户端缓存失效
    客户端定期检查版本号，如果不一致则刷新数据
*/
