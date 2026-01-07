-- ============================================
-- 分库分表SQL脚本
-- 数据库: hermet_1
-- 分表数量: 4
-- 生成时间: 2026-01-07 17:41:19
-- 原始文件: ./02_channel_init.sql
-- ============================================

-- ============================================
-- 枚举类型定义
-- ============================================

DROP TYPE IF EXISTS channel_application_status_enum CASCADE;
CREATE TYPE channel_application_status_enum AS ENUM ('pending', 'approved', 'rejected');

DROP TYPE IF EXISTS channel_member_role_enum CASCADE;
CREATE TYPE channel_member_role_enum AS ENUM ('owner', 'admin', 'member');

DROP TYPE IF EXISTS channel_status_enum CASCADE;
CREATE TYPE channel_status_enum AS ENUM ('creating', 'active', 'failed','archived');

DROP TYPE IF EXISTS channel_type_enum CASCADE;
CREATE TYPE channel_type_enum AS ENUM ('single', 'group');

-- ============================================
-- 表: channel (分表数: 4)
-- ============================================

-- 分表 0: channel_0
DROP TABLE IF EXISTS channel_0;
CREATE TABLE channel_0 (
    id BIGINT PRIMARY KEY,
    avatar VARCHAR(256) NOT NULL DEFAULT '',
    channel_name VARCHAR(128) NOT NULL DEFAULT '',
    channel_type channel_type_enum NOT NULL,
    channel_status channel_status_enum NOT NULL,
    creator BIGINT NOT NULL,
    created_at BIGINT NOT NULL,
    updated_at BIGINT NOT NULL
);

COMMENT ON COLUMN channel_0.id IS '频道 ID';
COMMENT ON COLUMN channel_0.channel_name IS '频道名称 ( 单聊为空，群聊有名称 )';
COMMENT ON COLUMN channel_0.channel_type IS '频道类型 ( single=单聊 / group=群聊 )';
COMMENT ON COLUMN channel_0.channel_status IS '频道状态 ( creating=创建中 / active=活跃 / failed=失败 / archived=已归档 )';
COMMENT ON COLUMN channel_0.avatar IS '频道头像';
COMMENT ON COLUMN channel_0.creator IS '创建者';
COMMENT ON COLUMN channel_0.created_at IS '创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN channel_0.updated_at IS '更新时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN channel_0.created_at IS '创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN channel_0.updated_at IS '更新时间戳 ( Unix 毫秒值 )';

-- 创建索引
CREATE INDEX idx_channel_type_0 ON channel_0(channel_type);
CREATE INDEX idx_channel_creator_0 ON channel_0(creator);


-- 分表 1: channel_1
DROP TABLE IF EXISTS channel_1;
CREATE TABLE channel_1 (
    id BIGINT PRIMARY KEY,
    avatar VARCHAR(256) NOT NULL DEFAULT '',
    channel_name VARCHAR(128) NOT NULL DEFAULT '',
    channel_type channel_type_enum NOT NULL,
    channel_status channel_status_enum NOT NULL,
    creator BIGINT NOT NULL,
    created_at BIGINT NOT NULL,
    updated_at BIGINT NOT NULL
);

COMMENT ON COLUMN channel_1.id IS '频道 ID';
COMMENT ON COLUMN channel_1.channel_name IS '频道名称 ( 单聊为空，群聊有名称 )';
COMMENT ON COLUMN channel_1.channel_type IS '频道类型 ( single=单聊 / group=群聊 )';
COMMENT ON COLUMN channel_1.channel_status IS '频道状态 ( creating=创建中 / active=活跃 / failed=失败 / archived=已归档 )';
COMMENT ON COLUMN channel_1.avatar IS '频道头像';
COMMENT ON COLUMN channel_1.creator IS '创建者';
COMMENT ON COLUMN channel_1.created_at IS '创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN channel_1.updated_at IS '更新时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN channel_1.created_at IS '创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN channel_1.updated_at IS '更新时间戳 ( Unix 毫秒值 )';

-- 创建索引
CREATE INDEX idx_channel_type_1 ON channel_1(channel_type);
CREATE INDEX idx_channel_creator_1 ON channel_1(creator);


