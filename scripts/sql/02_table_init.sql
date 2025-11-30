-- 系统用户信息表
DROP TABLE IF EXISTS biz_user;
CREATE TABLE biz_user (
    id BIGSERIAL PRIMARY KEY,
    email VARCHAR(128) NOT NULL,
    mobile VARCHAR(16) NOT NULL,
    avatar VARCHAR(256) DEFAULT '' NOT NULL,
    passwd VARCHAR(128) NOT NULL,
    nickname VARCHAR(64) NOT NULL,
    created_at BIGINT NOT NULL,
    updated_at BIGINT NOT NULL,
    CONSTRAINT uk_mobile UNIQUE (mobile)
);

COMMENT ON TABLE biz_user IS '业务用户信息表';
COMMENT ON COLUMN biz_user.id IS 'id';
COMMENT ON COLUMN biz_user.email IS '邮箱';
COMMENT ON COLUMN biz_user.mobile IS '手机';
COMMENT ON COLUMN biz_user.avatar IS '头像';
COMMENT ON COLUMN biz_user.passwd IS '密码（请存储哈希后的值）';
COMMENT ON COLUMN biz_user.nickname IS '昵称';
COMMENT ON COLUMN biz_user.created_at IS '创建时间戳 ( Unix 毫秒值 )';
COMMENT ON COLUMN biz_user.updated_at IS '更新时间戳 ( Unix 毫秒值 )';

-- 插入初始用户数据
INSERT INTO sys_user (
    id,
    email,
    mobile,
    avatar,
    passwd,
    nickname,
    created_at,
    updated_at
) VALUES (
    1,
    'jrmarcco@gmail.com',
    '13800138000',
    '',
    '$2a$10$besICPqbCRWOocqlsaKXV.rniGRyCNPLHeFT.osXbhgisW4XSW/um',
    'jrmarcco',
    EXTRACT(EPOCH FROM NOW()) * 1000,
    EXTRACT(EPOCH FROM NOW()) * 1000
);
