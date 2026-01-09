-- ============================================
-- 分库分表SQL脚本
-- 数据库: hermet_1
-- 分表数量: 4
-- 生成时间: 2026-01-09 16:40:52
-- 原始文件: ./02_user_init.sql
-- ============================================

-- ============================================
-- 枚举类型定义
-- ============================================

DROP TYPE IF EXISTS gender_enum CASCADE;
CREATE TYPE gender_enum AS ENUM ('unknown', 'male', 'female');

DROP TYPE IF EXISTS user_status_enum CASCADE;
CREATE TYPE user_status_enum AS ENUM ('active', 'disabled', 'deleted');

-- ============================================
-- 表: biz_user (分表数: 4)
-- ============================================

-- 分表 0: biz_user_0
DROP TABLE IF EXISTS biz_user_0;
CREATE TABLE biz_user_0 (
    id BIGINT PRIMARY KEY,

    -- 账号信息
    email VARCHAR(128) NOT NULL,
    mobile VARCHAR(16) NOT NULL,
    passwd VARCHAR(128) NOT NULL,

    -- 个人信息 ( 会被冗余到读取侧 )
    nickname VARCHAR(64) NOT NULL,
    avatar VARCHAR(256) NOT NULL DEFAULT '',
    gender gender_enum NOT NULL DEFAULT 'unknown',
    region VARCHAR(64) NOT NULL DEFAULT '',            -- 地区
    birthday BIGINT NOT NULL DEFAULT 0,                -- 生日 ( Unix 毫秒值 )
    tagline VARCHAR(256) NOT NULL DEFAULT '',          -- 用户签名

    -- 版本控制（CQRS 关键字段）
    info_ver INT NOT NULL DEFAULT 1,                   -- 个人信息版本号

    -- 状态管理
    user_status user_status_enum NOT NULL DEFAULT 'active',
    deleted_at BIGINT NOT NULL DEFAULT 0,              -- 软删除 ( 0 表示未删除 )

    -- 时间戳
    created_at BIGINT NOT NULL,
    updated_at BIGINT NOT NULL
);

COMMENT ON TABLE biz_user_0 IS '【 写入侧 】业务用户信息表';
COMMENT ON COLUMN biz_user_0.id IS '用户 ID';
COMMENT ON COLUMN biz_user_0.email IS '邮箱 ( 唯一 )';
COMMENT ON COLUMN biz_user_0.mobile IS '手机号 ( 唯一 )';
COMMENT ON COLUMN biz_user_0.passwd IS '密码';
COMMENT ON COLUMN biz_user_0.nickname IS '昵称 ( 会被冗余到会话视图 / 联系人视图 )';
COMMENT ON COLUMN biz_user_0.avatar IS '头像 ( 会被冗余到会话视图联系人视图 )';
COMMENT ON COLUMN biz_user_0.gender IS '性别 ( unknown=未知 / male=男 / female=女 )';
COMMENT ON COLUMN biz_user_0.tagline IS '用户签名';
COMMENT ON COLUMN biz_user_0.region IS '地区 ( 如：北京市-海淀区 )';
COMMENT ON COLUMN biz_user_0.birthday IS '生日时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN biz_user_0.info_ver IS '【 CQRS 关键字段 】个人信息版本号 ( 用于同步检测 )';
COMMENT ON COLUMN biz_user_0.user_status IS '用户状态 ( active=正常 / disabled=禁用 / deleted=已注销 )';
COMMENT ON COLUMN biz_user_0.deleted_at IS '软删除时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN biz_user_0.created_at IS '创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN biz_user_0.updated_at IS '更新时间戳 ( Unix 毫秒值 )';

-- 创建索引
CREATE UNIQUE INDEX uk_biz_user_email_0 ON biz_user_0(email) WHERE deleted_at = 0;

CREATE UNIQUE INDEX uk_biz_user_mobile_0 ON biz_user_0(mobile) WHERE deleted_at = 0;

CREATE INDEX idx_biz_user_nickname_0 ON biz_user_0(nickname) WHERE deleted_at = 0;

CREATE INDEX idx_biz_user_status_0 ON biz_user_0(user_status, deleted_at);