-- 分表 2: channel_2
DROP TABLE IF EXISTS channel_2;
CREATE TABLE channel_2 (
    id BIGINT PRIMARY KEY,
    avatar VARCHAR(256) NOT NULL DEFAULT '',
    channel_name VARCHAR(128) NOT NULL DEFAULT '',
    channel_type channel_type_enum NOT NULL,
    channel_status channel_status_enum NOT NULL,
    creator BIGINT NOT NULL,
    created_at BIGINT NOT NULL,
    updated_at BIGINT NOT NULL
);

COMMENT ON COLUMN channel_2.id IS '频道 ID';
COMMENT ON COLUMN channel_2.channel_name IS '频道名称 ( 单聊为空，群聊有名称 )';
COMMENT ON COLUMN channel_2.channel_type IS '频道类型 ( single=单聊 / group=群聊 )';
COMMENT ON COLUMN channel_2.channel_status IS '频道状态 ( creating=创建中 / active=活跃 / failed=失败 / archived=已归档 )';
COMMENT ON COLUMN channel_2.avatar IS '频道头像';
COMMENT ON COLUMN channel_2.creator IS '创建者';
COMMENT ON COLUMN channel_2.created_at IS '创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN channel_2.updated_at IS '更新时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN channel_2.created_at IS '创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN channel_2.updated_at IS '更新时间戳 ( Unix 毫秒值 )';

-- 创建索引
CREATE INDEX idx_channel_type_2 ON channel_2(channel_type);
CREATE INDEX idx_channel_creator_2 ON channel_2(creator);


-- 分表 3: channel_3
DROP TABLE IF EXISTS channel_3;
CREATE TABLE channel_3 (
    id BIGINT PRIMARY KEY,
    avatar VARCHAR(256) NOT NULL DEFAULT '',
    channel_name VARCHAR(128) NOT NULL DEFAULT '',
    channel_type channel_type_enum NOT NULL,
    channel_status channel_status_enum NOT NULL,
    creator BIGINT NOT NULL,
    created_at BIGINT NOT NULL,
    updated_at BIGINT NOT NULL
);

COMMENT ON COLUMN channel_3.id IS '频道 ID';
COMMENT ON COLUMN channel_3.channel_name IS '频道名称 ( 单聊为空，群聊有名称 )';
COMMENT ON COLUMN channel_3.channel_type IS '频道类型 ( single=单聊 / group=群聊 )';
COMMENT ON COLUMN channel_3.channel_status IS '频道状态 ( creating=创建中 / active=活跃 / failed=失败 / archived=已归档 )';
COMMENT ON COLUMN channel_3.avatar IS '频道头像';
COMMENT ON COLUMN channel_3.creator IS '创建者';
COMMENT ON COLUMN channel_3.created_at IS '创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN channel_3.updated_at IS '更新时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN channel_3.created_at IS '创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN channel_3.updated_at IS '更新时间戳 ( Unix 毫秒值 )';

-- 创建索引
CREATE INDEX idx_channel_type_3 ON channel_3(channel_type);
CREATE INDEX idx_channel_creator_3 ON channel_3(creator);


-- ============================================
-- 表: channel_application (分表数: 4)
-- ============================================

-- 分表 0: channel_application_0
DROP TABLE IF EXISTS channel_application_0;
CREATE TABLE channel_application_0 (
    id BIGINT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    channel_id BIGINT NOT NULL,
    channel_name VARCHAR(128) NOT NULL DEFAULT '',
    channel_avatar VARCHAR(256) NOT NULL DEFAULT '',
    channel_type channel_type_enum NOT NULL,
    application_status channel_application_status_enum NOT NULL,
    created_at BIGINT NOT NULL,
    updated_at BIGINT NOT NULL
);

