-- ============================================================================
-- 写入侧 ( Write Side ) - 标准化设计
-- ============================================================================

-- 频道类型枚举 ( single=单聊 / group=群聊 )
DROP TYPE IF EXISTS channel_type_enum CASCADE;
CREATE TYPE channel_type_enum AS ENUM ('single', 'group');

-- 频道状态枚举 ( creating=创建中 / active=活跃 / failed=失败 / archived=已归档 )
DROP TYPE IF EXISTS channel_status_enum CASCADE;
CREATE TYPE channel_status_enum AS ENUM ('creating', 'active', 'failed','archived');

-- 频道表 ( 核心表，保持标准化 )
DROP TABLE IF EXISTS channel;
CREATE TABLE channel (
    id BIGINT PRIMARY KEY,

    -- 频道基础信息
    channel_name VARCHAR(128) NOT NULL DEFAULT '',
    channel_type channel_type_enum NOT NULL,
    channel_avatar VARCHAR(256) NOT NULL DEFAULT '',
    channel_status channel_status_enum NOT NULL,
    channel_info_ver INT NOT NULL DEFAULT 1,
    channel_member_count INT NOT NULL DEFAULT 0,

    -- 最后消息时间 ( 用于判断活跃度 )
    last_message_at BIGINT NOT NULL DEFAULT 0,

    creator_id BIGINT NOT NULL,

    created_at BIGINT NOT NULL,
    updated_at BIGINT NOT NULL
);

COMMENT ON TABLE channel IS '【写入侧】频道表（聊天会话表）';
COMMENT ON COLUMN channel.id IS '频道 ID';
COMMENT ON COLUMN channel.channel_name IS '频道名称 ( 单聊为空 )';
COMMENT ON COLUMN channel.channel_type IS '频道类型 ( single=单聊 / group=群聊 )';
COMMENT ON COLUMN channel.channel_avatar IS '频道头像';
COMMENT ON COLUMN channel.channel_status IS '频道状态 ( creating=创建中 / active=活跃 / failed=失败 / archived=已归档 )';
COMMENT ON COLUMN channel.channel_info_ver IS '【 CQRS 关键字段 】频道信息版本号 ( 用于同步检测 )';
COMMENT ON COLUMN channel.channel_member_count IS '频道成员数量';
COMMENT ON COLUMN channel.last_message_at IS '最后消息时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN channel.creator_id IS '创建者 ID';
COMMENT ON COLUMN channel.created_at IS '创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN channel.updated_at IS '更新时间戳 ( Unix 毫秒值 )';

-- 索引
CREATE INDEX idx_channel_type ON channel(channel_type);
CREATE INDEX idx_channel_creator ON channel(creator_id);
CREATE INDEX idx_channel_status ON channel(channel_status);



-- 频道成员角色枚举
DROP TYPE IF EXISTS channel_member_role_enum CASCADE;
CREATE TYPE channel_member_role_enum AS ENUM ('owner', 'admin', 'member');

-- 频道成员表
DROP TABLE IF EXISTS channel_member;
CREATE TABLE channel_member (
    id BIGINT PRIMARY KEY,
    channel_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,

    -- 成员角色
    role channel_member_role_enum NOT NULL DEFAULT 'member',

    -- 成员昵称 ( 群昵称 )
    nickname VARCHAR(64) NOT NULL DEFAULT '',

    -- 加入 / 退出时间
    joined_at BIGINT NOT NULL,
    left_at BIGINT NOT NULL DEFAULT 0,

    created_at BIGINT NOT NULL,
    updated_at BIGINT NOT NULL,

    -- 唯一约束：同一用户在同一频道中只能有一条记录
    CONSTRAINT uk_channel_member_channel_user UNIQUE(channel_id, user_id)
);

