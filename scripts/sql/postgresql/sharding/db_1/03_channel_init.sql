-- ============================================
-- 分库分表SQL脚本
-- 数据库: hermet_1
-- 分表数量: 4
-- 生成时间: 2026-01-09 19:22:17
-- 原始文件: ./03_channel_init.sql
-- ============================================

-- ============================================
-- 枚举类型定义
-- ============================================

DROP TYPE IF EXISTS application_status_enum CASCADE;
CREATE TYPE application_status_enum AS ENUM ('pending', 'approved', 'rejected');

DROP TYPE IF EXISTS channel_member_role_enum CASCADE;
CREATE TYPE channel_member_role_enum AS ENUM ('owner', 'admin', 'member');

DROP TYPE IF EXISTS channel_status_enum CASCADE;
CREATE TYPE channel_status_enum AS ENUM ('creating', 'active', 'failed','archived');

DROP TYPE IF EXISTS channel_type_enum CASCADE;
CREATE TYPE channel_type_enum AS ENUM ('single', 'group');

DROP TYPE IF EXISTS contact_source_enum CASCADE;
CREATE TYPE contact_source_enum AS ENUM ('search', 'qrcode', 'group');

-- ============================================
-- 表: channel (分表数: 4)
-- ============================================

-- 分表 0: channel_0
DROP TABLE IF EXISTS channel_0;
CREATE TABLE channel_0 (
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

COMMENT ON TABLE channel_0 IS '【写入侧】频道表（聊天会话表）';
COMMENT ON COLUMN channel_0.id IS '频道 ID';
COMMENT ON COLUMN channel_0.channel_name IS '频道名称 ( 单聊为空 )';
COMMENT ON COLUMN channel_0.channel_type IS '频道类型 ( single=单聊 / group=群聊 )';
COMMENT ON COLUMN channel_0.channel_avatar IS '频道头像';
COMMENT ON COLUMN channel_0.channel_status IS '频道状态 ( creating=创建中 / active=活跃 / failed=失败 / archived=已归档 )';
COMMENT ON COLUMN channel_0.channel_info_ver IS '【 CQRS 关键字段 】频道信息版本号 ( 用于同步检测 )';
COMMENT ON COLUMN channel_0.channel_member_count IS '频道成员数量';
COMMENT ON COLUMN channel_0.last_message_at IS '最后消息时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN channel_0.creator_id IS '创建者 ID';
COMMENT ON COLUMN channel_0.created_at IS '创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN channel_0.updated_at IS '更新时间戳 ( Unix 毫秒值 )';

-- 创建索引
CREATE INDEX idx_channel_type_0 ON channel_0(channel_type);

CREATE INDEX idx_channel_creator_0 ON channel_0(creator_id);

CREATE INDEX idx_channel_status_0 ON channel_0(channel_status);

-- 分表 1: channel_1
DROP TABLE IF EXISTS channel_1;
CREATE TABLE channel_1 (
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

COMMENT ON TABLE channel_1 IS '【写入侧】频道表（聊天会话表）';
COMMENT ON COLUMN channel_1.id IS '频道 ID';
COMMENT ON COLUMN channel_1.channel_name IS '频道名称 ( 单聊为空 )';
COMMENT ON COLUMN channel_1.channel_type IS '频道类型 ( single=单聊 / group=群聊 )';
COMMENT ON COLUMN channel_1.channel_avatar IS '频道头像';
COMMENT ON COLUMN channel_1.channel_status IS '频道状态 ( creating=创建中 / active=活跃 / failed=失败 / archived=已归档 )';
COMMENT ON COLUMN channel_1.channel_info_ver IS '【 CQRS 关键字段 】频道信息版本号 ( 用于同步检测 )';
COMMENT ON COLUMN channel_1.channel_member_count IS '频道成员数量';
COMMENT ON COLUMN channel_1.last_message_at IS '最后消息时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN channel_1.creator_id IS '创建者 ID';
COMMENT ON COLUMN channel_1.created_at IS '创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN channel_1.updated_at IS '更新时间戳 ( Unix 毫秒值 )';

-- 创建索引
CREATE INDEX idx_channel_type_1 ON channel_1(channel_type);

CREATE INDEX idx_channel_creator_1 ON channel_1(creator_id);

CREATE INDEX idx_channel_status_1 ON channel_1(channel_status);

-- 分表 2: channel_2
DROP TABLE IF EXISTS channel_2;
CREATE TABLE channel_2 (
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

COMMENT ON TABLE channel_2 IS '【写入侧】频道表（聊天会话表）';
COMMENT ON COLUMN channel_2.id IS '频道 ID';
COMMENT ON COLUMN channel_2.channel_name IS '频道名称 ( 单聊为空 )';
COMMENT ON COLUMN channel_2.channel_type IS '频道类型 ( single=单聊 / group=群聊 )';
COMMENT ON COLUMN channel_2.channel_avatar IS '频道头像';
COMMENT ON COLUMN channel_2.channel_status IS '频道状态 ( creating=创建中 / active=活跃 / failed=失败 / archived=已归档 )';
COMMENT ON COLUMN channel_2.channel_info_ver IS '【 CQRS 关键字段 】频道信息版本号 ( 用于同步检测 )';
COMMENT ON COLUMN channel_2.channel_member_count IS '频道成员数量';
COMMENT ON COLUMN channel_2.last_message_at IS '最后消息时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN channel_2.creator_id IS '创建者 ID';
COMMENT ON COLUMN channel_2.created_at IS '创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN channel_2.updated_at IS '更新时间戳 ( Unix 毫秒值 )';

-- 创建索引
CREATE INDEX idx_channel_type_2 ON channel_2(channel_type);

CREATE INDEX idx_channel_creator_2 ON channel_2(creator_id);

CREATE INDEX idx_channel_status_2 ON channel_2(channel_status);

-- 分表 3: channel_3
DROP TABLE IF EXISTS channel_3;
CREATE TABLE channel_3 (
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

COMMENT ON TABLE channel_3 IS '【写入侧】频道表（聊天会话表）';
COMMENT ON COLUMN channel_3.id IS '频道 ID';
COMMENT ON COLUMN channel_3.channel_name IS '频道名称 ( 单聊为空 )';
COMMENT ON COLUMN channel_3.channel_type IS '频道类型 ( single=单聊 / group=群聊 )';
COMMENT ON COLUMN channel_3.channel_avatar IS '频道头像';
COMMENT ON COLUMN channel_3.channel_status IS '频道状态 ( creating=创建中 / active=活跃 / failed=失败 / archived=已归档 )';
COMMENT ON COLUMN channel_3.channel_info_ver IS '【 CQRS 关键字段 】频道信息版本号 ( 用于同步检测 )';
COMMENT ON COLUMN channel_3.channel_member_count IS '频道成员数量';
COMMENT ON COLUMN channel_3.last_message_at IS '最后消息时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN channel_3.creator_id IS '创建者 ID';
COMMENT ON COLUMN channel_3.created_at IS '创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN channel_3.updated_at IS '更新时间戳 ( Unix 毫秒值 )';

-- 创建索引
CREATE INDEX idx_channel_type_3 ON channel_3(channel_type);

CREATE INDEX idx_channel_creator_3 ON channel_3(creator_id);

CREATE INDEX idx_channel_status_3 ON channel_3(channel_status);

-- ============================================
-- 表: channel_application (分表数: 4)
-- ============================================

-- 分表 0: channel_application_0
DROP TABLE IF EXISTS channel_application_0;
CREATE TABLE channel_application_0 (
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

COMMENT ON TABLE channel_application_0 IS '频道申请表 ( 入群申请 )';
COMMENT ON COLUMN channel_application_0.id IS '主键 ID';
COMMENT ON COLUMN channel_application_0.applicant_id IS '申请人 ID';
COMMENT ON COLUMN channel_application_0.channel_id IS '频道 ID';
COMMENT ON COLUMN channel_application_0.channel_name IS '频道名称';
COMMENT ON COLUMN channel_application_0.channel_avatar IS '频道头像';
COMMENT ON COLUMN channel_application_0.application_status IS '申请状态 ( pending=待处理 / approved=已批准 / rejected=已拒绝 )';
COMMENT ON COLUMN channel_application_0.application_message IS '申请验证消息';
COMMENT ON COLUMN channel_application_0.reviewer_id IS '审批人 ID';
COMMENT ON COLUMN channel_application_0.reviewed_at IS '审批时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN channel_application_0.created_at IS '创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN channel_application_0.updated_at IS '更新时间戳 ( Unix 毫秒值 )';

-- 创建索引
CREATE INDEX idx_channel_application_channel_0 ON channel_application_0(channel_id);

CREATE INDEX idx_channel_application_pending_0 ON channel_application_0(channel_id, application_status) WHERE application_status = 'pending';

-- 分表 1: channel_application_1
DROP TABLE IF EXISTS channel_application_1;
CREATE TABLE channel_application_1 (
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

COMMENT ON TABLE channel_application_1 IS '频道申请表 ( 入群申请 )';
COMMENT ON COLUMN channel_application_1.id IS '主键 ID';
COMMENT ON COLUMN channel_application_1.applicant_id IS '申请人 ID';
COMMENT ON COLUMN channel_application_1.channel_id IS '频道 ID';
COMMENT ON COLUMN channel_application_1.channel_name IS '频道名称';
COMMENT ON COLUMN channel_application_1.channel_avatar IS '频道头像';
COMMENT ON COLUMN channel_application_1.application_status IS '申请状态 ( pending=待处理 / approved=已批准 / rejected=已拒绝 )';
COMMENT ON COLUMN channel_application_1.application_message IS '申请验证消息';
COMMENT ON COLUMN channel_application_1.reviewer_id IS '审批人 ID';
COMMENT ON COLUMN channel_application_1.reviewed_at IS '审批时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN channel_application_1.created_at IS '创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN channel_application_1.updated_at IS '更新时间戳 ( Unix 毫秒值 )';

-- 创建索引
CREATE INDEX idx_channel_application_channel_1 ON channel_application_1(channel_id);

CREATE INDEX idx_channel_application_pending_1 ON channel_application_1(channel_id, application_status) WHERE application_status = 'pending';

-- 分表 2: channel_application_2
DROP TABLE IF EXISTS channel_application_2;
CREATE TABLE channel_application_2 (
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

COMMENT ON TABLE channel_application_2 IS '频道申请表 ( 入群申请 )';
COMMENT ON COLUMN channel_application_2.id IS '主键 ID';
COMMENT ON COLUMN channel_application_2.applicant_id IS '申请人 ID';
COMMENT ON COLUMN channel_application_2.channel_id IS '频道 ID';
COMMENT ON COLUMN channel_application_2.channel_name IS '频道名称';
COMMENT ON COLUMN channel_application_2.channel_avatar IS '频道头像';
COMMENT ON COLUMN channel_application_2.application_status IS '申请状态 ( pending=待处理 / approved=已批准 / rejected=已拒绝 )';
COMMENT ON COLUMN channel_application_2.application_message IS '申请验证消息';
COMMENT ON COLUMN channel_application_2.reviewer_id IS '审批人 ID';
COMMENT ON COLUMN channel_application_2.reviewed_at IS '审批时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN channel_application_2.created_at IS '创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN channel_application_2.updated_at IS '更新时间戳 ( Unix 毫秒值 )';

-- 创建索引
CREATE INDEX idx_channel_application_channel_2 ON channel_application_2(channel_id);

CREATE INDEX idx_channel_application_pending_2 ON channel_application_2(channel_id, application_status) WHERE application_status = 'pending';

-- 分表 3: channel_application_3
DROP TABLE IF EXISTS channel_application_3;
CREATE TABLE channel_application_3 (
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

COMMENT ON TABLE channel_application_3 IS '频道申请表 ( 入群申请 )';
COMMENT ON COLUMN channel_application_3.id IS '主键 ID';
COMMENT ON COLUMN channel_application_3.applicant_id IS '申请人 ID';
COMMENT ON COLUMN channel_application_3.channel_id IS '频道 ID';
COMMENT ON COLUMN channel_application_3.channel_name IS '频道名称';
COMMENT ON COLUMN channel_application_3.channel_avatar IS '频道头像';
COMMENT ON COLUMN channel_application_3.application_status IS '申请状态 ( pending=待处理 / approved=已批准 / rejected=已拒绝 )';
COMMENT ON COLUMN channel_application_3.application_message IS '申请验证消息';
COMMENT ON COLUMN channel_application_3.reviewer_id IS '审批人 ID';
COMMENT ON COLUMN channel_application_3.reviewed_at IS '审批时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN channel_application_3.created_at IS '创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN channel_application_3.updated_at IS '更新时间戳 ( Unix 毫秒值 )';

-- 创建索引
CREATE INDEX idx_channel_application_channel_3 ON channel_application_3(channel_id);

CREATE INDEX idx_channel_application_pending_3 ON channel_application_3(channel_id, application_status) WHERE application_status = 'pending';

-- ============================================
-- 表: channel_member (分表数: 4)
-- ============================================

-- 分表 0: channel_member_0
DROP TABLE IF EXISTS channel_member_0;
CREATE TABLE channel_member_0 (
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
    CONSTRAINT uk_channel_member_channel_user_0 UNIQUE(channel_id, user_id)
);

COMMENT ON TABLE channel_member_0 IS '【 写入侧 】频道成员表';
COMMENT ON COLUMN channel_member_0.id IS '主键 ID';
COMMENT ON COLUMN channel_member_0.channel_id IS '频道 ID';
COMMENT ON COLUMN channel_member_0.user_id IS '用户 ID';
COMMENT ON COLUMN channel_member_0.role IS '成员角色 ( owner=群主 / admin=管理员 / member=普通成员 )';
COMMENT ON COLUMN channel_member_0.nickname IS '群昵称（用户在该群的昵称）';
COMMENT ON COLUMN channel_member_0.joined_at IS '加入时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN channel_member_0.left_at IS '退出时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN channel_member_0.created_at IS '创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN channel_member_0.updated_at IS '更新时间戳 ( Unix 毫秒值 )';

-- 创建索引
CREATE INDEX idx_channel_member_channel_0 ON channel_member_0(channel_id);

CREATE INDEX idx_channel_member_user_0 ON channel_member_0(user_id);

CREATE INDEX idx_channel_member_active_0 ON channel_member_0(channel_id, left_at) WHERE left_at = 0;

-- 分表 1: channel_member_1
DROP TABLE IF EXISTS channel_member_1;
CREATE TABLE channel_member_1 (
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
    CONSTRAINT uk_channel_member_channel_user_1 UNIQUE(channel_id, user_id)
);

COMMENT ON TABLE channel_member_1 IS '【 写入侧 】频道成员表';
COMMENT ON COLUMN channel_member_1.id IS '主键 ID';
COMMENT ON COLUMN channel_member_1.channel_id IS '频道 ID';
COMMENT ON COLUMN channel_member_1.user_id IS '用户 ID';
COMMENT ON COLUMN channel_member_1.role IS '成员角色 ( owner=群主 / admin=管理员 / member=普通成员 )';
COMMENT ON COLUMN channel_member_1.nickname IS '群昵称（用户在该群的昵称）';
COMMENT ON COLUMN channel_member_1.joined_at IS '加入时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN channel_member_1.left_at IS '退出时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN channel_member_1.created_at IS '创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN channel_member_1.updated_at IS '更新时间戳 ( Unix 毫秒值 )';

-- 创建索引
CREATE INDEX idx_channel_member_channel_1 ON channel_member_1(channel_id);

CREATE INDEX idx_channel_member_user_1 ON channel_member_1(user_id);

CREATE INDEX idx_channel_member_active_1 ON channel_member_1(channel_id, left_at) WHERE left_at = 0;

-- 分表 2: channel_member_2
DROP TABLE IF EXISTS channel_member_2;
CREATE TABLE channel_member_2 (
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
    CONSTRAINT uk_channel_member_channel_user_2 UNIQUE(channel_id, user_id)
);

COMMENT ON TABLE channel_member_2 IS '【 写入侧 】频道成员表';
COMMENT ON COLUMN channel_member_2.id IS '主键 ID';
COMMENT ON COLUMN channel_member_2.channel_id IS '频道 ID';
COMMENT ON COLUMN channel_member_2.user_id IS '用户 ID';
COMMENT ON COLUMN channel_member_2.role IS '成员角色 ( owner=群主 / admin=管理员 / member=普通成员 )';
COMMENT ON COLUMN channel_member_2.nickname IS '群昵称（用户在该群的昵称）';
COMMENT ON COLUMN channel_member_2.joined_at IS '加入时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN channel_member_2.left_at IS '退出时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN channel_member_2.created_at IS '创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN channel_member_2.updated_at IS '更新时间戳 ( Unix 毫秒值 )';

-- 创建索引
CREATE INDEX idx_channel_member_channel_2 ON channel_member_2(channel_id);

CREATE INDEX idx_channel_member_user_2 ON channel_member_2(user_id);

CREATE INDEX idx_channel_member_active_2 ON channel_member_2(channel_id, left_at) WHERE left_at = 0;

-- 分表 3: channel_member_3
DROP TABLE IF EXISTS channel_member_3;
CREATE TABLE channel_member_3 (
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
    CONSTRAINT uk_channel_member_channel_user_3 UNIQUE(channel_id, user_id)
);

COMMENT ON TABLE channel_member_3 IS '【 写入侧 】频道成员表';
COMMENT ON COLUMN channel_member_3.id IS '主键 ID';
COMMENT ON COLUMN channel_member_3.channel_id IS '频道 ID';
COMMENT ON COLUMN channel_member_3.user_id IS '用户 ID';
COMMENT ON COLUMN channel_member_3.role IS '成员角色 ( owner=群主 / admin=管理员 / member=普通成员 )';
COMMENT ON COLUMN channel_member_3.nickname IS '群昵称（用户在该群的昵称）';
COMMENT ON COLUMN channel_member_3.joined_at IS '加入时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN channel_member_3.left_at IS '退出时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN channel_member_3.created_at IS '创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN channel_member_3.updated_at IS '更新时间戳 ( Unix 毫秒值 )';

-- 创建索引
CREATE INDEX idx_channel_member_channel_3 ON channel_member_3(channel_id);

CREATE INDEX idx_channel_member_user_3 ON channel_member_3(user_id);

CREATE INDEX idx_channel_member_active_3 ON channel_member_3(channel_id, left_at) WHERE left_at = 0;

-- ============================================
-- 表: channel_read_record (分表数: 4)
-- ============================================

-- 分表 0: channel_read_record_0
DROP TABLE IF EXISTS channel_read_record_0;
CREATE TABLE channel_read_record_0 (
    id BIGINT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    channel_id BIGINT NOT NULL,
    last_read_message_id BIGINT NOT NULL DEFAULT 0,

    created_at BIGINT NOT NULL,
    updated_at BIGINT NOT NULL,

    -- 唯一约束：一个用户在一个频道中只有一条已读记录
    CONSTRAINT uk_read_record_user_channel_0 UNIQUE(user_id, channel_id)
);

COMMENT ON TABLE channel_read_record_0 IS '【 写入侧 】频道消息已读记录表';
COMMENT ON COLUMN channel_read_record_0.id IS '主键 ID';
COMMENT ON COLUMN channel_read_record_0.user_id IS '用户 ID';
COMMENT ON COLUMN channel_read_record_0.channel_id IS '频道 ID';
COMMENT ON COLUMN channel_read_record_0.last_read_message_id IS '最后已读消息 ID';
COMMENT ON COLUMN channel_read_record_0.created_at IS '创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN channel_read_record_0.updated_at IS '更新时间戳 ( Unix 毫秒值 )';

-- 创建索引
CREATE INDEX idx_channel_read_user_channel_0 ON channel_read_record_0(user_id, channel_id);

-- 分表 1: channel_read_record_1
DROP TABLE IF EXISTS channel_read_record_1;
CREATE TABLE channel_read_record_1 (
    id BIGINT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    channel_id BIGINT NOT NULL,
    last_read_message_id BIGINT NOT NULL DEFAULT 0,

    created_at BIGINT NOT NULL,
    updated_at BIGINT NOT NULL,

    -- 唯一约束：一个用户在一个频道中只有一条已读记录
    CONSTRAINT uk_read_record_user_channel_1 UNIQUE(user_id, channel_id)
);

COMMENT ON TABLE channel_read_record_1 IS '【 写入侧 】频道消息已读记录表';
COMMENT ON COLUMN channel_read_record_1.id IS '主键 ID';
COMMENT ON COLUMN channel_read_record_1.user_id IS '用户 ID';
COMMENT ON COLUMN channel_read_record_1.channel_id IS '频道 ID';
COMMENT ON COLUMN channel_read_record_1.last_read_message_id IS '最后已读消息 ID';
COMMENT ON COLUMN channel_read_record_1.created_at IS '创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN channel_read_record_1.updated_at IS '更新时间戳 ( Unix 毫秒值 )';

-- 创建索引
CREATE INDEX idx_channel_read_user_channel_1 ON channel_read_record_1(user_id, channel_id);

-- 分表 2: channel_read_record_2
DROP TABLE IF EXISTS channel_read_record_2;
CREATE TABLE channel_read_record_2 (
    id BIGINT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    channel_id BIGINT NOT NULL,
    last_read_message_id BIGINT NOT NULL DEFAULT 0,

    created_at BIGINT NOT NULL,
    updated_at BIGINT NOT NULL,

    -- 唯一约束：一个用户在一个频道中只有一条已读记录
    CONSTRAINT uk_read_record_user_channel_2 UNIQUE(user_id, channel_id)
);

COMMENT ON TABLE channel_read_record_2 IS '【 写入侧 】频道消息已读记录表';
COMMENT ON COLUMN channel_read_record_2.id IS '主键 ID';
COMMENT ON COLUMN channel_read_record_2.user_id IS '用户 ID';
COMMENT ON COLUMN channel_read_record_2.channel_id IS '频道 ID';
COMMENT ON COLUMN channel_read_record_2.last_read_message_id IS '最后已读消息 ID';
COMMENT ON COLUMN channel_read_record_2.created_at IS '创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN channel_read_record_2.updated_at IS '更新时间戳 ( Unix 毫秒值 )';

-- 创建索引
CREATE INDEX idx_channel_read_user_channel_2 ON channel_read_record_2(user_id, channel_id);

-- 分表 3: channel_read_record_3
DROP TABLE IF EXISTS channel_read_record_3;
CREATE TABLE channel_read_record_3 (
    id BIGINT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    channel_id BIGINT NOT NULL,
    last_read_message_id BIGINT NOT NULL DEFAULT 0,

    created_at BIGINT NOT NULL,
    updated_at BIGINT NOT NULL,

    -- 唯一约束：一个用户在一个频道中只有一条已读记录
    CONSTRAINT uk_read_record_user_channel_3 UNIQUE(user_id, channel_id)
);

COMMENT ON TABLE channel_read_record_3 IS '【 写入侧 】频道消息已读记录表';
COMMENT ON COLUMN channel_read_record_3.id IS '主键 ID';
COMMENT ON COLUMN channel_read_record_3.user_id IS '用户 ID';
COMMENT ON COLUMN channel_read_record_3.channel_id IS '频道 ID';
COMMENT ON COLUMN channel_read_record_3.last_read_message_id IS '最后已读消息 ID';
COMMENT ON COLUMN channel_read_record_3.created_at IS '创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN channel_read_record_3.updated_at IS '更新时间戳 ( Unix 毫秒值 )';

-- 创建索引
CREATE INDEX idx_channel_read_user_channel_3 ON channel_read_record_3(user_id, channel_id);

-- ============================================
-- 表: contact_application (分表数: 4)
-- ============================================

-- 分表 0: contact_application_0
DROP TABLE IF EXISTS contact_application_0;
CREATE TABLE contact_application_0 (
    id BIGINT PRIMARY KEY,

    target_id BIGINT NOT NULL,

    -- 申请用户信息。
    applicant_id BIGINT NOT NULL,
    applicant_name VARCHAR(128) NOT NULL DEFAULT '',
    applicant_avatar VARCHAR(256) NOT NULL DEFAULT '',

    -- 添加来源 ( search=搜索添加 / qrcode=扫码添加 / group=群聊添加 )
    source contact_source_enum NOT NULL DEFAULT 'search',

    application_status application_status_enum NOT NULL,
    application_message VARCHAR(256) NOT NULL DEFAULT '',

    reviewed_at BIGINT NOT NULL DEFAULT 0,

    created_at BIGINT NOT NULL,
    updated_at BIGINT NOT NULL
);

COMMENT ON TABLE contact_application_0 IS '联系人申请表 ( 加好友申请 )';
COMMENT ON COLUMN contact_application_0.id IS '主键 ID';
COMMENT ON COLUMN contact_application_0.target_id IS '目标用户 ID';
COMMENT ON COLUMN contact_application_0.applicant_id IS '申请人 ID';
COMMENT ON COLUMN contact_application_0.applicant_name IS '申请人昵称';
COMMENT ON COLUMN contact_application_0.applicant_avatar IS '申请人头像';
COMMENT ON COLUMN contact_application_0.source IS '添加来源 ( search=搜索添加 / qrcode=扫码添加 / group=群聊添加 )';
COMMENT ON COLUMN contact_application_0.application_status IS '申请状态 ( pending=待处理 / approved=已批准 / rejected=已拒绝 )';
COMMENT ON COLUMN contact_application_0.application_message IS '申请验证消息';
COMMENT ON COLUMN contact_application_0.reviewed_at IS '审批时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN contact_application_0.created_at IS '创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN contact_application_0.updated_at IS '更新时间戳 ( Unix 毫秒值 )';

-- 创建索引
CREATE INDEX idx_contact_application_target_0 ON contact_application_0(target_id);

CREATE INDEX idx_contact_application_pending_0 ON contact_application_0(target_id, application_status) WHERE application_status = 'pending';

-- 分表 1: contact_application_1
DROP TABLE IF EXISTS contact_application_1;
CREATE TABLE contact_application_1 (
    id BIGINT PRIMARY KEY,

    target_id BIGINT NOT NULL,

    -- 申请用户信息。
    applicant_id BIGINT NOT NULL,
    applicant_name VARCHAR(128) NOT NULL DEFAULT '',
    applicant_avatar VARCHAR(256) NOT NULL DEFAULT '',

    -- 添加来源 ( search=搜索添加 / qrcode=扫码添加 / group=群聊添加 )
    source contact_source_enum NOT NULL DEFAULT 'search',

    application_status application_status_enum NOT NULL,
    application_message VARCHAR(256) NOT NULL DEFAULT '',

    reviewed_at BIGINT NOT NULL DEFAULT 0,

    created_at BIGINT NOT NULL,
    updated_at BIGINT NOT NULL
);

COMMENT ON TABLE contact_application_1 IS '联系人申请表 ( 加好友申请 )';
COMMENT ON COLUMN contact_application_1.id IS '主键 ID';
COMMENT ON COLUMN contact_application_1.target_id IS '目标用户 ID';
COMMENT ON COLUMN contact_application_1.applicant_id IS '申请人 ID';
COMMENT ON COLUMN contact_application_1.applicant_name IS '申请人昵称';
COMMENT ON COLUMN contact_application_1.applicant_avatar IS '申请人头像';
COMMENT ON COLUMN contact_application_1.source IS '添加来源 ( search=搜索添加 / qrcode=扫码添加 / group=群聊添加 )';
COMMENT ON COLUMN contact_application_1.application_status IS '申请状态 ( pending=待处理 / approved=已批准 / rejected=已拒绝 )';
COMMENT ON COLUMN contact_application_1.application_message IS '申请验证消息';
COMMENT ON COLUMN contact_application_1.reviewed_at IS '审批时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN contact_application_1.created_at IS '创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN contact_application_1.updated_at IS '更新时间戳 ( Unix 毫秒值 )';

-- 创建索引
CREATE INDEX idx_contact_application_target_1 ON contact_application_1(target_id);

CREATE INDEX idx_contact_application_pending_1 ON contact_application_1(target_id, application_status) WHERE application_status = 'pending';

-- 分表 2: contact_application_2
DROP TABLE IF EXISTS contact_application_2;
CREATE TABLE contact_application_2 (
    id BIGINT PRIMARY KEY,

    target_id BIGINT NOT NULL,

    -- 申请用户信息。
    applicant_id BIGINT NOT NULL,
    applicant_name VARCHAR(128) NOT NULL DEFAULT '',
    applicant_avatar VARCHAR(256) NOT NULL DEFAULT '',

    -- 添加来源 ( search=搜索添加 / qrcode=扫码添加 / group=群聊添加 )
    source contact_source_enum NOT NULL DEFAULT 'search',

    application_status application_status_enum NOT NULL,
    application_message VARCHAR(256) NOT NULL DEFAULT '',

    reviewed_at BIGINT NOT NULL DEFAULT 0,

    created_at BIGINT NOT NULL,
    updated_at BIGINT NOT NULL
);

COMMENT ON TABLE contact_application_2 IS '联系人申请表 ( 加好友申请 )';
COMMENT ON COLUMN contact_application_2.id IS '主键 ID';
COMMENT ON COLUMN contact_application_2.target_id IS '目标用户 ID';
COMMENT ON COLUMN contact_application_2.applicant_id IS '申请人 ID';
COMMENT ON COLUMN contact_application_2.applicant_name IS '申请人昵称';
COMMENT ON COLUMN contact_application_2.applicant_avatar IS '申请人头像';
COMMENT ON COLUMN contact_application_2.source IS '添加来源 ( search=搜索添加 / qrcode=扫码添加 / group=群聊添加 )';
COMMENT ON COLUMN contact_application_2.application_status IS '申请状态 ( pending=待处理 / approved=已批准 / rejected=已拒绝 )';
COMMENT ON COLUMN contact_application_2.application_message IS '申请验证消息';
COMMENT ON COLUMN contact_application_2.reviewed_at IS '审批时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN contact_application_2.created_at IS '创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN contact_application_2.updated_at IS '更新时间戳 ( Unix 毫秒值 )';

-- 创建索引
CREATE INDEX idx_contact_application_target_2 ON contact_application_2(target_id);

CREATE INDEX idx_contact_application_pending_2 ON contact_application_2(target_id, application_status) WHERE application_status = 'pending';

-- 分表 3: contact_application_3
DROP TABLE IF EXISTS contact_application_3;
CREATE TABLE contact_application_3 (
    id BIGINT PRIMARY KEY,

    target_id BIGINT NOT NULL,

    -- 申请用户信息。
    applicant_id BIGINT NOT NULL,
    applicant_name VARCHAR(128) NOT NULL DEFAULT '',
    applicant_avatar VARCHAR(256) NOT NULL DEFAULT '',

    -- 添加来源 ( search=搜索添加 / qrcode=扫码添加 / group=群聊添加 )
    source contact_source_enum NOT NULL DEFAULT 'search',

    application_status application_status_enum NOT NULL,
    application_message VARCHAR(256) NOT NULL DEFAULT '',

    reviewed_at BIGINT NOT NULL DEFAULT 0,

    created_at BIGINT NOT NULL,
    updated_at BIGINT NOT NULL
);

COMMENT ON TABLE contact_application_3 IS '联系人申请表 ( 加好友申请 )';
COMMENT ON COLUMN contact_application_3.id IS '主键 ID';
COMMENT ON COLUMN contact_application_3.target_id IS '目标用户 ID';
COMMENT ON COLUMN contact_application_3.applicant_id IS '申请人 ID';
COMMENT ON COLUMN contact_application_3.applicant_name IS '申请人昵称';
COMMENT ON COLUMN contact_application_3.applicant_avatar IS '申请人头像';
COMMENT ON COLUMN contact_application_3.source IS '添加来源 ( search=搜索添加 / qrcode=扫码添加 / group=群聊添加 )';
COMMENT ON COLUMN contact_application_3.application_status IS '申请状态 ( pending=待处理 / approved=已批准 / rejected=已拒绝 )';
COMMENT ON COLUMN contact_application_3.application_message IS '申请验证消息';
COMMENT ON COLUMN contact_application_3.reviewed_at IS '审批时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN contact_application_3.created_at IS '创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN contact_application_3.updated_at IS '更新时间戳 ( Unix 毫秒值 )';

-- 创建索引
CREATE INDEX idx_contact_application_target_3 ON contact_application_3(target_id);

CREATE INDEX idx_contact_application_pending_3 ON contact_application_3(target_id, application_status) WHERE application_status = 'pending';

-- ============================================
-- 表: contact_reverse_index (分表数: 4)
-- ============================================

-- 分表 0: contact_reverse_index_0
DROP TABLE IF EXISTS contact_reverse_index_0;
CREATE TABLE contact_reverse_index_0 (
    contact_user_id BIGINT NOT NULL,                        -- 被添加的用户 ID
    owner_user_id BIGINT NOT NULL,                          -- 联系人所有者 ( 谁的联系人 )

    created_at BIGINT NOT NULL,

    PRIMARY KEY(contact_user_id, owner_user_id)
);

COMMENT ON TABLE contact_reverse_index_0 IS '【 反向索引 】联系人反向索引表 ( 用于用户资料变更时，快速查询 "谁的联系人中有某个用户" )';
COMMENT ON COLUMN contact_reverse_index_0.contact_user_id IS '联系人用户 ID ( 被添加的人 )';
COMMENT ON COLUMN contact_reverse_index_0.owner_user_id IS '联系人所有者 ID ( 谁添加了他 )';
COMMENT ON COLUMN contact_reverse_index_0.created_at IS '创建时间戳 ( Unix 毫秒值 )';

-- 创建索引
CREATE INDEX idx_cori_contact_0 ON contact_reverse_index_0(contact_user_id);

-- 分表 1: contact_reverse_index_1
DROP TABLE IF EXISTS contact_reverse_index_1;
CREATE TABLE contact_reverse_index_1 (
    contact_user_id BIGINT NOT NULL,                        -- 被添加的用户 ID
    owner_user_id BIGINT NOT NULL,                          -- 联系人所有者 ( 谁的联系人 )

    created_at BIGINT NOT NULL,

    PRIMARY KEY(contact_user_id, owner_user_id)
);

COMMENT ON TABLE contact_reverse_index_1 IS '【 反向索引 】联系人反向索引表 ( 用于用户资料变更时，快速查询 "谁的联系人中有某个用户" )';
COMMENT ON COLUMN contact_reverse_index_1.contact_user_id IS '联系人用户 ID ( 被添加的人 )';
COMMENT ON COLUMN contact_reverse_index_1.owner_user_id IS '联系人所有者 ID ( 谁添加了他 )';
COMMENT ON COLUMN contact_reverse_index_1.created_at IS '创建时间戳 ( Unix 毫秒值 )';

-- 创建索引
CREATE INDEX idx_cori_contact_1 ON contact_reverse_index_1(contact_user_id);

-- 分表 2: contact_reverse_index_2
DROP TABLE IF EXISTS contact_reverse_index_2;
CREATE TABLE contact_reverse_index_2 (
    contact_user_id BIGINT NOT NULL,                        -- 被添加的用户 ID
    owner_user_id BIGINT NOT NULL,                          -- 联系人所有者 ( 谁的联系人 )

    created_at BIGINT NOT NULL,

    PRIMARY KEY(contact_user_id, owner_user_id)
);

COMMENT ON TABLE contact_reverse_index_2 IS '【 反向索引 】联系人反向索引表 ( 用于用户资料变更时，快速查询 "谁的联系人中有某个用户" )';
COMMENT ON COLUMN contact_reverse_index_2.contact_user_id IS '联系人用户 ID ( 被添加的人 )';
COMMENT ON COLUMN contact_reverse_index_2.owner_user_id IS '联系人所有者 ID ( 谁添加了他 )';
COMMENT ON COLUMN contact_reverse_index_2.created_at IS '创建时间戳 ( Unix 毫秒值 )';

-- 创建索引
CREATE INDEX idx_cori_contact_2 ON contact_reverse_index_2(contact_user_id);

-- 分表 3: contact_reverse_index_3
DROP TABLE IF EXISTS contact_reverse_index_3;
CREATE TABLE contact_reverse_index_3 (
    contact_user_id BIGINT NOT NULL,                        -- 被添加的用户 ID
    owner_user_id BIGINT NOT NULL,                          -- 联系人所有者 ( 谁的联系人 )

    created_at BIGINT NOT NULL,

    PRIMARY KEY(contact_user_id, owner_user_id)
);

COMMENT ON TABLE contact_reverse_index_3 IS '【 反向索引 】联系人反向索引表 ( 用于用户资料变更时，快速查询 "谁的联系人中有某个用户" )';
COMMENT ON COLUMN contact_reverse_index_3.contact_user_id IS '联系人用户 ID ( 被添加的人 )';
COMMENT ON COLUMN contact_reverse_index_3.owner_user_id IS '联系人所有者 ID ( 谁添加了他 )';
COMMENT ON COLUMN contact_reverse_index_3.created_at IS '创建时间戳 ( Unix 毫秒值 )';

-- 创建索引
CREATE INDEX idx_cori_contact_3 ON contact_reverse_index_3(contact_user_id);

-- ============================================
-- 表: conversation_reverse_index (分表数: 4)
-- ============================================

-- 分表 0: conversation_reverse_index_0
DROP TABLE IF EXISTS conversation_reverse_index_0;
CREATE TABLE conversation_reverse_index_0 (
    peer_user_id BIGINT NOT NULL,                           -- 单聊对方用户 ID
    owner_user_id BIGINT NOT NULL,                          -- 会话所有者 ( 谁的会话 )
    channel_id BIGINT NOT NULL,                             -- 频道 ID

    created_at BIGINT NOT NULL,

    PRIMARY KEY(peer_user_id, owner_user_id)
);

COMMENT ON TABLE conversation_reverse_index_0 IS '【 反向索引 】会话反向索引表 ( 用于用户资料变更时，快速查询 "谁的会话中有某个用户" )';
COMMENT ON COLUMN conversation_reverse_index_0.peer_user_id IS '单聊对方用户 ID';
COMMENT ON COLUMN conversation_reverse_index_0.owner_user_id IS '会话所有者 ID';
COMMENT ON COLUMN conversation_reverse_index_0.channel_id IS '频道 ID';
COMMENT ON COLUMN conversation_reverse_index_0.created_at IS '创建时间戳 ( Unix 毫秒值 )';

-- 创建索引
CREATE INDEX idx_cri_peer_0 ON conversation_reverse_index_0(peer_user_id);

-- 分表 1: conversation_reverse_index_1
DROP TABLE IF EXISTS conversation_reverse_index_1;
CREATE TABLE conversation_reverse_index_1 (
    peer_user_id BIGINT NOT NULL,                           -- 单聊对方用户 ID
    owner_user_id BIGINT NOT NULL,                          -- 会话所有者 ( 谁的会话 )
    channel_id BIGINT NOT NULL,                             -- 频道 ID

    created_at BIGINT NOT NULL,

    PRIMARY KEY(peer_user_id, owner_user_id)
);

COMMENT ON TABLE conversation_reverse_index_1 IS '【 反向索引 】会话反向索引表 ( 用于用户资料变更时，快速查询 "谁的会话中有某个用户" )';
COMMENT ON COLUMN conversation_reverse_index_1.peer_user_id IS '单聊对方用户 ID';
COMMENT ON COLUMN conversation_reverse_index_1.owner_user_id IS '会话所有者 ID';
COMMENT ON COLUMN conversation_reverse_index_1.channel_id IS '频道 ID';
COMMENT ON COLUMN conversation_reverse_index_1.created_at IS '创建时间戳 ( Unix 毫秒值 )';

-- 创建索引
CREATE INDEX idx_cri_peer_1 ON conversation_reverse_index_1(peer_user_id);

-- 分表 2: conversation_reverse_index_2
DROP TABLE IF EXISTS conversation_reverse_index_2;
CREATE TABLE conversation_reverse_index_2 (
    peer_user_id BIGINT NOT NULL,                           -- 单聊对方用户 ID
    owner_user_id BIGINT NOT NULL,                          -- 会话所有者 ( 谁的会话 )
    channel_id BIGINT NOT NULL,                             -- 频道 ID

    created_at BIGINT NOT NULL,

    PRIMARY KEY(peer_user_id, owner_user_id)
);

COMMENT ON TABLE conversation_reverse_index_2 IS '【 反向索引 】会话反向索引表 ( 用于用户资料变更时，快速查询 "谁的会话中有某个用户" )';
COMMENT ON COLUMN conversation_reverse_index_2.peer_user_id IS '单聊对方用户 ID';
COMMENT ON COLUMN conversation_reverse_index_2.owner_user_id IS '会话所有者 ID';
COMMENT ON COLUMN conversation_reverse_index_2.channel_id IS '频道 ID';
COMMENT ON COLUMN conversation_reverse_index_2.created_at IS '创建时间戳 ( Unix 毫秒值 )';

-- 创建索引
CREATE INDEX idx_cri_peer_2 ON conversation_reverse_index_2(peer_user_id);

-- 分表 3: conversation_reverse_index_3
DROP TABLE IF EXISTS conversation_reverse_index_3;
CREATE TABLE conversation_reverse_index_3 (
    peer_user_id BIGINT NOT NULL,                           -- 单聊对方用户 ID
    owner_user_id BIGINT NOT NULL,                          -- 会话所有者 ( 谁的会话 )
    channel_id BIGINT NOT NULL,                             -- 频道 ID

    created_at BIGINT NOT NULL,

    PRIMARY KEY(peer_user_id, owner_user_id)
);

COMMENT ON TABLE conversation_reverse_index_3 IS '【 反向索引 】会话反向索引表 ( 用于用户资料变更时，快速查询 "谁的会话中有某个用户" )';
COMMENT ON COLUMN conversation_reverse_index_3.peer_user_id IS '单聊对方用户 ID';
COMMENT ON COLUMN conversation_reverse_index_3.owner_user_id IS '会话所有者 ID';
COMMENT ON COLUMN conversation_reverse_index_3.channel_id IS '频道 ID';
COMMENT ON COLUMN conversation_reverse_index_3.created_at IS '创建时间戳 ( Unix 毫秒值 )';

-- 创建索引
CREATE INDEX idx_cri_peer_3 ON conversation_reverse_index_3(peer_user_id);

-- ============================================
-- 表: user_contact (分表数: 4)
-- ============================================

-- 分表 0: user_contact_0
DROP TABLE IF EXISTS user_contact_0;
CREATE TABLE user_contact_0 (
    id BIGINT PRIMARY KEY,

    user_id BIGINT NOT NULL,
    contact_id BIGINT NOT NULL,

    -- 联系人备注名
    remark_name VARCHAR(64) NOT NULL DEFAULT '',

    -- 添加来源 ( search=搜索添加 / qrcode=扫码添加 / group=群聊添加 )
    source contact_source_enum NOT NULL DEFAULT 'search',

    -- 联系人标签
    tags VARCHAR(128)[] DEFAULT '{}',

    -- 联系人分组
    group_name VARCHAR(32) NOT NULL DEFAULT 'friends',

    -- 状态标记
    is_starred BOOLEAN NOT NULL DEFAULT FALSE,  -- 星标
    is_blocked BOOLEAN NOT NULL DEFAULT FALSE,  -- 黑名单

    added_at BIGINT NOT NULL,
    deleted_at BIGINT NOT NULL DEFAULT 0,

    created_at BIGINT NOT NULL,
    updated_at BIGINT NOT NULL,

    -- 唯一约束
    CONSTRAINT uk_user_contact_0 UNIQUE(user_id, contact_id)
);

COMMENT ON TABLE user_contact_0 IS '【 写入侧 】用户联系人表';
COMMENT ON COLUMN user_contact_0.id IS '主键 ID';
COMMENT ON COLUMN user_contact_0.user_id IS '联系人 ID';
COMMENT ON COLUMN user_contact_0.contact_id IS '联系人 ID';
COMMENT ON COLUMN user_contact_0.remark_name IS '联系人备注名';
COMMENT ON COLUMN user_contact_0.source IS '添加来源 ( search=搜索 / qrcode=扫码 / group=群聊 )';
COMMENT ON COLUMN user_contact_0.tags IS '联系人标签数组';
COMMENT ON COLUMN user_contact_0.group_name IS '联系人分组';
COMMENT ON COLUMN user_contact_0.is_starred IS '是否星标联系人';
COMMENT ON COLUMN user_contact_0.is_blocked IS '是否黑名单联系人';
COMMENT ON COLUMN user_contact_0.added_at IS '添加时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN user_contact_0.deleted_at IS '删除时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN user_contact_0.created_at IS '创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN user_contact_0.updated_at IS '更新时间戳 ( Unix 毫秒值 )';

-- 创建索引
CREATE INDEX idx_user_contact_user_0 ON user_contact_0(user_id);

CREATE INDEX idx_user_contact_user_active_0 ON user_contact_0(user_id, deleted_at) WHERE deleted_at = 0;

CREATE INDEX idx_user_contact_user_starred_0 ON user_contact_0(user_id, is_starred) WHERE is_starred = TRUE AND deleted_at = 0;

-- 分表 1: user_contact_1
DROP TABLE IF EXISTS user_contact_1;
CREATE TABLE user_contact_1 (
    id BIGINT PRIMARY KEY,

    user_id BIGINT NOT NULL,
    contact_id BIGINT NOT NULL,

    -- 联系人备注名
    remark_name VARCHAR(64) NOT NULL DEFAULT '',

    -- 添加来源 ( search=搜索添加 / qrcode=扫码添加 / group=群聊添加 )
    source contact_source_enum NOT NULL DEFAULT 'search',

    -- 联系人标签
    tags VARCHAR(128)[] DEFAULT '{}',

    -- 联系人分组
    group_name VARCHAR(32) NOT NULL DEFAULT 'friends',

    -- 状态标记
    is_starred BOOLEAN NOT NULL DEFAULT FALSE,  -- 星标
    is_blocked BOOLEAN NOT NULL DEFAULT FALSE,  -- 黑名单

    added_at BIGINT NOT NULL,
    deleted_at BIGINT NOT NULL DEFAULT 0,

    created_at BIGINT NOT NULL,
    updated_at BIGINT NOT NULL,

    -- 唯一约束
    CONSTRAINT uk_user_contact_1 UNIQUE(user_id, contact_id)
);

COMMENT ON TABLE user_contact_1 IS '【 写入侧 】用户联系人表';
COMMENT ON COLUMN user_contact_1.id IS '主键 ID';
COMMENT ON COLUMN user_contact_1.user_id IS '联系人 ID';
COMMENT ON COLUMN user_contact_1.contact_id IS '联系人 ID';
COMMENT ON COLUMN user_contact_1.remark_name IS '联系人备注名';
COMMENT ON COLUMN user_contact_1.source IS '添加来源 ( search=搜索 / qrcode=扫码 / group=群聊 )';
COMMENT ON COLUMN user_contact_1.tags IS '联系人标签数组';
COMMENT ON COLUMN user_contact_1.group_name IS '联系人分组';
COMMENT ON COLUMN user_contact_1.is_starred IS '是否星标联系人';
COMMENT ON COLUMN user_contact_1.is_blocked IS '是否黑名单联系人';
COMMENT ON COLUMN user_contact_1.added_at IS '添加时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN user_contact_1.deleted_at IS '删除时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN user_contact_1.created_at IS '创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN user_contact_1.updated_at IS '更新时间戳 ( Unix 毫秒值 )';

-- 创建索引
CREATE INDEX idx_user_contact_user_1 ON user_contact_1(user_id);

CREATE INDEX idx_user_contact_user_active_1 ON user_contact_1(user_id, deleted_at) WHERE deleted_at = 0;

CREATE INDEX idx_user_contact_user_starred_1 ON user_contact_1(user_id, is_starred) WHERE is_starred = TRUE AND deleted_at = 0;

-- 分表 2: user_contact_2
DROP TABLE IF EXISTS user_contact_2;
CREATE TABLE user_contact_2 (
    id BIGINT PRIMARY KEY,

    user_id BIGINT NOT NULL,
    contact_id BIGINT NOT NULL,

    -- 联系人备注名
    remark_name VARCHAR(64) NOT NULL DEFAULT '',

    -- 添加来源 ( search=搜索添加 / qrcode=扫码添加 / group=群聊添加 )
    source contact_source_enum NOT NULL DEFAULT 'search',

    -- 联系人标签
    tags VARCHAR(128)[] DEFAULT '{}',

    -- 联系人分组
    group_name VARCHAR(32) NOT NULL DEFAULT 'friends',

    -- 状态标记
    is_starred BOOLEAN NOT NULL DEFAULT FALSE,  -- 星标
    is_blocked BOOLEAN NOT NULL DEFAULT FALSE,  -- 黑名单

    added_at BIGINT NOT NULL,
    deleted_at BIGINT NOT NULL DEFAULT 0,

    created_at BIGINT NOT NULL,
    updated_at BIGINT NOT NULL,

    -- 唯一约束
    CONSTRAINT uk_user_contact_2 UNIQUE(user_id, contact_id)
);

COMMENT ON TABLE user_contact_2 IS '【 写入侧 】用户联系人表';
COMMENT ON COLUMN user_contact_2.id IS '主键 ID';
COMMENT ON COLUMN user_contact_2.user_id IS '联系人 ID';
COMMENT ON COLUMN user_contact_2.contact_id IS '联系人 ID';
COMMENT ON COLUMN user_contact_2.remark_name IS '联系人备注名';
COMMENT ON COLUMN user_contact_2.source IS '添加来源 ( search=搜索 / qrcode=扫码 / group=群聊 )';
COMMENT ON COLUMN user_contact_2.tags IS '联系人标签数组';
COMMENT ON COLUMN user_contact_2.group_name IS '联系人分组';
COMMENT ON COLUMN user_contact_2.is_starred IS '是否星标联系人';
COMMENT ON COLUMN user_contact_2.is_blocked IS '是否黑名单联系人';
COMMENT ON COLUMN user_contact_2.added_at IS '添加时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN user_contact_2.deleted_at IS '删除时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN user_contact_2.created_at IS '创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN user_contact_2.updated_at IS '更新时间戳 ( Unix 毫秒值 )';

-- 创建索引
CREATE INDEX idx_user_contact_user_2 ON user_contact_2(user_id);

CREATE INDEX idx_user_contact_user_active_2 ON user_contact_2(user_id, deleted_at) WHERE deleted_at = 0;

CREATE INDEX idx_user_contact_user_starred_2 ON user_contact_2(user_id, is_starred) WHERE is_starred = TRUE AND deleted_at = 0;

-- 分表 3: user_contact_3
DROP TABLE IF EXISTS user_contact_3;
CREATE TABLE user_contact_3 (
    id BIGINT PRIMARY KEY,

    user_id BIGINT NOT NULL,
    contact_id BIGINT NOT NULL,

    -- 联系人备注名
    remark_name VARCHAR(64) NOT NULL DEFAULT '',

    -- 添加来源 ( search=搜索添加 / qrcode=扫码添加 / group=群聊添加 )
    source contact_source_enum NOT NULL DEFAULT 'search',

    -- 联系人标签
    tags VARCHAR(128)[] DEFAULT '{}',

    -- 联系人分组
    group_name VARCHAR(32) NOT NULL DEFAULT 'friends',

    -- 状态标记
    is_starred BOOLEAN NOT NULL DEFAULT FALSE,  -- 星标
    is_blocked BOOLEAN NOT NULL DEFAULT FALSE,  -- 黑名单

    added_at BIGINT NOT NULL,
    deleted_at BIGINT NOT NULL DEFAULT 0,

    created_at BIGINT NOT NULL,
    updated_at BIGINT NOT NULL,

    -- 唯一约束
    CONSTRAINT uk_user_contact_3 UNIQUE(user_id, contact_id)
);

COMMENT ON TABLE user_contact_3 IS '【 写入侧 】用户联系人表';
COMMENT ON COLUMN user_contact_3.id IS '主键 ID';
COMMENT ON COLUMN user_contact_3.user_id IS '联系人 ID';
COMMENT ON COLUMN user_contact_3.contact_id IS '联系人 ID';
COMMENT ON COLUMN user_contact_3.remark_name IS '联系人备注名';
COMMENT ON COLUMN user_contact_3.source IS '添加来源 ( search=搜索 / qrcode=扫码 / group=群聊 )';
COMMENT ON COLUMN user_contact_3.tags IS '联系人标签数组';
COMMENT ON COLUMN user_contact_3.group_name IS '联系人分组';
COMMENT ON COLUMN user_contact_3.is_starred IS '是否星标联系人';
COMMENT ON COLUMN user_contact_3.is_blocked IS '是否黑名单联系人';
COMMENT ON COLUMN user_contact_3.added_at IS '添加时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN user_contact_3.deleted_at IS '删除时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN user_contact_3.created_at IS '创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN user_contact_3.updated_at IS '更新时间戳 ( Unix 毫秒值 )';

-- 创建索引
CREATE INDEX idx_user_contact_user_3 ON user_contact_3(user_id);

CREATE INDEX idx_user_contact_user_active_3 ON user_contact_3(user_id, deleted_at) WHERE deleted_at = 0;

CREATE INDEX idx_user_contact_user_starred_3 ON user_contact_3(user_id, is_starred) WHERE is_starred = TRUE AND deleted_at = 0;

-- ============================================
-- 表: user_contact_view (分表数: 4)
-- ============================================

-- 分表 0: user_contact_view_0
DROP TABLE IF EXISTS user_contact_view_0;
CREATE TABLE user_contact_view_0 (
    id BIGINT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    contact_id BIGINT NOT NULL,                                 -- 联系人 user_id

    -- 联系人信息 ( 冗余自 user 表 )
    contact_nickname VARCHAR(64) NOT NULL DEFAULT '',           -- 联系人昵称 ( 冗余 )
    contact_avatar VARCHAR(256) NOT NULL DEFAULT '',            -- 联系人头像 ( 冗余 )
    contact_info_ver INT NOT NULL DEFAULT 1,                    -- 【 CQRS 关键字段 】联系人信息版本号 ( 用于同步检测 )

    -- 好友关系信息 ( 冗余自 user_contact 表 )
    remark_name VARCHAR(64) NOT NULL DEFAULT '',                -- 备注名
    group_name VARCHAR(32) NOT NULL DEFAULT 'friends',          -- 分组名
    tags VARCHAR(128)[] DEFAULT '{}',                           -- 标签

    -- 状态
    is_starred BOOLEAN NOT NULL DEFAULT FALSE,                  -- 星标
    is_blocked BOOLEAN NOT NULL DEFAULT FALSE,                  -- 黑名单

    -- 扩展信息 ( 可选，冗余自 user 表 )
    mobile VARCHAR(16) NOT NULL DEFAULT '',                     -- 手机号
    source contact_source_enum NOT NULL DEFAULT 'search',       -- 添加来源 ( search=搜索 / qrcode=扫码 / group=群聊 )

    added_at BIGINT NOT NULL,
    deleted_at BIGINT NOT NULL DEFAULT 0,

    created_at BIGINT NOT NULL,
    updated_at BIGINT NOT NULL,

    -- 唯一约束
    CONSTRAINT uk_user_contact_view_0 UNIQUE(user_id, contact_id)
);

COMMENT ON TABLE user_contact_view_0 IS '【 读取侧 】用户联系人视图表 ( 用于通讯录展示，冗余数据 )';
COMMENT ON COLUMN user_contact_view_0.id IS '主键 ID';
COMMENT ON COLUMN user_contact_view_0.user_id IS '用户 ID';
COMMENT ON COLUMN user_contact_view_0.contact_id IS '联系人 ID ( 好友 ID )';
COMMENT ON COLUMN user_contact_view_0.contact_nickname IS '联系人昵称 ( 冗余自 user 表 )';
COMMENT ON COLUMN user_contact_view_0.contact_avatar IS '联系人头像 ( 冗余自 user 表 )';
COMMENT ON COLUMN user_contact_view_0.contact_info_ver IS '【 CQRS 关键字段 】联系人信息版本号 ( 用于同步检测 )';
COMMENT ON COLUMN user_contact_view_0.remark_name IS '备注名';
COMMENT ON COLUMN user_contact_view_0.group_name IS '分组名';
COMMENT ON COLUMN user_contact_view_0.tags IS '标签数组';
COMMENT ON COLUMN user_contact_view_0.is_starred IS '是否星标';
COMMENT ON COLUMN user_contact_view_0.is_blocked IS '是否拉黑';
COMMENT ON COLUMN user_contact_view_0.mobile IS '手机号 ( 冗余 )';
COMMENT ON COLUMN user_contact_view_0.source IS '添加来源';
COMMENT ON COLUMN user_contact_view_0.added_at IS '添加时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN user_contact_view_0.deleted_at IS '删除时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN user_contact_view_0.created_at IS '创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN user_contact_view_0.updated_at IS '更新时间戳 ( Unix 毫秒值 )';

-- 创建索引
CREATE INDEX idx_ucov_list_0 ON user_contact_view_0(
    user_id,
    is_starred DESC,
    contact_nickname
) WHERE deleted_at = 0;

CREATE INDEX idx_ucov_group_0 ON user_contact_view_0(
    user_id,
    group_name,
    contact_nickname
) WHERE deleted_at = 0;

CREATE INDEX idx_ucov_starred_0 ON user_contact_view_0(
    user_id,
    contact_nickname
) WHERE is_starred = TRUE AND deleted_at = 0;

CREATE INDEX idx_ucov_initial_0 ON user_contact_view_0(
    user_id,
    LEFT(contact_nickname, 1),
    contact_nickname
) WHERE deleted_at = 0;

-- 分表 1: user_contact_view_1
DROP TABLE IF EXISTS user_contact_view_1;
CREATE TABLE user_contact_view_1 (
    id BIGINT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    contact_id BIGINT NOT NULL,                                 -- 联系人 user_id

    -- 联系人信息 ( 冗余自 user 表 )
    contact_nickname VARCHAR(64) NOT NULL DEFAULT '',           -- 联系人昵称 ( 冗余 )
    contact_avatar VARCHAR(256) NOT NULL DEFAULT '',            -- 联系人头像 ( 冗余 )
    contact_info_ver INT NOT NULL DEFAULT 1,                    -- 【 CQRS 关键字段 】联系人信息版本号 ( 用于同步检测 )

    -- 好友关系信息 ( 冗余自 user_contact 表 )
    remark_name VARCHAR(64) NOT NULL DEFAULT '',                -- 备注名
    group_name VARCHAR(32) NOT NULL DEFAULT 'friends',          -- 分组名
    tags VARCHAR(128)[] DEFAULT '{}',                           -- 标签

    -- 状态
    is_starred BOOLEAN NOT NULL DEFAULT FALSE,                  -- 星标
    is_blocked BOOLEAN NOT NULL DEFAULT FALSE,                  -- 黑名单

    -- 扩展信息 ( 可选，冗余自 user 表 )
    mobile VARCHAR(16) NOT NULL DEFAULT '',                     -- 手机号
    source contact_source_enum NOT NULL DEFAULT 'search',       -- 添加来源 ( search=搜索 / qrcode=扫码 / group=群聊 )

    added_at BIGINT NOT NULL,
    deleted_at BIGINT NOT NULL DEFAULT 0,

    created_at BIGINT NOT NULL,
    updated_at BIGINT NOT NULL,

    -- 唯一约束
    CONSTRAINT uk_user_contact_view_1 UNIQUE(user_id, contact_id)
);

COMMENT ON TABLE user_contact_view_1 IS '【 读取侧 】用户联系人视图表 ( 用于通讯录展示，冗余数据 )';
COMMENT ON COLUMN user_contact_view_1.id IS '主键 ID';
COMMENT ON COLUMN user_contact_view_1.user_id IS '用户 ID';
COMMENT ON COLUMN user_contact_view_1.contact_id IS '联系人 ID ( 好友 ID )';
COMMENT ON COLUMN user_contact_view_1.contact_nickname IS '联系人昵称 ( 冗余自 user 表 )';
COMMENT ON COLUMN user_contact_view_1.contact_avatar IS '联系人头像 ( 冗余自 user 表 )';
COMMENT ON COLUMN user_contact_view_1.contact_info_ver IS '【 CQRS 关键字段 】联系人信息版本号 ( 用于同步检测 )';
COMMENT ON COLUMN user_contact_view_1.remark_name IS '备注名';
COMMENT ON COLUMN user_contact_view_1.group_name IS '分组名';
COMMENT ON COLUMN user_contact_view_1.tags IS '标签数组';
COMMENT ON COLUMN user_contact_view_1.is_starred IS '是否星标';
COMMENT ON COLUMN user_contact_view_1.is_blocked IS '是否拉黑';
COMMENT ON COLUMN user_contact_view_1.mobile IS '手机号 ( 冗余 )';
COMMENT ON COLUMN user_contact_view_1.source IS '添加来源';
COMMENT ON COLUMN user_contact_view_1.added_at IS '添加时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN user_contact_view_1.deleted_at IS '删除时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN user_contact_view_1.created_at IS '创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN user_contact_view_1.updated_at IS '更新时间戳 ( Unix 毫秒值 )';

-- 创建索引
CREATE INDEX idx_ucov_list_1 ON user_contact_view_1(
    user_id,
    is_starred DESC,
    contact_nickname
) WHERE deleted_at = 0;

CREATE INDEX idx_ucov_group_1 ON user_contact_view_1(
    user_id,
    group_name,
    contact_nickname
) WHERE deleted_at = 0;

CREATE INDEX idx_ucov_starred_1 ON user_contact_view_1(
    user_id,
    contact_nickname
) WHERE is_starred = TRUE AND deleted_at = 0;

CREATE INDEX idx_ucov_initial_1 ON user_contact_view_1(
    user_id,
    LEFT(contact_nickname, 1),
    contact_nickname
) WHERE deleted_at = 0;

-- 分表 2: user_contact_view_2
DROP TABLE IF EXISTS user_contact_view_2;
CREATE TABLE user_contact_view_2 (
    id BIGINT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    contact_id BIGINT NOT NULL,                                 -- 联系人 user_id

    -- 联系人信息 ( 冗余自 user 表 )
    contact_nickname VARCHAR(64) NOT NULL DEFAULT '',           -- 联系人昵称 ( 冗余 )
    contact_avatar VARCHAR(256) NOT NULL DEFAULT '',            -- 联系人头像 ( 冗余 )
    contact_info_ver INT NOT NULL DEFAULT 1,                    -- 【 CQRS 关键字段 】联系人信息版本号 ( 用于同步检测 )

    -- 好友关系信息 ( 冗余自 user_contact 表 )
    remark_name VARCHAR(64) NOT NULL DEFAULT '',                -- 备注名
    group_name VARCHAR(32) NOT NULL DEFAULT 'friends',          -- 分组名
    tags VARCHAR(128)[] DEFAULT '{}',                           -- 标签

    -- 状态
    is_starred BOOLEAN NOT NULL DEFAULT FALSE,                  -- 星标
    is_blocked BOOLEAN NOT NULL DEFAULT FALSE,                  -- 黑名单

    -- 扩展信息 ( 可选，冗余自 user 表 )
    mobile VARCHAR(16) NOT NULL DEFAULT '',                     -- 手机号
    source contact_source_enum NOT NULL DEFAULT 'search',       -- 添加来源 ( search=搜索 / qrcode=扫码 / group=群聊 )

    added_at BIGINT NOT NULL,
    deleted_at BIGINT NOT NULL DEFAULT 0,

    created_at BIGINT NOT NULL,
    updated_at BIGINT NOT NULL,

    -- 唯一约束
    CONSTRAINT uk_user_contact_view_2 UNIQUE(user_id, contact_id)
);

COMMENT ON TABLE user_contact_view_2 IS '【 读取侧 】用户联系人视图表 ( 用于通讯录展示，冗余数据 )';
COMMENT ON COLUMN user_contact_view_2.id IS '主键 ID';
COMMENT ON COLUMN user_contact_view_2.user_id IS '用户 ID';
COMMENT ON COLUMN user_contact_view_2.contact_id IS '联系人 ID ( 好友 ID )';
COMMENT ON COLUMN user_contact_view_2.contact_nickname IS '联系人昵称 ( 冗余自 user 表 )';
COMMENT ON COLUMN user_contact_view_2.contact_avatar IS '联系人头像 ( 冗余自 user 表 )';
COMMENT ON COLUMN user_contact_view_2.contact_info_ver IS '【 CQRS 关键字段 】联系人信息版本号 ( 用于同步检测 )';
COMMENT ON COLUMN user_contact_view_2.remark_name IS '备注名';
COMMENT ON COLUMN user_contact_view_2.group_name IS '分组名';
COMMENT ON COLUMN user_contact_view_2.tags IS '标签数组';
COMMENT ON COLUMN user_contact_view_2.is_starred IS '是否星标';
COMMENT ON COLUMN user_contact_view_2.is_blocked IS '是否拉黑';
COMMENT ON COLUMN user_contact_view_2.mobile IS '手机号 ( 冗余 )';
COMMENT ON COLUMN user_contact_view_2.source IS '添加来源';
COMMENT ON COLUMN user_contact_view_2.added_at IS '添加时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN user_contact_view_2.deleted_at IS '删除时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN user_contact_view_2.created_at IS '创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN user_contact_view_2.updated_at IS '更新时间戳 ( Unix 毫秒值 )';

-- 创建索引
CREATE INDEX idx_ucov_list_2 ON user_contact_view_2(
    user_id,
    is_starred DESC,
    contact_nickname
) WHERE deleted_at = 0;

CREATE INDEX idx_ucov_group_2 ON user_contact_view_2(
    user_id,
    group_name,
    contact_nickname
) WHERE deleted_at = 0;

CREATE INDEX idx_ucov_starred_2 ON user_contact_view_2(
    user_id,
    contact_nickname
) WHERE is_starred = TRUE AND deleted_at = 0;

CREATE INDEX idx_ucov_initial_2 ON user_contact_view_2(
    user_id,
    LEFT(contact_nickname, 1),
    contact_nickname
) WHERE deleted_at = 0;

-- 分表 3: user_contact_view_3
DROP TABLE IF EXISTS user_contact_view_3;
CREATE TABLE user_contact_view_3 (
    id BIGINT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    contact_id BIGINT NOT NULL,                                 -- 联系人 user_id

    -- 联系人信息 ( 冗余自 user 表 )
    contact_nickname VARCHAR(64) NOT NULL DEFAULT '',           -- 联系人昵称 ( 冗余 )
    contact_avatar VARCHAR(256) NOT NULL DEFAULT '',            -- 联系人头像 ( 冗余 )
    contact_info_ver INT NOT NULL DEFAULT 1,                    -- 【 CQRS 关键字段 】联系人信息版本号 ( 用于同步检测 )

    -- 好友关系信息 ( 冗余自 user_contact 表 )
    remark_name VARCHAR(64) NOT NULL DEFAULT '',                -- 备注名
    group_name VARCHAR(32) NOT NULL DEFAULT 'friends',          -- 分组名
    tags VARCHAR(128)[] DEFAULT '{}',                           -- 标签

    -- 状态
    is_starred BOOLEAN NOT NULL DEFAULT FALSE,                  -- 星标
    is_blocked BOOLEAN NOT NULL DEFAULT FALSE,                  -- 黑名单

    -- 扩展信息 ( 可选，冗余自 user 表 )
    mobile VARCHAR(16) NOT NULL DEFAULT '',                     -- 手机号
    source contact_source_enum NOT NULL DEFAULT 'search',       -- 添加来源 ( search=搜索 / qrcode=扫码 / group=群聊 )

    added_at BIGINT NOT NULL,
    deleted_at BIGINT NOT NULL DEFAULT 0,

    created_at BIGINT NOT NULL,
    updated_at BIGINT NOT NULL,

    -- 唯一约束
    CONSTRAINT uk_user_contact_view_3 UNIQUE(user_id, contact_id)
);

COMMENT ON TABLE user_contact_view_3 IS '【 读取侧 】用户联系人视图表 ( 用于通讯录展示，冗余数据 )';
COMMENT ON COLUMN user_contact_view_3.id IS '主键 ID';
COMMENT ON COLUMN user_contact_view_3.user_id IS '用户 ID';
COMMENT ON COLUMN user_contact_view_3.contact_id IS '联系人 ID ( 好友 ID )';
COMMENT ON COLUMN user_contact_view_3.contact_nickname IS '联系人昵称 ( 冗余自 user 表 )';
COMMENT ON COLUMN user_contact_view_3.contact_avatar IS '联系人头像 ( 冗余自 user 表 )';
COMMENT ON COLUMN user_contact_view_3.contact_info_ver IS '【 CQRS 关键字段 】联系人信息版本号 ( 用于同步检测 )';
COMMENT ON COLUMN user_contact_view_3.remark_name IS '备注名';
COMMENT ON COLUMN user_contact_view_3.group_name IS '分组名';
COMMENT ON COLUMN user_contact_view_3.tags IS '标签数组';
COMMENT ON COLUMN user_contact_view_3.is_starred IS '是否星标';
COMMENT ON COLUMN user_contact_view_3.is_blocked IS '是否拉黑';
COMMENT ON COLUMN user_contact_view_3.mobile IS '手机号 ( 冗余 )';
COMMENT ON COLUMN user_contact_view_3.source IS '添加来源';
COMMENT ON COLUMN user_contact_view_3.added_at IS '添加时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN user_contact_view_3.deleted_at IS '删除时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN user_contact_view_3.created_at IS '创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN user_contact_view_3.updated_at IS '更新时间戳 ( Unix 毫秒值 )';

-- 创建索引
CREATE INDEX idx_ucov_list_3 ON user_contact_view_3(
    user_id,
    is_starred DESC,
    contact_nickname
) WHERE deleted_at = 0;

CREATE INDEX idx_ucov_group_3 ON user_contact_view_3(
    user_id,
    group_name,
    contact_nickname
) WHERE deleted_at = 0;

CREATE INDEX idx_ucov_starred_3 ON user_contact_view_3(
    user_id,
    contact_nickname
) WHERE is_starred = TRUE AND deleted_at = 0;

CREATE INDEX idx_ucov_initial_3 ON user_contact_view_3(
    user_id,
    LEFT(contact_nickname, 1),
    contact_nickname
) WHERE deleted_at = 0;

-- ============================================
-- 表: user_conversation_view (分表数: 4)
-- ============================================

-- 分表 0: user_conversation_view_0
DROP TABLE IF EXISTS user_conversation_view_0;
CREATE TABLE user_conversation_view_0 (
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
    CONSTRAINT uk_user_conversation_0 UNIQUE(user_id, channel_id),

    -- 检查约束：单聊时必须有 peer_user_id
    CONSTRAINT chk_conversation_peer_0 CHECK (
        (conversation_type = 'single' AND peer_user_id IS NOT NULL)
        OR
        (conversation_type = 'group' AND peer_user_id IS NULL)
    )
);

COMMENT ON TABLE user_conversation_view_0 IS '【 读取侧 】用户会话视图表 ( 用于会话列表展示，冗余数据 )';
COMMENT ON COLUMN user_conversation_view_0.id IS '主键 ID';
COMMENT ON COLUMN user_conversation_view_0.user_id IS '用户 ID';
COMMENT ON COLUMN user_conversation_view_0.channel_id IS '频道 ID';
COMMENT ON COLUMN user_conversation_view_0.conversation_type IS '会话类型 ( single=单聊 / group=群聊 )';
COMMENT ON COLUMN user_conversation_view_0.conversation_name IS '会话显示名称 ( 单聊：备注名>昵称 / 群聊：群名 )';
COMMENT ON COLUMN user_conversation_view_0.conversation_avatar IS '会话显示头像 ( 单聊：对方头像，群聊：群头像 )';
COMMENT ON COLUMN user_conversation_view_0.conversation_info_ver IS '【 CQRS 关键字段 】会话信息版本号 ( 用于同步检测 )';
COMMENT ON COLUMN user_conversation_view_0.peer_user_id IS '单聊对方用户 ID ( 仅单聊有值 )';
COMMENT ON COLUMN user_conversation_view_0.peer_nickname IS '对方昵称 ( 冗余自 user 表 )';
COMMENT ON COLUMN user_conversation_view_0.peer_avatar IS '对方头像 ( 冗余自 user 表 )';
COMMENT ON COLUMN user_conversation_view_0.remark_name IS '好友备注名';
COMMENT ON COLUMN user_conversation_view_0.is_muted IS '是否免打扰';
COMMENT ON COLUMN user_conversation_view_0.is_pinned IS '是否置顶';
COMMENT ON COLUMN user_conversation_view_0.is_hidden IS '是否隐藏';
COMMENT ON COLUMN user_conversation_view_0.is_starred IS '是否星标 ( 仅单聊 )';
COMMENT ON COLUMN user_conversation_view_0.last_message_id IS '最后消息 ID';
COMMENT ON COLUMN user_conversation_view_0.last_message_type IS '最后消息类型';
COMMENT ON COLUMN user_conversation_view_0.last_message_content IS '最后消息内容摘要';
COMMENT ON COLUMN user_conversation_view_0.last_message_sender_id IS '最后消息发送者 ID';
COMMENT ON COLUMN user_conversation_view_0.last_message_sender_name IS '最后消息发送者昵称';
COMMENT ON COLUMN user_conversation_view_0.last_message_time IS '最后消息时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN user_conversation_view_0.unread_count IS '未读消息数';
COMMENT ON COLUMN user_conversation_view_0.mention_count IS '@我的消息数';
COMMENT ON COLUMN user_conversation_view_0.opened_at IS '会话创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN user_conversation_view_0.closed_at IS '会话删除时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN user_conversation_view_0.created_at IS '创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN user_conversation_view_0.updated_at IS '更新时间戳 ( Unix 毫秒值 )';

-- 创建索引
CREATE INDEX idx_ucv_list_0 ON user_conversation_view_0(
    user_id,
    is_pinned DESC,
    last_message_time DESC
) WHERE closed_at = 0 AND is_hidden = FALSE;

CREATE INDEX idx_ucv_pinned_0 ON user_conversation_view_0(
    user_id,
    last_message_time DESC
) WHERE is_pinned = TRUE AND closed_at = 0;

CREATE INDEX idx_ucv_type_0 ON user_conversation_view_0(
    user_id,
    conversation_type,
    last_message_time DESC
) WHERE closed_at = 0;

CREATE INDEX idx_ucv_unread_0 ON user_conversation_view_0(
    user_id,
    unread_count DESC,
    last_message_time DESC
) WHERE unread_count > 0 AND closed_at = 0;

CREATE INDEX idx_ucv_peer_0 ON user_conversation_view_0(user_id, peer_user_id)
    WHERE conversation_type = 'single';

-- 分表 1: user_conversation_view_1
DROP TABLE IF EXISTS user_conversation_view_1;
CREATE TABLE user_conversation_view_1 (
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
    CONSTRAINT uk_user_conversation_1 UNIQUE(user_id, channel_id),

    -- 检查约束：单聊时必须有 peer_user_id
    CONSTRAINT chk_conversation_peer_1 CHECK (
        (conversation_type = 'single' AND peer_user_id IS NOT NULL)
        OR
        (conversation_type = 'group' AND peer_user_id IS NULL)
    )
);

COMMENT ON TABLE user_conversation_view_1 IS '【 读取侧 】用户会话视图表 ( 用于会话列表展示，冗余数据 )';
COMMENT ON COLUMN user_conversation_view_1.id IS '主键 ID';
COMMENT ON COLUMN user_conversation_view_1.user_id IS '用户 ID';
COMMENT ON COLUMN user_conversation_view_1.channel_id IS '频道 ID';
COMMENT ON COLUMN user_conversation_view_1.conversation_type IS '会话类型 ( single=单聊 / group=群聊 )';
COMMENT ON COLUMN user_conversation_view_1.conversation_name IS '会话显示名称 ( 单聊：备注名>昵称 / 群聊：群名 )';
COMMENT ON COLUMN user_conversation_view_1.conversation_avatar IS '会话显示头像 ( 单聊：对方头像，群聊：群头像 )';
COMMENT ON COLUMN user_conversation_view_1.conversation_info_ver IS '【 CQRS 关键字段 】会话信息版本号 ( 用于同步检测 )';
COMMENT ON COLUMN user_conversation_view_1.peer_user_id IS '单聊对方用户 ID ( 仅单聊有值 )';
COMMENT ON COLUMN user_conversation_view_1.peer_nickname IS '对方昵称 ( 冗余自 user 表 )';
COMMENT ON COLUMN user_conversation_view_1.peer_avatar IS '对方头像 ( 冗余自 user 表 )';
COMMENT ON COLUMN user_conversation_view_1.remark_name IS '好友备注名';
COMMENT ON COLUMN user_conversation_view_1.is_muted IS '是否免打扰';
COMMENT ON COLUMN user_conversation_view_1.is_pinned IS '是否置顶';
COMMENT ON COLUMN user_conversation_view_1.is_hidden IS '是否隐藏';
COMMENT ON COLUMN user_conversation_view_1.is_starred IS '是否星标 ( 仅单聊 )';
COMMENT ON COLUMN user_conversation_view_1.last_message_id IS '最后消息 ID';
COMMENT ON COLUMN user_conversation_view_1.last_message_type IS '最后消息类型';
COMMENT ON COLUMN user_conversation_view_1.last_message_content IS '最后消息内容摘要';
COMMENT ON COLUMN user_conversation_view_1.last_message_sender_id IS '最后消息发送者 ID';
COMMENT ON COLUMN user_conversation_view_1.last_message_sender_name IS '最后消息发送者昵称';
COMMENT ON COLUMN user_conversation_view_1.last_message_time IS '最后消息时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN user_conversation_view_1.unread_count IS '未读消息数';
COMMENT ON COLUMN user_conversation_view_1.mention_count IS '@我的消息数';
COMMENT ON COLUMN user_conversation_view_1.opened_at IS '会话创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN user_conversation_view_1.closed_at IS '会话删除时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN user_conversation_view_1.created_at IS '创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN user_conversation_view_1.updated_at IS '更新时间戳 ( Unix 毫秒值 )';

-- 创建索引
CREATE INDEX idx_ucv_list_1 ON user_conversation_view_1(
    user_id,
    is_pinned DESC,
    last_message_time DESC
) WHERE closed_at = 0 AND is_hidden = FALSE;

CREATE INDEX idx_ucv_pinned_1 ON user_conversation_view_1(
    user_id,
    last_message_time DESC
) WHERE is_pinned = TRUE AND closed_at = 0;

CREATE INDEX idx_ucv_type_1 ON user_conversation_view_1(
    user_id,
    conversation_type,
    last_message_time DESC
) WHERE closed_at = 0;

CREATE INDEX idx_ucv_unread_1 ON user_conversation_view_1(
    user_id,
    unread_count DESC,
    last_message_time DESC
) WHERE unread_count > 0 AND closed_at = 0;

CREATE INDEX idx_ucv_peer_1 ON user_conversation_view_1(user_id, peer_user_id)
    WHERE conversation_type = 'single';

-- 分表 2: user_conversation_view_2
DROP TABLE IF EXISTS user_conversation_view_2;
CREATE TABLE user_conversation_view_2 (
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
    CONSTRAINT uk_user_conversation_2 UNIQUE(user_id, channel_id),

    -- 检查约束：单聊时必须有 peer_user_id
    CONSTRAINT chk_conversation_peer_2 CHECK (
        (conversation_type = 'single' AND peer_user_id IS NOT NULL)
        OR
        (conversation_type = 'group' AND peer_user_id IS NULL)
    )
);

COMMENT ON TABLE user_conversation_view_2 IS '【 读取侧 】用户会话视图表 ( 用于会话列表展示，冗余数据 )';
COMMENT ON COLUMN user_conversation_view_2.id IS '主键 ID';
COMMENT ON COLUMN user_conversation_view_2.user_id IS '用户 ID';
COMMENT ON COLUMN user_conversation_view_2.channel_id IS '频道 ID';
COMMENT ON COLUMN user_conversation_view_2.conversation_type IS '会话类型 ( single=单聊 / group=群聊 )';
COMMENT ON COLUMN user_conversation_view_2.conversation_name IS '会话显示名称 ( 单聊：备注名>昵称 / 群聊：群名 )';
COMMENT ON COLUMN user_conversation_view_2.conversation_avatar IS '会话显示头像 ( 单聊：对方头像，群聊：群头像 )';
COMMENT ON COLUMN user_conversation_view_2.conversation_info_ver IS '【 CQRS 关键字段 】会话信息版本号 ( 用于同步检测 )';
COMMENT ON COLUMN user_conversation_view_2.peer_user_id IS '单聊对方用户 ID ( 仅单聊有值 )';
COMMENT ON COLUMN user_conversation_view_2.peer_nickname IS '对方昵称 ( 冗余自 user 表 )';
COMMENT ON COLUMN user_conversation_view_2.peer_avatar IS '对方头像 ( 冗余自 user 表 )';
COMMENT ON COLUMN user_conversation_view_2.remark_name IS '好友备注名';
COMMENT ON COLUMN user_conversation_view_2.is_muted IS '是否免打扰';
COMMENT ON COLUMN user_conversation_view_2.is_pinned IS '是否置顶';
COMMENT ON COLUMN user_conversation_view_2.is_hidden IS '是否隐藏';
COMMENT ON COLUMN user_conversation_view_2.is_starred IS '是否星标 ( 仅单聊 )';
COMMENT ON COLUMN user_conversation_view_2.last_message_id IS '最后消息 ID';
COMMENT ON COLUMN user_conversation_view_2.last_message_type IS '最后消息类型';
COMMENT ON COLUMN user_conversation_view_2.last_message_content IS '最后消息内容摘要';
COMMENT ON COLUMN user_conversation_view_2.last_message_sender_id IS '最后消息发送者 ID';
COMMENT ON COLUMN user_conversation_view_2.last_message_sender_name IS '最后消息发送者昵称';
COMMENT ON COLUMN user_conversation_view_2.last_message_time IS '最后消息时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN user_conversation_view_2.unread_count IS '未读消息数';
COMMENT ON COLUMN user_conversation_view_2.mention_count IS '@我的消息数';
COMMENT ON COLUMN user_conversation_view_2.opened_at IS '会话创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN user_conversation_view_2.closed_at IS '会话删除时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN user_conversation_view_2.created_at IS '创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN user_conversation_view_2.updated_at IS '更新时间戳 ( Unix 毫秒值 )';

-- 创建索引
CREATE INDEX idx_ucv_list_2 ON user_conversation_view_2(
    user_id,
    is_pinned DESC,
    last_message_time DESC
) WHERE closed_at = 0 AND is_hidden = FALSE;

CREATE INDEX idx_ucv_pinned_2 ON user_conversation_view_2(
    user_id,
    last_message_time DESC
) WHERE is_pinned = TRUE AND closed_at = 0;

CREATE INDEX idx_ucv_type_2 ON user_conversation_view_2(
    user_id,
    conversation_type,
    last_message_time DESC
) WHERE closed_at = 0;

CREATE INDEX idx_ucv_unread_2 ON user_conversation_view_2(
    user_id,
    unread_count DESC,
    last_message_time DESC
) WHERE unread_count > 0 AND closed_at = 0;

CREATE INDEX idx_ucv_peer_2 ON user_conversation_view_2(user_id, peer_user_id)
    WHERE conversation_type = 'single';

-- 分表 3: user_conversation_view_3
DROP TABLE IF EXISTS user_conversation_view_3;
CREATE TABLE user_conversation_view_3 (
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
    CONSTRAINT uk_user_conversation_3 UNIQUE(user_id, channel_id),

    -- 检查约束：单聊时必须有 peer_user_id
    CONSTRAINT chk_conversation_peer_3 CHECK (
        (conversation_type = 'single' AND peer_user_id IS NOT NULL)
        OR
        (conversation_type = 'group' AND peer_user_id IS NULL)
    )
);

COMMENT ON TABLE user_conversation_view_3 IS '【 读取侧 】用户会话视图表 ( 用于会话列表展示，冗余数据 )';
COMMENT ON COLUMN user_conversation_view_3.id IS '主键 ID';
COMMENT ON COLUMN user_conversation_view_3.user_id IS '用户 ID';
COMMENT ON COLUMN user_conversation_view_3.channel_id IS '频道 ID';
COMMENT ON COLUMN user_conversation_view_3.conversation_type IS '会话类型 ( single=单聊 / group=群聊 )';
COMMENT ON COLUMN user_conversation_view_3.conversation_name IS '会话显示名称 ( 单聊：备注名>昵称 / 群聊：群名 )';
COMMENT ON COLUMN user_conversation_view_3.conversation_avatar IS '会话显示头像 ( 单聊：对方头像，群聊：群头像 )';
COMMENT ON COLUMN user_conversation_view_3.conversation_info_ver IS '【 CQRS 关键字段 】会话信息版本号 ( 用于同步检测 )';
COMMENT ON COLUMN user_conversation_view_3.peer_user_id IS '单聊对方用户 ID ( 仅单聊有值 )';
COMMENT ON COLUMN user_conversation_view_3.peer_nickname IS '对方昵称 ( 冗余自 user 表 )';
COMMENT ON COLUMN user_conversation_view_3.peer_avatar IS '对方头像 ( 冗余自 user 表 )';
COMMENT ON COLUMN user_conversation_view_3.remark_name IS '好友备注名';
COMMENT ON COLUMN user_conversation_view_3.is_muted IS '是否免打扰';
COMMENT ON COLUMN user_conversation_view_3.is_pinned IS '是否置顶';
COMMENT ON COLUMN user_conversation_view_3.is_hidden IS '是否隐藏';
COMMENT ON COLUMN user_conversation_view_3.is_starred IS '是否星标 ( 仅单聊 )';
COMMENT ON COLUMN user_conversation_view_3.last_message_id IS '最后消息 ID';
COMMENT ON COLUMN user_conversation_view_3.last_message_type IS '最后消息类型';
COMMENT ON COLUMN user_conversation_view_3.last_message_content IS '最后消息内容摘要';
COMMENT ON COLUMN user_conversation_view_3.last_message_sender_id IS '最后消息发送者 ID';
COMMENT ON COLUMN user_conversation_view_3.last_message_sender_name IS '最后消息发送者昵称';
COMMENT ON COLUMN user_conversation_view_3.last_message_time IS '最后消息时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN user_conversation_view_3.unread_count IS '未读消息数';
COMMENT ON COLUMN user_conversation_view_3.mention_count IS '@我的消息数';
COMMENT ON COLUMN user_conversation_view_3.opened_at IS '会话创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN user_conversation_view_3.closed_at IS '会话删除时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN user_conversation_view_3.created_at IS '创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN user_conversation_view_3.updated_at IS '更新时间戳 ( Unix 毫秒值 )';

-- 创建索引
CREATE INDEX idx_ucv_list_3 ON user_conversation_view_3(
    user_id,
    is_pinned DESC,
    last_message_time DESC
) WHERE closed_at = 0 AND is_hidden = FALSE;

CREATE INDEX idx_ucv_pinned_3 ON user_conversation_view_3(
    user_id,
    last_message_time DESC
) WHERE is_pinned = TRUE AND closed_at = 0;

CREATE INDEX idx_ucv_type_3 ON user_conversation_view_3(
    user_id,
    conversation_type,
    last_message_time DESC
) WHERE closed_at = 0;

CREATE INDEX idx_ucv_unread_3 ON user_conversation_view_3(
    user_id,
    unread_count DESC,
    last_message_time DESC
) WHERE unread_count > 0 AND closed_at = 0;

CREATE INDEX idx_ucv_peer_3 ON user_conversation_view_3(user_id, peer_user_id)
    WHERE conversation_type = 'single';