COMMENT ON COLUMN channel_application_0.id IS '主键 ID';
COMMENT ON COLUMN channel_application_0.user_id IS '用户 ID';
COMMENT ON COLUMN channel_application_0.channel_id IS '频道 ID';
COMMENT ON COLUMN channel_application_0.channel_name IS '频道名称 ( 单聊为用户昵称 )';
COMMENT ON COLUMN channel_application_0.channel_avatar IS '频道头像';
COMMENT ON COLUMN channel_application_0.channel_type IS '频道类型 ( single=单聊, group=群聊 )';
COMMENT ON COLUMN channel_application_0.application_status IS '申请状态 ( pending=待处理 / approved=已批准 / rejected=已拒绝 )';
COMMENT ON COLUMN channel_application_0.created_at IS '创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN channel_application_0.updated_at IS '更新时间戳 ( Unix 毫秒值 )';

-- 创建索引
CREATE INDEX idx_channel_application_user_0 ON channel_application_0(user_id);
CREATE INDEX idx_channel_application_channel_0 ON channel_application_0(channel_id);


-- 分表 1: channel_application_1
DROP TABLE IF EXISTS channel_application_1;
CREATE TABLE channel_application_1 (
    id BIGINT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    channel_id BIGINT NOT NULL,
    channel_name VARCHAR(128) NOT NULL DEFAULT '',
    channel_avatar VARCHAR(256) NOT NULL DEFAULT '',
    channel_type channel_type_enum NOT NULL,
    application_status channel_application_status_enum NOT NULL,
    created_at BIGINT NOT NULL,
    updated_at BIGINT NOT NULL
);

COMMENT ON COLUMN channel_application_1.id IS '主键 ID';
COMMENT ON COLUMN channel_application_1.user_id IS '用户 ID';
COMMENT ON COLUMN channel_application_1.channel_id IS '频道 ID';
COMMENT ON COLUMN channel_application_1.channel_name IS '频道名称 ( 单聊为用户昵称 )';
COMMENT ON COLUMN channel_application_1.channel_avatar IS '频道头像';
COMMENT ON COLUMN channel_application_1.channel_type IS '频道类型 ( single=单聊, group=群聊 )';
COMMENT ON COLUMN channel_application_1.application_status IS '申请状态 ( pending=待处理 / approved=已批准 / rejected=已拒绝 )';
COMMENT ON COLUMN channel_application_1.created_at IS '创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN channel_application_1.updated_at IS '更新时间戳 ( Unix 毫秒值 )';

-- 创建索引
CREATE INDEX idx_channel_application_user_1 ON channel_application_1(user_id);
CREATE INDEX idx_channel_application_channel_1 ON channel_application_1(channel_id);


-- 分表 2: channel_application_2
DROP TABLE IF EXISTS channel_application_2;
CREATE TABLE channel_application_2 (
    id BIGINT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    channel_id BIGINT NOT NULL,
    channel_name VARCHAR(128) NOT NULL DEFAULT '',
    channel_avatar VARCHAR(256) NOT NULL DEFAULT '',
    channel_type channel_type_enum NOT NULL,
    application_status channel_application_status_enum NOT NULL,
    created_at BIGINT NOT NULL,
    updated_at BIGINT NOT NULL
);

COMMENT ON COLUMN channel_application_2.id IS '主键 ID';
COMMENT ON COLUMN channel_application_2.user_id IS '用户 ID';
COMMENT ON COLUMN channel_application_2.channel_id IS '频道 ID';
COMMENT ON COLUMN channel_application_2.channel_name IS '频道名称 ( 单聊为用户昵称 )';
COMMENT ON COLUMN channel_application_2.channel_avatar IS '频道头像';
COMMENT ON COLUMN channel_application_2.channel_type IS '频道类型 ( single=单聊, group=群聊 )';
COMMENT ON COLUMN channel_application_2.application_status IS '申请状态 ( pending=待处理 / approved=已批准 / rejected=已拒绝 )';
COMMENT ON COLUMN channel_application_2.created_at IS '创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN channel_application_2.updated_at IS '更新时间戳 ( Unix 毫秒值 )';

-- 创建索引
CREATE INDEX idx_channel_application_user_2 ON channel_application_2(user_id);
CREATE INDEX idx_channel_application_channel_2 ON channel_application_2(channel_id);


