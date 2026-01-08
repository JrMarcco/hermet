-- ============================================================================
-- 写入侧 ( Write Side ) - 标准化设计
-- ============================================================================

-- 用户状态枚举 ( active=正常 / disabled=禁用 / deleted=已注销 )
DROP TYPE IF EXISTS user_status_enum CASCADE;
CREATE TYPE user_status_enum AS ENUM ('active', 'disabled', 'deleted');

-- 用户性别枚举 ( unknown=未知 / male=男 / female=女 )
DROP TYPE IF EXISTS gender_enum CASCADE;
CREATE TYPE gender_enum AS ENUM ('unknown', 'male', 'female');

-- 业务用户信息表
DROP TABLE IF EXISTS biz_user;
CREATE TABLE biz_user (
    id BIGINT PRIMARY KEY,

    -- 账号信息
    email VARCHAR(128) NOT NULL,
    mobile VARCHAR(16) NOT NULL,
    passwd VARCHAR(128) NOT NULL,

    -- 个人信息（会被冗余到读取侧）
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
    deleted_at BIGINT NOT NULL DEFAULT 0,              -- 软删除 ( 0表示未删除 )

    -- 时间戳
    created_at BIGINT NOT NULL,
    updated_at BIGINT NOT NULL
);

COMMENT ON TABLE biz_user IS '【 写入侧 】业务用户信息表';
COMMENT ON COLUMN biz_user.id IS '用户 ID';
COMMENT ON COLUMN biz_user.email IS '邮箱 ( 唯一 )';
COMMENT ON COLUMN biz_user.mobile IS '手机号 ( 唯一 )';
COMMENT ON COLUMN biz_user.passwd IS '密码';
COMMENT ON COLUMN biz_user.nickname IS '昵称 ( 会被冗余到会话视图 / 联系人视图 )';
COMMENT ON COLUMN biz_user.avatar IS '头像 ( 会被冗余到会话视图联系人视图 )';
COMMENT ON COLUMN biz_user.gender IS '性别 ( unknown=未知 / male=男 / female=女 )';
COMMENT ON COLUMN biz_user.tagline IS '用户签名';
COMMENT ON COLUMN biz_user.region IS '地区 ( 如：北京市-海淀区 )';
COMMENT ON COLUMN biz_user.birthday IS '生日时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN biz_user.info_ver IS '【 CQRS 关键字段 】个人信息版本号 ( 用于同步检测 )';
COMMENT ON COLUMN biz_user.user_status IS '用户状态 ( active=正常 / disabled=禁用 / deleted=已注销 )';
COMMENT ON COLUMN biz_user.deleted_at IS '软删除时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN biz_user.created_at IS '创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN biz_user.updated_at IS '更新时间戳 ( Unix 毫秒值 )';

-- 索引
-- 1. 账号登录相关
CREATE UNIQUE INDEX uk_biz_user_email ON biz_user(email) WHERE deleted_at = 0;
CREATE UNIQUE INDEX uk_biz_user_mobile ON biz_user(mobile) WHERE deleted_at = 0;

-- 2. 搜索用户 ( 昵称模糊搜索 )
CREATE INDEX idx_biz_user_nickname ON biz_user(nickname) WHERE deleted_at = 0;

-- 3. 状态查询
CREATE INDEX idx_biz_user_status ON biz_user(user_status, deleted_at);

-- ============================================================================
-- 测试数据
-- ============================================================================

-- 插入初始用户数据
INSERT INTO biz_user (
    id,
    email,
    mobile,
    passwd,
    nickname,
    avatar,
    gender,
    tagline,
    region,
    birthday,
    info_ver,
    user_status,
    deleted_at,
    created_at,
    updated_at
) VALUES (
    1,
    'jrmarcco@gmail.com',
    '13100131000',
    '$2a$10$besICPqbCRWOocqlsaKXV.rniGRyCNPLHeFT.osXbhgisW4XSW/um',
    'jrmarcco',
    'https://avatars.githubusercontent.com/u/jrmarcco',
    'male',
    'Stay hungry, stay foolish.',
    '',
    0,  -- 未设置生日
    1,
    'active',
    0,  -- 未删除
    EXTRACT(EPOCH FROM NOW()) * 1000,
    EXTRACT(EPOCH FROM NOW()) * 1000
);

-- hermet_0
-- 以 jrmarcco@gmail.com 为 sharder 插入数据到分表
INSERT INTO biz_user_2 (
    id,
    email,
    mobile,
    passwd,
    nickname,
    avatar,
    gender,
    tagline,
    region,
    birthday,
    info_ver,
    user_status,
    deleted_at,
    created_at,
    updated_at
) VALUES (
    134605228232032256,
    'jrmarcco@gmail.com',
    '13100131000',
    '$2a$10$besICPqbCRWOocqlsaKXV.rniGRyCNPLHeFT.osXbhgisW4XSW/um',
    'jrmarcco',
    'https://avatars.githubusercontent.com/u/jrmarcco',
    'male',
    'Stay hungry, stay foolish.',
    '',
    0,
    1,
    'active',
    0,
    EXTRACT(EPOCH FROM NOW()) * 1000,
    EXTRACT(EPOCH FROM NOW()) * 1000
);
