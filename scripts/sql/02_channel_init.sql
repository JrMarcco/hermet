-- 频道类型枚举 ( single=单聊, group=群聊 )
DROP TYPE IF EXISTS channel_type_enum CASCADE;
CREATE TYPE channel_type_enum AS ENUM ('single', 'group');

DROP TYPE IF EXISTS channel_status_enum CASCADE;
CREATE TYPE channel_status_enum AS ENUM ('creating', 'active', 'failed','archived');

-- 频道表 ( 聊天会话表 )
DROP TABLE IF EXISTS channel;
CREATE TABLE channel (
    id BIGINT PRIMARY KEY,
    avatar VARCHAR(256) NOT NULL DEFAULT '',
    channel_name VARCHAR(128) NOT NULL DEFAULT '',
    channel_type channel_type_enum NOT NULL,
    channel_status channel_status_enum NOT NULL,
    creator BIGINT NOT NULL,
    created_at BIGINT NOT NULL,
    updated_at BIGINT NOT NULL
);

COMMENT ON TABLE channel IS '频道表 ( 聊天会话表 )';
COMMENT ON COLUMN channel.id IS '频道 ID';
COMMENT ON COLUMN channel.channel_name IS '频道名称 ( 单聊为空，群聊有名称 )';
COMMENT ON COLUMN channel.channel_type IS '频道类型 ( single=单聊 / group=群聊 )';
COMMENT ON COLUMN channel.channel_status IS '频道状态 ( creating=创建中 / active=活跃 / failed=失败 / archived=已归档 )';
COMMENT ON COLUMN channel.avatar IS '频道头像';
COMMENT ON COLUMN channel.creator IS '创建者';
COMMENT ON COLUMN channel.created_at IS '创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN channel.updated_at IS '更新时间戳 ( Unix 毫秒值 )';

-- 创建索引
CREATE INDEX idx_channel_type ON channel(channel_type);
CREATE INDEX idx_channel_creator ON channel(creator);



-- 频道成员角色枚举 ( owner=群主 / admin=管理员 / member=普通成员 )
DROP TYPE IF EXISTS channel_member_role_enum CASCADE;
CREATE TYPE channel_member_role_enum AS ENUM ('owner', 'admin', 'member');

-- 频道成员表
DROP TABLE IF EXISTS channel_member;
CREATE TABLE channel_member (
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

COMMENT ON TABLE channel_member IS '频道成员表';
COMMENT ON COLUMN channel_member.id IS '主键 ID';
COMMENT ON COLUMN channel_member.channel_id IS '频道 ID';
COMMENT ON COLUMN channel_member.user_id IS '用户 ID';
COMMENT ON COLUMN channel_member.user_role IS '用户在频道中的角色 ( owner=群主 / admin=管理员 / member=普通成员 )';
COMMENT ON COLUMN channel_member.user_profile_ver IS '用户信息版本号';
COMMENT ON COLUMN channel_member.avatar IS '用户头像';
COMMENT ON COLUMN channel_member.alias IS '用户在频道中的别名';
COMMENT ON COLUMN channel_member.nickname IS '用户昵称';
COMMENT ON COLUMN channel_member.priority_order IS '优先级（用于排序）';
COMMENT ON COLUMN channel_member.mute IS '是否免打扰';
COMMENT ON COLUMN channel.created_at IS '创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN channel.updated_at IS '更新时间戳 ( Unix 毫秒值 )';

-- 创建索引
CREATE INDEX idx_channel_member_channel ON channel_member(channel_id);
CREATE INDEX idx_channel_member_user ON channel_member(user_id);



-- 频道消息已读记录表
DROP TABLE IF EXISTS channel_read_record;
CREATE TABLE channel_read_record (
    id BIGINT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    channel_id BIGINT NOT NULL,
    last_message_id BIGINT NOT NULL DEFAULT 0,
    updated_at BIGINT NOT NULL,
    CONSTRAINT uk_channel_user_read UNIQUE (user_id, channel_id)
);

COMMENT ON TABLE channel_read_record IS '频道消息已读记录表';
COMMENT ON COLUMN channel_read_record.id IS '主键 ID';
COMMENT ON COLUMN channel_read_record.channel_id IS '频道 ID';
COMMENT ON COLUMN channel_read_record.user_id IS '用户 ID';
COMMENT ON COLUMN channel_read_record.last_message_id IS '最后已读消息ID';
COMMENT ON COLUMN channel_read_record.updated_at IS '更新时间戳 ( Unix 毫秒值 )';

-- 创建索引
CREATE INDEX idx_channel_read_user_channel ON channel_read_record(user_id, channel_id);



-- 用户频道
DROP TABLE IF EXISTS user_channel;
CREATE TABLE user_channel (
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

COMMENT ON TABLE user_channel IS '用户频道表';
COMMENT ON COLUMN user_channel.id IS '主键 ID';
COMMENT ON COLUMN user_channel.user_id IS '用户 ID';
COMMENT ON COLUMN user_channel.channel_id IS '频道 ID';
COMMENT ON COLUMN user_channel.channel_type IS '频道类型 ( single=单聊, group=群聊 )';
COMMENT ON COLUMN user_channel.channel_name IS '频道名称 ( 单聊为空，群聊有名称 )';
COMMENT ON COLUMN user_channel.channel_avatar IS '频道头像';
COMMENT ON COLUMN user_channel.channel_mute IS '是否免打扰';
COMMENT ON COLUMN user_channel.channel_join_at IS '加入时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN user_channel.channel_leave_at IS '离开时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN user_channel.created_at IS '创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN user_channel.updated_at IS '更新时间戳 ( Unix 毫秒值 )';

-- 创建索引
CREATE INDEX idx_user_channel_user ON user_channel(user_id);
