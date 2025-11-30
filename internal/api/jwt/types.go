package jwt

import (
	"context"

	"github.com/gin-gonic/gin"
)

//go:generate mockgen -source=types.go -destination=mock/jwt_handler.mock.go -package=jwtmock -typed Handler

type Handler interface {
	ExtractAccessToken(ctx *gin.Context) string
	CreateSession(ctx context.Context, sid string, uid uint64) error
	CheckSession(ctx context.Context, sid string, uid uint64) error
	RefreshSession(ctx context.Context, sid string) error
	ClearSession(ctx context.Context, sid string) error
}