COMMENT ON TABLE channel_member IS '【 写入侧 】频道成员表';
COMMENT ON COLUMN channel_member.id IS '主键 ID';
COMMENT ON COLUMN channel_member.channel_id IS '频道 ID';
COMMENT ON COLUMN channel_member.user_id IS '用户 ID';
COMMENT ON COLUMN channel_member.role IS '成员角色 ( owner=群主 / admin=管理员 / member=普通成员 )';
COMMENT ON COLUMN channel_member.nickname IS '群昵称（用户在该群的昵称）';
COMMENT ON COLUMN channel_member.joined_at IS '加入时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN channel_member.left_at IS '退出时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN channel_member.created_at IS '创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN channel_member.updated_at IS '更新时间戳 ( Unix 毫秒值 )';

-- 索引
CREATE INDEX idx_channel_member_channel ON channel_member(channel_id);
CREATE INDEX idx_channel_member_user ON channel_member(user_id);
CREATE INDEX idx_channel_member_active ON channel_member(channel_id, left_at) WHERE left_at = 0;



-- 频道消息已读记录表
DROP TABLE IF EXISTS channel_read_record;
CREATE TABLE channel_read_record (
    id BIGINT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    channel_id BIGINT NOT NULL,
    last_read_message_id BIGINT NOT NULL DEFAULT 0,

    created_at BIGINT NOT NULL,
    updated_at BIGINT NOT NULL,

    -- 唯一约束：一个用户在一个频道中只有一条已读记录
    CONSTRAINT uk_read_record_user_channel UNIQUE(user_id, channel_id)
);

COMMENT ON TABLE channel_read_record IS '【 写入侧 】频道消息已读记录表';
COMMENT ON COLUMN channel_read_record.id IS '主键 ID';
COMMENT ON COLUMN channel_read_record.user_id IS '用户 ID';
COMMENT ON COLUMN channel_read_record.channel_id IS '频道 ID';
COMMENT ON COLUMN channel_read_record.last_read_message_id IS '最后已读消息 ID';
COMMENT ON COLUMN channel_read_record.created_at IS '创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN channel_read_record.updated_at IS '更新时间戳 ( Unix 毫秒值 )';

-- 索引
CREATE INDEX idx_channel_read_user_channel ON channel_read_record(user_id, channel_id);



-- 添加来源枚举
DROP TYPE IF EXISTS friendship_source_enum CASCADE;
CREATE TYPE friendship_source_enum AS ENUM ('search', 'qrcode', 'group');

-- 好友关系表
DROP TABLE IF EXISTS friendship;
CREATE TABLE friendship (
    id BIGINT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    friend_id BIGINT NOT NULL,

    -- 好友备注名
    remark_name VARCHAR(64) NOT NULL DEFAULT '',

    -- 添加来源 ( search=搜索添加 / qrcode=扫码添加 / group=群聊添加 )
    source friendship_source_enum NOT NULL DEFAULT 'search',

    -- 好友标签
    tags VARCHAR(128)[] DEFAULT '{}',

    -- 好友分组
    group_name VARCHAR(32) NOT NULL DEFAULT 'friends',

    -- 状态标记
    is_starred BOOLEAN NOT NULL DEFAULT FALSE,  -- 星标好友
    is_blocked BOOLEAN NOT NULL DEFAULT FALSE,  -- 黑名单

    added_at BIGINT NOT NULL,
    deleted_at BIGINT NOT NULL DEFAULT 0,

    created_at BIGINT NOT NULL,
    updated_at BIGINT NOT NULL,

    -- 唯一约束
    CONSTRAINT uk_friendship UNIQUE(user_id, friend_id)
);

COMMENT ON TABLE friendship IS '【 写入侧 】好友关系表';
COMMENT ON COLUMN friendship.id IS '主键 ID';
COMMENT ON COLUMN friendship.user_id IS '用户 ID';
COMMENT ON COLUMN friendship.friend_id IS '好友 ID';
COMMENT ON COLUMN friendship.remark_name IS '好友备注名';
COMMENT ON COLUMN friendship.source IS '添加来源 ( search=搜索 / qrcode=扫码 / group=群聊 )';
COMMENT ON COLUMN friendship.tags IS '好友标签数组';
COMMENT ON COLUMN friendship.group_name IS '好友分组';
COMMENT ON COLUMN friendship.is_starred IS '是否星标好友';
COMMENT ON COLUMN friendship.is_blocked IS '是否拉黑';
COMMENT ON COLUMN friendship.added_at IS '添加时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN friendship.deleted_at IS '删除时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN friendship.created_at IS '创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN friendship.updated_at IS '更新时间戳 ( Unix 毫秒值 )';