-- 分表 3: channel_application_3
DROP TABLE IF EXISTS channel_application_3;
CREATE TABLE channel_application_3 (
    id BIGINT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    channel_id BIGINT NOT NULL,
    channel_name VARCHAR(128) NOT NULL DEFAULT '',
    channel_avatar VARCHAR(256) NOT NULL DEFAULT '',
    channel_type channel_type_enum NOT NULL,
    application_status channel_application_status_enum NOT NULL,
    created_at BIGINT NOT NULL,
    updated_at BIGINT NOT NULL
);

COMMENT ON COLUMN channel_application_3.id IS '主键 ID';
COMMENT ON COLUMN channel_application_3.user_id IS '用户 ID';
COMMENT ON COLUMN channel_application_3.channel_id IS '频道 ID';
COMMENT ON COLUMN channel_application_3.channel_name IS '频道名称 ( 单聊为用户昵称 )';
COMMENT ON COLUMN channel_application_3.channel_avatar IS '频道头像';
COMMENT ON COLUMN channel_application_3.channel_type IS '频道类型 ( single=单聊, group=群聊 )';
COMMENT ON COLUMN channel_application_3.application_status IS '申请状态 ( pending=待处理 / approved=已批准 / rejected=已拒绝 )';
COMMENT ON COLUMN channel_application_3.created_at IS '创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN channel_application_3.updated_at IS '更新时间戳 ( Unix 毫秒值 )';

-- 创建索引
CREATE INDEX idx_channel_application_user_3 ON channel_application_3(user_id);
CREATE INDEX idx_channel_application_channel_3 ON channel_application_3(channel_id);


-- ============================================
-- 表: channel_member (分表数: 4)
-- ============================================

-- 分表 0: channel_member_0
DROP TABLE IF EXISTS channel_member_0;
CREATE TABLE channel_member_0 (
    id BIGINT PRIMARY KEY,
    channel_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    user_role channel_member_role_enum NOT NULL DEFAULT 'member',
    user_profile_ver INT NOT NULL DEFAULT 1,
    avatar VARCHAR(256) NOT NULL DEFAULT '',
    alias VARCHAR(64) NOT NULL DEFAULT '',
    nickname VARCHAR(64) NOT NULL DEFAULT '',
    priority_order INT NOT NULL DEFAULT 0,
    mute BOOLEAN NOT NULL DEFAULT FALSE,
    created_at BIGINT NOT NULL,
    updated_at BIGINT NOT NULL,
    CONSTRAINT uk_channel_user UNIQUE (channel_id, user_id)
);

COMMENT ON COLUMN channel_member_0.id IS '主键 ID';
COMMENT ON COLUMN channel_member_0.channel_id IS '频道 ID';
COMMENT ON COLUMN channel_member_0.user_id IS '用户 ID';
COMMENT ON COLUMN channel_member_0.user_role IS '用户在频道中的角色 ( owner=群主 / admin=管理员 / member=普通成员 )';
COMMENT ON COLUMN channel_member_0.user_profile_ver IS '用户信息版本号';
COMMENT ON COLUMN channel_member_0.avatar IS '用户头像';
COMMENT ON COLUMN channel_member_0.alias IS '用户在频道中的别名';
COMMENT ON COLUMN channel_member_0.nickname IS '用户昵称';
COMMENT ON COLUMN channel_member_0.priority_order IS '优先级（用于排序）';
COMMENT ON COLUMN channel_member_0.mute IS '是否免打扰';

-- 创建索引
CREATE INDEX idx_channel_member_channel_0 ON channel_member_0(channel_id);
CREATE INDEX idx_channel_member_user_0 ON channel_member_0(user_id);


-- 分表 1: channel_member_1
DROP TABLE IF EXISTS channel_member_1;
CREATE TABLE channel_member_1 (
    id BIGINT PRIMARY KEY,
    channel_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    user_role channel_member_role_enum NOT NULL DEFAULT 'member',
    user_profile_ver INT NOT NULL DEFAULT 1,
    avatar VARCHAR(256) NOT NULL DEFAULT '',
    alias VARCHAR(64) NOT NULL DEFAULT '',
    nickname VARCHAR(64) NOT NULL DEFAULT '',
    priority_order INT NOT NULL DEFAULT 0,
    mute BOOLEAN NOT NULL DEFAULT FALSE,
    created_at BIGINT NOT NULL,
    updated_at BIGINT NOT NULL,
    CONSTRAINT uk_channel_user UNIQUE (channel_id, user_id)
);