-- 分表 1: biz_user_1
DROP TABLE IF EXISTS biz_user_1;
CREATE TABLE biz_user_1 (
    id BIGINT PRIMARY KEY,

    -- 账号信息
    email VARCHAR(128) NOT NULL,
    mobile VARCHAR(16) NOT NULL,
    passwd VARCHAR(128) NOT NULL,

    -- 个人信息 ( 会被冗余到读取侧 )
    nickname VARCHAR(64) NOT NULL,
    avatar VARCHAR(256) NOT NULL DEFAULT '',
    gender gender_enum NOT NULL DEFAULT 'unknown',
    region VARCHAR(64) NOT NULL DEFAULT '',            -- 地区
    birthday BIGINT NOT NULL DEFAULT 0,                -- 生日 ( Unix 毫秒值 )
    tagline VARCHAR(256) NOT NULL DEFAULT '',          -- 用户签名

    -- 版本控制（CQRS 关键字段）
    info_ver INT NOT NULL DEFAULT 1,                   -- 个人信息版本号

    -- 状态管理
    user_status user_status_enum NOT NULL DEFAULT 'active',
    deleted_at BIGINT NOT NULL DEFAULT 0,              -- 软删除 ( 0 表示未删除 )

    -- 时间戳
    created_at BIGINT NOT NULL,
    updated_at BIGINT NOT NULL
);

COMMENT ON TABLE biz_user_1 IS '【 写入侧 】业务用户信息表';
COMMENT ON COLUMN biz_user_1.id IS '用户 ID';
COMMENT ON COLUMN biz_user_1.email IS '邮箱 ( 唯一 )';
COMMENT ON COLUMN biz_user_1.mobile IS '手机号 ( 唯一 )';
COMMENT ON COLUMN biz_user_1.passwd IS '密码';
COMMENT ON COLUMN biz_user_1.nickname IS '昵称 ( 会被冗余到会话视图 / 联系人视图 )';
COMMENT ON COLUMN biz_user_1.avatar IS '头像 ( 会被冗余到会话视图联系人视图 )';
COMMENT ON COLUMN biz_user_1.gender IS '性别 ( unknown=未知 / male=男 / female=女 )';
COMMENT ON COLUMN biz_user_1.tagline IS '用户签名';
COMMENT ON COLUMN biz_user_1.region IS '地区 ( 如：北京市-海淀区 )';
COMMENT ON COLUMN biz_user_1.birthday IS '生日时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN biz_user_1.info_ver IS '【 CQRS 关键字段 】个人信息版本号 ( 用于同步检测 )';
COMMENT ON COLUMN biz_user_1.user_status IS '用户状态 ( active=正常 / disabled=禁用 / deleted=已注销 )';
COMMENT ON COLUMN biz_user_1.deleted_at IS '软删除时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN biz_user_1.created_at IS '创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN biz_user_1.updated_at IS '更新时间戳 ( Unix 毫秒值 )';

-- 创建索引
CREATE UNIQUE INDEX uk_biz_user_email_1 ON biz_user_1(email) WHERE deleted_at = 0;

CREATE UNIQUE INDEX uk_biz_user_mobile_1 ON biz_user_1(mobile) WHERE deleted_at = 0;

CREATE INDEX idx_biz_user_nickname_1 ON biz_user_1(nickname) WHERE deleted_at = 0;

CREATE INDEX idx_biz_user_status_1 ON biz_user_1(user_status, deleted_at);

-- 分表 2: biz_user_2
DROP TABLE IF EXISTS biz_user_2;
CREATE TABLE biz_user_2 (
    id BIGINT PRIMARY KEY,

    -- 账号信息
    email VARCHAR(128) NOT NULL,
    mobile VARCHAR(16) NOT NULL,
    passwd VARCHAR(128) NOT NULL,

    -- 个人信息 ( 会被冗余到读取侧 )
    nickname VARCHAR(64) NOT NULL,
    avatar VARCHAR(256) NOT NULL DEFAULT '',
    gender gender_enum NOT NULL DEFAULT 'unknown',
    region VARCHAR(64) NOT NULL DEFAULT '',            -- 地区
    birthday BIGINT NOT NULL DEFAULT 0,                -- 生日 ( Unix 毫秒值 )
    tagline VARCHAR(256) NOT NULL DEFAULT '',          -- 用户签名

    -- 版本控制（CQRS 关键字段）
    info_ver INT NOT NULL DEFAULT 1,                   -- 个人信息版本号

    -- 状态管理
    user_status user_status_enum NOT NULL DEFAULT 'active',
    deleted_at BIGINT NOT NULL DEFAULT 0,              -- 软删除 ( 0 表示未删除 )

    -- 时间戳
    created_at BIGINT NOT NULL,
    updated_at BIGINT NOT NULL
);