-- 索引
CREATE INDEX idx_friendship_user ON friendship(user_id);
CREATE INDEX idx_friendship_user_active ON friendship(user_id, deleted_at) WHERE deleted_at = 0;
CREATE INDEX idx_friendship_user_starred ON friendship(user_id, is_starred) WHERE is_starred = TRUE AND deleted_at = 0;



-- ============================================================================
-- 读取侧 (Read Side) - 冗余宽表设计
-- ============================================================================

-- 用户会话视图表 ( 会话列表专用，冗余所有展示字段 )
DROP TABLE IF EXISTS user_conversation_view;
CREATE TABLE user_conversation_view (
    id BIGINT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    channel_id BIGINT NOT NULL,

    -- 会话基础信息 ( 冗余 )
    conversation_type channel_type_enum NOT NULL,
    conversation_name VARCHAR(128) NOT NULL DEFAULT '',         -- 冗余 ( 群名 或 对方昵称 / 备注名 )
    conversation_avatar VARCHAR(256) NOT NULL DEFAULT '',       -- 冗余 ( 群头像 或 对方头像 )
    conversation_info_ver INT NOT NULL DEFAULT 1,               -- 【 CQRS 关键字段 】版本号 ( 用于检测 channel / user 信息变更 )

    -- 单聊特有字段 ( 单聊时有值，群聊时为 NULL )
    peer_user_id BIGINT,                                        -- 对方用户ID
    peer_nickname VARCHAR(64),                                  -- 对方昵称 ( 冗余自 user 表 )
    peer_avatar VARCHAR(256),                                   -- 对方头像 ( 冗余自 user 表 )
    remark_name VARCHAR(64),                                    -- 我给对方的备注名

    -- 个性化设置
    is_muted BOOLEAN NOT NULL DEFAULT FALSE,                    -- 免打扰
    is_pinned BOOLEAN NOT NULL DEFAULT FALSE,                   -- 置顶
    is_hidden BOOLEAN NOT NULL DEFAULT FALSE,                   -- 隐藏
    is_starred BOOLEAN NOT NULL DEFAULT FALSE,                  -- 星标（仅单聊有意义）

    -- 最后消息快照（冗余，用于会话列表展示）
    last_message_id BIGINT NOT NULL DEFAULT 0,
    last_message_type VARCHAR(32) NOT NULL DEFAULT '',          -- 消息类型 ( text/image/voice/video 等 )
    last_message_content VARCHAR(512) NOT NULL DEFAULT '',      -- 消息内容摘要
    last_message_sender_id BIGINT NOT NULL DEFAULT 0,
    last_message_sender_name VARCHAR(64) NOT NULL DEFAULT '',   -- 发送者昵称 ( 冗余 )
    last_message_time BIGINT NOT NULL DEFAULT 0,

    -- 未读数（冗余，实时更新）
    unread_count INT NOT NULL DEFAULT 0,
    mention_count INT NOT NULL DEFAULT 0,                       -- @我的消息数

    -- 会话状态
    opened_at BIGINT NOT NULL,                                  -- 会话创建时间
    closed_at BIGINT NOT NULL DEFAULT 0,                        -- 会话删除时间 ( 0 表示未删除 )

    created_at BIGINT NOT NULL,
    updated_at BIGINT NOT NULL,

    -- 唯一约束
    CONSTRAINT uk_user_conversation UNIQUE(user_id, channel_id),

    -- 检查约束：单聊时必须有 peer_user_id
    CONSTRAINT chk_conversation_peer CHECK (
        (conversation_type = 'single' AND peer_user_id IS NOT NULL)
        OR
        (conversation_type = 'group' AND peer_user_id IS NULL)
    )
);