COMMENT ON COLUMN channel_member_1.id IS '主键 ID';
COMMENT ON COLUMN channel_member_1.channel_id IS '频道 ID';
COMMENT ON COLUMN channel_member_1.user_id IS '用户 ID';
COMMENT ON COLUMN channel_member_1.user_role IS '用户在频道中的角色 ( owner=群主 / admin=管理员 / member=普通成员 )';
COMMENT ON COLUMN channel_member_1.user_profile_ver IS '用户信息版本号';
COMMENT ON COLUMN channel_member_1.avatar IS '用户头像';
COMMENT ON COLUMN channel_member_1.alias IS '用户在频道中的别名';
COMMENT ON COLUMN channel_member_1.nickname IS '用户昵称';
COMMENT ON COLUMN channel_member_1.priority_order IS '优先级（用于排序）';
COMMENT ON COLUMN channel_member_1.mute IS '是否免打扰';

-- 创建索引
CREATE INDEX idx_channel_member_channel_1 ON channel_member_1(channel_id);
CREATE INDEX idx_channel_member_user_1 ON channel_member_1(user_id);


-- 分表 2: channel_member_2
DROP TABLE IF EXISTS channel_member_2;
CREATE TABLE channel_member_2 (
    id BIGINT PRIMARY KEY,
    channel_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    user_role channel_member_role_enum NOT NULL DEFAULT 'member',
    user_profile_ver INT NOT NULL DEFAULT 1,
    avatar VARCHAR(256) NOT NULL DEFAULT '',
    alias VARCHAR(64) NOT NULL DEFAULT '',
    nickname VARCHAR(64) NOT NULL DEFAULT '',
    priority_order INT NOT NULL DEFAULT 0,
    mute BOOLEAN NOT NULL DEFAULT FALSE,
    created_at BIGINT NOT NULL,
    updated_at BIGINT NOT NULL,
    CONSTRAINT uk_channel_user UNIQUE (channel_id, user_id)
);

COMMENT ON COLUMN channel_member_2.id IS '主键 ID';
COMMENT ON COLUMN channel_member_2.channel_id IS '频道 ID';
COMMENT ON COLUMN channel_member_2.user_id IS '用户 ID';
COMMENT ON COLUMN channel_member_2.user_role IS '用户在频道中的角色 ( owner=群主 / admin=管理员 / member=普通成员 )';
COMMENT ON COLUMN channel_member_2.user_profile_ver IS '用户信息版本号';
COMMENT ON COLUMN channel_member_2.avatar IS '用户头像';
COMMENT ON COLUMN channel_member_2.alias IS '用户在频道中的别名';
COMMENT ON COLUMN channel_member_2.nickname IS '用户昵称';
COMMENT ON COLUMN channel_member_2.priority_order IS '优先级（用于排序）';
COMMENT ON COLUMN channel_member_2.mute IS '是否免打扰';

-- 创建索引
CREATE INDEX idx_channel_member_channel_2 ON channel_member_2(channel_id);
CREATE INDEX idx_channel_member_user_2 ON channel_member_2(user_id);


-- 分表 3: channel_member_3
DROP TABLE IF EXISTS channel_member_3;
CREATE TABLE channel_member_3 (
    id BIGINT PRIMARY KEY,
    channel_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    user_role channel_member_role_enum NOT NULL DEFAULT 'member',
    user_profile_ver INT NOT NULL DEFAULT 1,
    avatar VARCHAR(256) NOT NULL DEFAULT '',
    alias VARCHAR(64) NOT NULL DEFAULT '',
    nickname VARCHAR(64) NOT NULL DEFAULT '',
    priority_order INT NOT NULL DEFAULT 0,
    mute BOOLEAN NOT NULL DEFAULT FALSE,
    created_at BIGINT NOT NULL,
    updated_at BIGINT NOT NULL,
    CONSTRAINT uk_channel_user UNIQUE (channel_id, user_id)
);

