-- ============================================
-- 分库分表SQL脚本
-- 数据库: hermet_0
-- 分表数量: 4
-- 生成时间: 2026-01-07 22:31:44
-- 原始文件: ./01_user_init.sql
-- ============================================

-- ============================================
-- 表: biz_user (分表数: 4)
-- ============================================

-- 分表 0: biz_user_0
DROP TABLE IF EXISTS biz_user_0;
CREATE TABLE biz_user_0 (
    id BIGINT PRIMARY KEY,
    email VARCHAR(128) NOT NULL,
    mobile VARCHAR(16) NOT NULL,
    avatar VARCHAR(256) DEFAULT '' NOT NULL,
    passwd VARCHAR(128) NOT NULL,
    nickname VARCHAR(64) NOT NULL,
    created_at BIGINT NOT NULL,
    updated_at BIGINT NOT NULL
);

COMMENT ON COLUMN biz_user_0.id IS 'id';
COMMENT ON COLUMN biz_user_0.email IS '邮箱';
COMMENT ON COLUMN biz_user_0.mobile IS '手机';
COMMENT ON COLUMN biz_user_0.avatar IS '头像';
COMMENT ON COLUMN biz_user_0.passwd IS '密码（请存储哈希后的值）';
COMMENT ON COLUMN biz_user_0.nickname IS '昵称';
COMMENT ON COLUMN biz_user_0.created_at IS '创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN biz_user_0.updated_at IS '更新时间戳 ( Unix 毫秒值 )';

-- 创建索引
CREATE INDEX idx_biz_user_email_0 ON biz_user_0(email);
CREATE INDEX idx_biz_user_mobile_0 ON biz_user_0(mobile);


-- 分表 1: biz_user_1
DROP TABLE IF EXISTS biz_user_1;
CREATE TABLE biz_user_1 (
    id BIGINT PRIMARY KEY,
    email VARCHAR(128) NOT NULL,
    mobile VARCHAR(16) NOT NULL,
    avatar VARCHAR(256) DEFAULT '' NOT NULL,
    passwd VARCHAR(128) NOT NULL,
    nickname VARCHAR(64) NOT NULL,
    created_at BIGINT NOT NULL,
    updated_at BIGINT NOT NULL
);

COMMENT ON COLUMN biz_user_1.id IS 'id';
COMMENT ON COLUMN biz_user_1.email IS '邮箱';
COMMENT ON COLUMN biz_user_1.mobile IS '手机';
COMMENT ON COLUMN biz_user_1.avatar IS '头像';
COMMENT ON COLUMN biz_user_1.passwd IS '密码（请存储哈希后的值）';
COMMENT ON COLUMN biz_user_1.nickname IS '昵称';
COMMENT ON COLUMN biz_user_1.created_at IS '创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN biz_user_1.updated_at IS '更新时间戳 ( Unix 毫秒值 )';

-- 创建索引
CREATE INDEX idx_biz_user_email_1 ON biz_user_1(email);
CREATE INDEX idx_biz_user_mobile_1 ON biz_user_1(mobile);


-- 分表 2: biz_user_2
DROP TABLE IF EXISTS biz_user_2;
CREATE TABLE biz_user_2 (
    id BIGINT PRIMARY KEY,
    email VARCHAR(128) NOT NULL,
    mobile VARCHAR(16) NOT NULL,
    avatar VARCHAR(256) DEFAULT '' NOT NULL,
    passwd VARCHAR(128) NOT NULL,
    nickname VARCHAR(64) NOT NULL,
    created_at BIGINT NOT NULL,
    updated_at BIGINT NOT NULL
);

COMMENT ON COLUMN biz_user_2.id IS 'id';
COMMENT ON COLUMN biz_user_2.email IS '邮箱';
COMMENT ON COLUMN biz_user_2.mobile IS '手机';
COMMENT ON COLUMN biz_user_2.avatar IS '头像';
COMMENT ON COLUMN biz_user_2.passwd IS '密码（请存储哈希后的值）';
COMMENT ON COLUMN biz_user_2.nickname IS '昵称';
COMMENT ON COLUMN biz_user_2.created_at IS '创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN biz_user_2.updated_at IS '更新时间戳 ( Unix 毫秒值 )';

-- 创建索引
CREATE INDEX idx_biz_user_email_2 ON biz_user_2(email);
CREATE INDEX idx_biz_user_mobile_2 ON biz_user_2(mobile);


-- 分表 3: biz_user_3
DROP TABLE IF EXISTS biz_user_3;
CREATE TABLE biz_user_3 (
    id BIGINT PRIMARY KEY,
    email VARCHAR(128) NOT NULL,
    mobile VARCHAR(16) NOT NULL,
    avatar VARCHAR(256) DEFAULT '' NOT NULL,
    passwd VARCHAR(128) NOT NULL,
    nickname VARCHAR(64) NOT NULL,
    created_at BIGINT NOT NULL,
    updated_at BIGINT NOT NULL
);

COMMENT ON COLUMN biz_user_3.id IS 'id';
COMMENT ON COLUMN biz_user_3.email IS '邮箱';
COMMENT ON COLUMN biz_user_3.mobile IS '手机';
COMMENT ON COLUMN biz_user_3.avatar IS '头像';
COMMENT ON COLUMN biz_user_3.passwd IS '密码（请存储哈希后的值）';
COMMENT ON COLUMN biz_user_3.nickname IS '昵称';
COMMENT ON COLUMN biz_user_3.created_at IS '创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN biz_user_3.updated_at IS '更新时间戳 ( Unix 毫秒值 )';

-- 创建索引
CREATE INDEX idx_biz_user_email_3 ON biz_user_3(email);
CREATE INDEX idx_biz_user_mobile_3 ON biz_user_3(mobile);