COMMENT ON TABLE user_conversation_view IS '【 读取侧 】用户会话视图表 ( 用于会话列表展示，冗余数据 )';
COMMENT ON COLUMN user_conversation_view.id IS '主键 ID';
COMMENT ON COLUMN user_conversation_view.user_id IS '用户 ID';
COMMENT ON COLUMN user_conversation_view.channel_id IS '频道 ID';
COMMENT ON COLUMN user_conversation_view.conversation_type IS '会话类型 ( single=单聊 / group=群聊 )';
COMMENT ON COLUMN user_conversation_view.conversation_name IS '会话显示名称 ( 单聊：备注名>昵称 / 群聊：群名 )';
COMMENT ON COLUMN user_conversation_view.conversation_avatar IS '会话显示头像 ( 单聊：对方头像，群聊：群头像 )';
COMMENT ON COLUMN user_conversation_view.conversation_info_ver IS '【 CQRS 关键字段 】会话信息版本号 ( 用于同步检测 )';
COMMENT ON COLUMN user_conversation_view.peer_user_id IS '单聊对方用户 ID ( 仅单聊有值 )';
COMMENT ON COLUMN user_conversation_view.peer_nickname IS '对方昵称 ( 冗余自 user 表 )';
COMMENT ON COLUMN user_conversation_view.peer_avatar IS '对方头像 ( 冗余自 user 表 )';
COMMENT ON COLUMN user_conversation_view.remark_name IS '好友备注名';
COMMENT ON COLUMN user_conversation_view.is_muted IS '是否免打扰';
COMMENT ON COLUMN user_conversation_view.is_pinned IS '是否置顶';
COMMENT ON COLUMN user_conversation_view.is_hidden IS '是否隐藏';
COMMENT ON COLUMN user_conversation_view.is_starred IS '是否星标 ( 仅单聊 )';
COMMENT ON COLUMN user_conversation_view.last_message_id IS '最后消息 ID';
COMMENT ON COLUMN user_conversation_view.last_message_type IS '最后消息类型';
COMMENT ON COLUMN user_conversation_view.last_message_content IS '最后消息内容摘要';
COMMENT ON COLUMN user_conversation_view.last_message_sender_id IS '最后消息发送者 ID';
COMMENT ON COLUMN user_conversation_view.last_message_sender_name IS '最后消息发送者昵称';
COMMENT ON COLUMN user_conversation_view.last_message_time IS '最后消息时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN user_conversation_view.unread_count IS '未读消息数';
COMMENT ON COLUMN user_conversation_view.mention_count IS '@我的消息数';
COMMENT ON COLUMN user_conversation_view.opened_at IS '会话创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN user_conversation_view.closed_at IS '会话删除时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN user_conversation_view.created_at IS '创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN user_conversation_view.updated_at IS '更新时间戳 ( Unix 毫秒值 )';

-- 索引 ( 针对会话列表查询优化 )
-- 1. 会话列表主查询 ( 按时间倒序 )
CREATE INDEX idx_ucv_list ON user_conversation_view(
    user_id,
    is_pinned DESC,
    last_message_time DESC
) WHERE closed_at = 0 AND is_hidden = FALSE;

-- 2. 置顶会话查询
CREATE INDEX idx_ucv_pinned ON user_conversation_view(
    user_id,
    last_message_time DESC
) WHERE is_pinned = TRUE AND closed_at = 0;

-- 3. 按会话类型过滤
CREATE INDEX idx_ucv_type ON user_conversation_view(
    user_id,
    conversation_type,
    last_message_time DESC
) WHERE closed_at = 0;

-- 4. 有未读消息的会话
CREATE INDEX idx_ucv_unread ON user_conversation_view(
    user_id,
    unread_count DESC,
    last_message_time DESC
) WHERE unread_count > 0 AND closed_at = 0;