COMMENT ON COLUMN channel_member_3.id IS '主键 ID';
COMMENT ON COLUMN channel_member_3.channel_id IS '频道 ID';
COMMENT ON COLUMN channel_member_3.user_id IS '用户 ID';
COMMENT ON COLUMN channel_member_3.user_role IS '用户在频道中的角色 ( owner=群主 / admin=管理员 / member=普通成员 )';
COMMENT ON COLUMN channel_member_3.user_profile_ver IS '用户信息版本号';
COMMENT ON COLUMN channel_member_3.avatar IS '用户头像';
COMMENT ON COLUMN channel_member_3.alias IS '用户在频道中的别名';
COMMENT ON COLUMN channel_member_3.nickname IS '用户昵称';
COMMENT ON COLUMN channel_member_3.priority_order IS '优先级（用于排序）';
COMMENT ON COLUMN channel_member_3.mute IS '是否免打扰';

-- 创建索引
CREATE INDEX idx_channel_member_channel_3 ON channel_member_3(channel_id);
CREATE INDEX idx_channel_member_user_3 ON channel_member_3(user_id);


-- ============================================
-- 表: channel_read_record (分表数: 4)
-- ============================================

-- 分表 0: channel_read_record_0
DROP TABLE IF EXISTS channel_read_record_0;
CREATE TABLE channel_read_record_0 (
    id BIGINT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    channel_id BIGINT NOT NULL,
    last_message_id BIGINT NOT NULL DEFAULT 0,
    updated_at BIGINT NOT NULL,
    CONSTRAINT uk_channel_user_read UNIQUE (user_id, channel_id)
);

COMMENT ON COLUMN channel_read_record_0.id IS '主键 ID';
COMMENT ON COLUMN channel_read_record_0.channel_id IS '频道 ID';
COMMENT ON COLUMN channel_read_record_0.user_id IS '用户 ID';
COMMENT ON COLUMN channel_read_record_0.last_message_id IS '最后已读消息ID';
COMMENT ON COLUMN channel_read_record_0.updated_at IS '更新时间戳 ( Unix 毫秒值 )';

-- 创建索引
CREATE INDEX idx_channel_read_user_channel_0 ON channel_read_record_0(user_id, channel_id);


-- 分表 1: channel_read_record_1
DROP TABLE IF EXISTS channel_read_record_1;
CREATE TABLE channel_read_record_1 (
    id BIGINT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    channel_id BIGINT NOT NULL,
    last_message_id BIGINT NOT NULL DEFAULT 0,
    updated_at BIGINT NOT NULL,
    CONSTRAINT uk_channel_user_read UNIQUE (user_id, channel_id)
);

COMMENT ON COLUMN channel_read_record_1.id IS '主键 ID';
COMMENT ON COLUMN channel_read_record_1.channel_id IS '频道 ID';
COMMENT ON COLUMN channel_read_record_1.user_id IS '用户 ID';
COMMENT ON COLUMN channel_read_record_1.last_message_id IS '最后已读消息ID';
COMMENT ON COLUMN channel_read_record_1.updated_at IS '更新时间戳 ( Unix 毫秒值 )';

-- 创建索引
CREATE INDEX idx_channel_read_user_channel_1 ON channel_read_record_1(user_id, channel_id);


-- 分表 2: channel_read_record_2
DROP TABLE IF EXISTS channel_read_record_2;
CREATE TABLE channel_read_record_2 (
    id BIGINT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    channel_id BIGINT NOT NULL,
    last_message_id BIGINT NOT NULL DEFAULT 0,
    updated_at BIGINT NOT NULL,
    CONSTRAINT uk_channel_user_read UNIQUE (user_id, channel_id)
);

COMMENT ON COLUMN channel_read_record_2.id IS '主键 ID';
COMMENT ON COLUMN channel_read_record_2.channel_id IS '频道 ID';
COMMENT ON COLUMN channel_read_record_2.user_id IS '用户 ID';
COMMENT ON COLUMN channel_read_record_2.last_message_id IS '最后已读消息ID';
COMMENT ON COLUMN channel_read_record_2.updated_at IS '更新时间戳 ( Unix 毫秒值 )';

-- 创建索引
CREATE INDEX idx_channel_read_user_channel_2 ON channel_read_record_2(user_id, channel_id);