COMMENT ON TABLE biz_user_2 IS '【 写入侧 】业务用户信息表';
COMMENT ON COLUMN biz_user_2.id IS '用户 ID';
COMMENT ON COLUMN biz_user_2.email IS '邮箱 ( 唯一 )';
COMMENT ON COLUMN biz_user_2.mobile IS '手机号 ( 唯一 )';
COMMENT ON COLUMN biz_user_2.passwd IS '密码';
COMMENT ON COLUMN biz_user_2.nickname IS '昵称 ( 会被冗余到会话视图 / 联系人视图 )';
COMMENT ON COLUMN biz_user_2.avatar IS '头像 ( 会被冗余到会话视图联系人视图 )';
COMMENT ON COLUMN biz_user_2.gender IS '性别 ( unknown=未知 / male=男 / female=女 )';
COMMENT ON COLUMN biz_user_2.tagline IS '用户签名';
COMMENT ON COLUMN biz_user_2.region IS '地区 ( 如：北京市-海淀区 )';
COMMENT ON COLUMN biz_user_2.birthday IS '生日时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN biz_user_2.info_ver IS '【 CQRS 关键字段 】个人信息版本号 ( 用于同步检测 )';
COMMENT ON COLUMN biz_user_2.user_status IS '用户状态 ( active=正常 / disabled=禁用 / deleted=已注销 )';
COMMENT ON COLUMN biz_user_2.deleted_at IS '软删除时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN biz_user_2.created_at IS '创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN biz_user_2.updated_at IS '更新时间戳 ( Unix 毫秒值 )';

-- 创建索引
CREATE UNIQUE INDEX uk_biz_user_email_2 ON biz_user_2(email) WHERE deleted_at = 0;

CREATE UNIQUE INDEX uk_biz_user_mobile_2 ON biz_user_2(mobile) WHERE deleted_at = 0;

CREATE INDEX idx_biz_user_nickname_2 ON biz_user_2(nickname) WHERE deleted_at = 0;

CREATE INDEX idx_biz_user_status_2 ON biz_user_2(user_status, deleted_at);

-- 分表 3: biz_user_3
DROP TABLE IF EXISTS biz_user_3;
CREATE TABLE biz_user_3 (
    id BIGINT PRIMARY KEY,

    -- 账号信息
    email VARCHAR(128) NOT NULL,
    mobile VARCHAR(16) NOT NULL,
    passwd VARCHAR(128) NOT NULL,

    -- 个人信息 ( 会被冗余到读取侧 )
    nickname VARCHAR(64) NOT NULL,
    avatar VARCHAR(256) NOT NULL DEFAULT '',
    gender gender_enum NOT NULL DEFAULT 'unknown',
    region VARCHAR(64) NOT NULL DEFAULT '',            -- 地区
    birthday BIGINT NOT NULL DEFAULT 0,                -- 生日 ( Unix 毫秒值 )
    tagline VARCHAR(256) NOT NULL DEFAULT '',          -- 用户签名

    -- 版本控制（CQRS 关键字段）
    info_ver INT NOT NULL DEFAULT 1,                   -- 个人信息版本号

    -- 状态管理
    user_status user_status_enum NOT NULL DEFAULT 'active',
    deleted_at BIGINT NOT NULL DEFAULT 0,              -- 软删除 ( 0 表示未删除 )

    -- 时间戳
    created_at BIGINT NOT NULL,
    updated_at BIGINT NOT NULL
);

COMMENT ON TABLE biz_user_3 IS '【 写入侧 】业务用户信息表';
COMMENT ON COLUMN biz_user_3.id IS '用户 ID';
COMMENT ON COLUMN biz_user_3.email IS '邮箱 ( 唯一 )';
COMMENT ON COLUMN biz_user_3.mobile IS '手机号 ( 唯一 )';
COMMENT ON COLUMN biz_user_3.passwd IS '密码';
COMMENT ON COLUMN biz_user_3.nickname IS '昵称 ( 会被冗余到会话视图 / 联系人视图 )';
COMMENT ON COLUMN biz_user_3.avatar IS '头像 ( 会被冗余到会话视图联系人视图 )';
COMMENT ON COLUMN biz_user_3.gender IS '性别 ( unknown=未知 / male=男 / female=女 )';
COMMENT ON COLUMN biz_user_3.tagline IS '用户签名';
COMMENT ON COLUMN biz_user_3.region IS '地区 ( 如：北京市-海淀区 )';
COMMENT ON COLUMN biz_user_3.birthday IS '生日时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN biz_user_3.info_ver IS '【 CQRS 关键字段 】个人信息版本号 ( 用于同步检测 )';
COMMENT ON COLUMN biz_user_3.user_status IS '用户状态 ( active=正常 / disabled=禁用 / deleted=已注销 )';
COMMENT ON COLUMN biz_user_3.deleted_at IS '软删除时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN biz_user_3.created_at IS '创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN biz_user_3.updated_at IS '更新时间戳 ( Unix 毫秒值 )';

-- 创建索引
CREATE UNIQUE INDEX uk_biz_user_email_3 ON biz_user_3(email) WHERE deleted_at = 0;

CREATE UNIQUE INDEX uk_biz_user_mobile_3 ON biz_user_3(mobile) WHERE deleted_at = 0;

CREATE INDEX idx_biz_user_nickname_3 ON biz_user_3(nickname) WHERE deleted_at = 0;

CREATE INDEX idx_biz_user_status_3 ON biz_user_3(user_status, deleted_at);