-- 5. 单聊对方查询（用于判断是否已存在会话）
CREATE INDEX idx_ucv_peer ON user_conversation_view(user_id, peer_user_id)
    WHERE conversation_type = 'single';



-- 用户联系人视图表 ( 通讯录专用 - 冗余好友信息 )
DROP TABLE IF EXISTS user_contact_view;
CREATE TABLE user_contact_view (
    id BIGINT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    contact_id BIGINT NOT NULL,                                 -- 好友 user_id

    -- 联系人信息 ( 冗余自 user 表 )
    contact_nickname VARCHAR(64) NOT NULL DEFAULT '',           -- 好友昵称 ( 冗余 )
    contact_avatar VARCHAR(256) NOT NULL DEFAULT '',            -- 好友头像 ( 冗余 )
    contact_info_ver INT NOT NULL DEFAULT 1,                    -- 【 CQRS 关键字段 】好友信息版本号 ( 用于同步检测 )

    -- 好友关系信息 ( 冗余自 friendship 表 )
    remark_name VARCHAR(64) NOT NULL DEFAULT '',                -- 备注名
    group_name VARCHAR(32) NOT NULL DEFAULT 'friends',          -- 分组名
    tags VARCHAR(128)[] DEFAULT '{}',                           -- 标签

    -- 状态
    is_starred BOOLEAN NOT NULL DEFAULT FALSE,                  -- 星标
    is_blocked BOOLEAN NOT NULL DEFAULT FALSE,                  -- 黑名单

    -- 扩展信息 ( 可选，冗余自 user 表 )
    mobile VARCHAR(16) NOT NULL DEFAULT '',                     -- 手机号
    source friendship_source_enum NOT NULL DEFAULT 'search',    -- 添加来源

    added_at BIGINT NOT NULL,
    deleted_at BIGINT NOT NULL DEFAULT 0,

    created_at BIGINT NOT NULL,
    updated_at BIGINT NOT NULL,

    -- 唯一约束
    CONSTRAINT uk_user_contact UNIQUE(user_id, contact_id)
);

COMMENT ON TABLE user_contact_view IS '【 读取侧 】用户联系人视图表 ( 用于通讯录展示，冗余数据 )';
COMMENT ON COLUMN user_contact_view.id IS '主键 ID';
COMMENT ON COLUMN user_contact_view.user_id IS '用户 ID';
COMMENT ON COLUMN user_contact_view.contact_id IS '联系人 ID ( 好友 ID )';
COMMENT ON COLUMN user_contact_view.contact_nickname IS '联系人昵称 ( 冗余自 user 表 )';
COMMENT ON COLUMN user_contact_view.contact_avatar IS '联系人头像 ( 冗余自 user 表 )';
COMMENT ON COLUMN user_contact_view.contact_info_ver IS '【 CQRS 关键字段 】联系人信息版本号 ( 用于同步检测 )';
COMMENT ON COLUMN user_contact_view.remark_name IS '备注名';
COMMENT ON COLUMN user_contact_view.group_name IS '分组名';
COMMENT ON COLUMN user_contact_view.tags IS '标签数组';
COMMENT ON COLUMN user_contact_view.is_starred IS '是否星标';
COMMENT ON COLUMN user_contact_view.is_blocked IS '是否拉黑';
COMMENT ON COLUMN user_contact_view.mobile IS '手机号 ( 冗余 )';
COMMENT ON COLUMN user_contact_view.source IS '添加来源';
COMMENT ON COLUMN user_contact_view.added_at IS '添加时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN user_contact_view.deleted_at IS '删除时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN user_contact_view.created_at IS '创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN user_contact_view.updated_at IS '更新时间戳 ( Unix 毫秒值 )';

-- 索引 ( 针对通讯录查询优化 )
-- 1. 通讯录列表查询 ( 按昵称排序 )
CREATE INDEX idx_ucov_list ON user_contact_view(
    user_id,
    is_starred DESC,
    contact_nickname
) WHERE deleted_at = 0;