-- 分表 3: channel_read_record_3
DROP TABLE IF EXISTS channel_read_record_3;
CREATE TABLE channel_read_record_3 (
    id BIGINT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    channel_id BIGINT NOT NULL,
    last_message_id BIGINT NOT NULL DEFAULT 0,
    updated_at BIGINT NOT NULL,
    CONSTRAINT uk_channel_user_read UNIQUE (user_id, channel_id)
);

COMMENT ON COLUMN channel_read_record_3.id IS '主键 ID';
COMMENT ON COLUMN channel_read_record_3.channel_id IS '频道 ID';
COMMENT ON COLUMN channel_read_record_3.user_id IS '用户 ID';
COMMENT ON COLUMN channel_read_record_3.last_message_id IS '最后已读消息ID';
COMMENT ON COLUMN channel_read_record_3.updated_at IS '更新时间戳 ( Unix 毫秒值 )';

-- 创建索引
CREATE INDEX idx_channel_read_user_channel_3 ON channel_read_record_3(user_id, channel_id);


-- ============================================
-- 表: user_channel (分表数: 4)
-- ============================================

-- 分表 0: user_channel_0
DROP TABLE IF EXISTS user_channel_0;
CREATE TABLE user_channel_0 (
    id BIGINT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    channel_id BIGINT NOT NULL,
    channel_type channel_type_enum NOT NULL,
    channel_name VARCHAR(128) NOT NULL DEFAULT '',
    channel_avatar VARCHAR(256) NOT NULL DEFAULT '',
    channel_mute BOOLEAN NOT NULL DEFAULT FALSE,
    channel_join_at BIGINT NOT NULL,
    channel_leave_at BIGINT NOT NULL,
    created_at BIGINT NOT NULL,
    updated_at BIGINT NOT NULL,
    CONSTRAINT uk_user_channel UNIQUE (user_id, channel_id)
);

COMMENT ON COLUMN user_channel_0.id IS '主键 ID';
COMMENT ON COLUMN user_channel_0.user_id IS '用户 ID';
COMMENT ON COLUMN user_channel_0.channel_id IS '频道 ID';
COMMENT ON COLUMN user_channel_0.channel_type IS '频道类型 ( single=单聊, group=群聊 )';
COMMENT ON COLUMN user_channel_0.channel_name IS '频道名称 ( 单聊为空，群聊有名称 )';
COMMENT ON COLUMN user_channel_0.channel_avatar IS '频道头像';
COMMENT ON COLUMN user_channel_0.channel_mute IS '是否免打扰';
COMMENT ON COLUMN user_channel_0.channel_join_at IS '加入时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN user_channel_0.channel_leave_at IS '离开时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN user_channel_0.created_at IS '创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN user_channel_0.updated_at IS '更新时间戳 ( Unix 毫秒值 )';

-- 创建索引
CREATE INDEX idx_user_channel_user_channel_0 ON user_channel_0(user_id, channel_id);


-- 分表 1: user_channel_1
DROP TABLE IF EXISTS user_channel_1;
CREATE TABLE user_channel_1 (
    id BIGINT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    channel_id BIGINT NOT NULL,
    channel_type channel_type_enum NOT NULL,
    channel_name VARCHAR(128) NOT NULL DEFAULT '',
    channel_avatar VARCHAR(256) NOT NULL DEFAULT '',
    channel_mute BOOLEAN NOT NULL DEFAULT FALSE,
    channel_join_at BIGINT NOT NULL,
    channel_leave_at BIGINT NOT NULL,
    created_at BIGINT NOT NULL,
    updated_at BIGINT NOT NULL,
    CONSTRAINT uk_user_channel UNIQUE (user_id, channel_id)
);

COMMENT ON COLUMN user_channel_1.id IS '主键 ID';
COMMENT ON COLUMN user_channel_1.user_id IS '用户 ID';
COMMENT ON COLUMN user_channel_1.channel_id IS '频道 ID';
COMMENT ON COLUMN user_channel_1.channel_type IS '频道类型 ( single=单聊, group=群聊 )';
COMMENT ON COLUMN user_channel_1.channel_name IS '频道名称 ( 单聊为空，群聊有名称 )';
COMMENT ON COLUMN user_channel_1.channel_avatar IS '频道头像';
COMMENT ON COLUMN user_channel_1.channel_mute IS '是否免打扰';
COMMENT ON COLUMN user_channel_1.channel_join_at IS '加入时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN user_channel_1.channel_leave_at IS '离开时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN user_channel_1.created_at IS '创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN user_channel_1.updated_at IS '更新时间戳 ( Unix 毫秒值 )';

