package xsession

import (
	"context"
)

//go:generate mockgen -source=handler.go -destination=mock/jwt_handler.mock.go -package=jwtmock -typed Handler

// Handler 是 session 管理器接口，负责 session 的创建、校验、刷新和清除。
type Handler interface {
	// CreateSession 创建用户会话。
	CreateSession(ctx context.Context, sid string, uid uint64) error

	// CheckSession 校验用户会话。
	CheckSession(ctx context.Context, sid string, uid uint64) error

	// RefreshSession 刷新会话过期时间。
	RefreshSession(ctx context.Context, sid string) error

	// ClearSession 清除用户会话。
	ClearSession(ctx context.Context, sid string) error
}