-- 2. 按分组查询
CREATE INDEX idx_ucov_group ON user_contact_view(
    user_id,
    group_name,
    contact_nickname
) WHERE deleted_at = 0;

-- 3. 星标好友查询
CREATE INDEX idx_ucov_starred ON user_contact_view(
    user_id,
    contact_nickname
) WHERE is_starred = TRUE AND deleted_at = 0;

-- 4. 按首字母查询 ( 如果需要 )
CREATE INDEX idx_ucov_initial ON user_contact_view(
    user_id,
    LEFT(contact_nickname, 1),
    contact_nickname
) WHERE deleted_at = 0;


-- ============================================================================
-- 反向索引 ( Reverse Index ) - 加速数据同步
-- ============================================================================

-- 会话反向索引表 ( 用于快速查询 - "谁的会话中有某个用户" )
DROP TABLE IF EXISTS conversation_reverse_index;
CREATE TABLE conversation_reverse_index (
    peer_user_id BIGINT NOT NULL,                           -- 单聊对方用户 ID
    owner_user_id BIGINT NOT NULL,                          -- 会话所有者 ( 谁的会话 )
    channel_id BIGINT NOT NULL,                             -- 频道 ID

    created_at BIGINT NOT NULL,

    PRIMARY KEY(peer_user_id, owner_user_id)
);

COMMENT ON TABLE conversation_reverse_index IS '【 反向索引 】会话反向索引表 ( 用于用户资料变更时，快速查询 "谁的会话中有某个用户" )';
COMMENT ON COLUMN conversation_reverse_index.peer_user_id IS '单聊对方用户 ID';
COMMENT ON COLUMN conversation_reverse_index.owner_user_id IS '会话所有者 ID';
COMMENT ON COLUMN conversation_reverse_index.channel_id IS '频道 ID';
COMMENT ON COLUMN conversation_reverse_index.created_at IS '创建时间戳 ( Unix 毫秒值 )';

-- 索引
CREATE INDEX idx_cri_peer ON conversation_reverse_index(peer_user_id);

-- 使用场景示例：
-- 用户 A 修改了昵称/头像，需要更新哪些人的会话视图？
-- SELECT owner_user_id, channel_id FROM conversation_reverse_index WHERE peer_user_id = A


-- 联系人反向索引表 ( 用于快速查询 - "谁的联系人中有某个用户" )
DROP TABLE IF EXISTS contact_reverse_index;
CREATE TABLE contact_reverse_index (
    contact_user_id BIGINT NOT NULL,                        -- 被添加的用户 ID
    owner_user_id BIGINT NOT NULL,                          -- 联系人所有者 ( 谁的联系人 )

    created_at BIGINT NOT NULL,

    PRIMARY KEY(contact_user_id, owner_user_id)
);

COMMENT ON TABLE contact_reverse_index IS '【 反向索引 】联系人反向索引表 ( 用于用户资料变更时，快速查询 "谁的联系人中有某个用户" )';
COMMENT ON COLUMN contact_reverse_index.contact_user_id IS '联系人用户 ID ( 被添加的人 )';
COMMENT ON COLUMN contact_reverse_index.owner_user_id IS '联系人所有者 ID ( 谁添加了他 )';
COMMENT ON COLUMN contact_reverse_index.created_at IS '创建时间戳 ( Unix 毫秒值 )';

-- 索引
CREATE INDEX idx_cori_contact ON contact_reverse_index(contact_user_id);

-- 使用场景示例：
-- 用户 A 修改了昵称/头像，需要更新哪些人的联系人视图？
-- SELECT owner_user_id FROM contact_reverse_index WHERE contact_user_id = A


-- ============================================================================
-- 其他业务表
-- ============================================================================

-- 申请状态枚举
DROP TYPE IF EXISTS application_status_enum CASCADE;
CREATE TYPE application_status_enum AS ENUM ('pending', 'approved', 'rejected');