-- 创建索引
CREATE INDEX idx_user_channel_user_channel_1 ON user_channel_1(user_id, channel_id);


-- 分表 2: user_channel_2
DROP TABLE IF EXISTS user_channel_2;
CREATE TABLE user_channel_2 (
    id BIGINT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    channel_id BIGINT NOT NULL,
    channel_type channel_type_enum NOT NULL,
    channel_name VARCHAR(128) NOT NULL DEFAULT '',
    channel_avatar VARCHAR(256) NOT NULL DEFAULT '',
    channel_mute BOOLEAN NOT NULL DEFAULT FALSE,
    channel_join_at BIGINT NOT NULL,
    channel_leave_at BIGINT NOT NULL,
    created_at BIGINT NOT NULL,
    updated_at BIGINT NOT NULL,
    CONSTRAINT uk_user_channel UNIQUE (user_id, channel_id)
);

COMMENT ON COLUMN user_channel_2.id IS '主键 ID';
COMMENT ON COLUMN user_channel_2.user_id IS '用户 ID';
COMMENT ON COLUMN user_channel_2.channel_id IS '频道 ID';
COMMENT ON COLUMN user_channel_2.channel_type IS '频道类型 ( single=单聊, group=群聊 )';
COMMENT ON COLUMN user_channel_2.channel_name IS '频道名称 ( 单聊为空，群聊有名称 )';
COMMENT ON COLUMN user_channel_2.channel_avatar IS '频道头像';
COMMENT ON COLUMN user_channel_2.channel_mute IS '是否免打扰';
COMMENT ON COLUMN user_channel_2.channel_join_at IS '加入时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN user_channel_2.channel_leave_at IS '离开时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN user_channel_2.created_at IS '创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN user_channel_2.updated_at IS '更新时间戳 ( Unix 毫秒值 )';

-- 创建索引
CREATE INDEX idx_user_channel_user_channel_2 ON user_channel_2(user_id, channel_id);


-- 分表 3: user_channel_3
DROP TABLE IF EXISTS user_channel_3;
CREATE TABLE user_channel_3 (
    id BIGINT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    channel_id BIGINT NOT NULL,
    channel_type channel_type_enum NOT NULL,
    channel_name VARCHAR(128) NOT NULL DEFAULT '',
    channel_avatar VARCHAR(256) NOT NULL DEFAULT '',
    channel_mute BOOLEAN NOT NULL DEFAULT FALSE,
    channel_join_at BIGINT NOT NULL,
    channel_leave_at BIGINT NOT NULL,
    created_at BIGINT NOT NULL,
    updated_at BIGINT NOT NULL,
    CONSTRAINT uk_user_channel UNIQUE (user_id, channel_id)
);

COMMENT ON COLUMN user_channel_3.id IS '主键 ID';
COMMENT ON COLUMN user_channel_3.user_id IS '用户 ID';
COMMENT ON COLUMN user_channel_3.channel_id IS '频道 ID';
COMMENT ON COLUMN user_channel_3.channel_type IS '频道类型 ( single=单聊, group=群聊 )';
COMMENT ON COLUMN user_channel_3.channel_name IS '频道名称 ( 单聊为空，群聊有名称 )';
COMMENT ON COLUMN user_channel_3.channel_avatar IS '频道头像';
COMMENT ON COLUMN user_channel_3.channel_mute IS '是否免打扰';
COMMENT ON COLUMN user_channel_3.channel_join_at IS '加入时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN user_channel_3.channel_leave_at IS '离开时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN user_channel_3.created_at IS '创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN user_channel_3.updated_at IS '更新时间戳 ( Unix 毫秒值 )';

-- 创建索引
CREATE INDEX idx_user_channel_user_channel_3 ON user_channel_3(user_id, channel_id);