-- 联系人申请表 ( 加好友申请 - 以 TargetID 为分片键 )
DROP TABLE IF EXISTS contact_application;
CREATE TABLE contact_application (
    id BIGINT PRIMARY KEY,

    applicant_id BIGINT NOT NULL,

    -- 目标用户信息。
    target_id BIGINT NOT NULL,
    target_name VARCHAR(128) NOT NULL DEFAULT '',
    target_avatar VARCHAR(256) NOT NULL DEFAULT '',

    application_status application_status_enum NOT NULL,
    application_message VARCHAR(256) NOT NULL DEFAULT '',

    reviewed_at BIGINT NOT NULL DEFAULT 0,

    created_at BIGINT NOT NULL,
    updated_at BIGINT NOT NULL
);

COMMENT ON TABLE contact_application IS '联系人申请表 ( 加好友申请 )';
COMMENT ON COLUMN contact_application.id IS '主键 ID';
COMMENT ON COLUMN contact_application.applicant_id IS '申请人 ID';
COMMENT ON COLUMN contact_application.target_id IS '目标用户 ID';
COMMENT ON COLUMN contact_application.target_name IS '目标用户昵称';
COMMENT ON COLUMN contact_application.target_avatar IS '目标用户头像';
COMMENT ON COLUMN contact_application.application_status IS '申请状态 ( pending=待处理 / approved=已批准 / rejected=已拒绝 )';
COMMENT ON COLUMN contact_application.application_message IS '申请验证消息';
COMMENT ON COLUMN contact_application.reviewed_at IS '审批时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN contact_application.created_at IS '创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN contact_application.updated_at IS '更新时间戳 ( Unix 毫秒值 )';

-- 索引
CREATE INDEX idx_contact_application_target ON contact_application(target_id);
CREATE INDEX idx_contact_application_pending ON contact_application(target_id, application_status) WHERE application_status = 'pending';



-- 频道申请表 ( 入群申请 - 以 ChannelID 为分片键 )
DROP TABLE IF EXISTS channel_application;
CREATE TABLE channel_application (
    id BIGINT PRIMARY KEY,

    applicant_id BIGINT NOT NULL,

    -- 目标渠道信息。
    channel_id BIGINT NOT NULL,
    channel_name VARCHAR(128) NOT NULL DEFAULT '',
    channel_avatar VARCHAR(256) NOT NULL DEFAULT '',

    application_status application_status_enum NOT NULL,
    application_message VARCHAR(256) NOT NULL DEFAULT '',

    reviewer_id BIGINT NOT NULL DEFAULT 0,
    reviewed_at BIGINT NOT NULL DEFAULT 0,

    created_at BIGINT NOT NULL,
    updated_at BIGINT NOT NULL
);

COMMENT ON TABLE channel_application IS '频道申请表 ( 入群申请 )';
COMMENT ON COLUMN channel_application.id IS '主键 ID';
COMMENT ON COLUMN channel_application.applicant_id IS '申请人 ID';
COMMENT ON COLUMN channel_application.channel_id IS '频道 ID';
COMMENT ON COLUMN channel_application.channel_name IS '频道名称';
COMMENT ON COLUMN channel_application.channel_avatar IS '频道头像';
COMMENT ON COLUMN channel_application.application_status IS '申请状态 ( pending=待处理 / approved=已批准 / rejected=已拒绝 )';
COMMENT ON COLUMN channel_application.application_message IS '申请验证消息';
COMMENT ON COLUMN channel_application.reviewer_id IS '审批人 ID';
COMMENT ON COLUMN channel_application.reviewed_at IS '审批时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN channel_application.created_at IS '创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN channel_application.updated_at IS '更新时间戳 ( Unix 毫秒值 )';

-- 索引
CREATE INDEX idx_channel_application_channel ON channel_application(channel_id);
CREATE INDEX idx_channel_application_pending ON channel_application(channel_id, application_status) WHERE application_status = 'pending';
