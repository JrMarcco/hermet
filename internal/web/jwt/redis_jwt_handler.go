package jwt

import (
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/JrMarcco/hermet/internal/pkg/xgin"
	"github.com/gin-gonic/gin"
	"github.com/redis/go-redis/v9"
)

var _ Handler = (*RedisJwtHandler)(nil)

type RedisJwtHandler struct {
	rdb        redis.Cmdable
	expiration time.Duration
}

func (h *RedisJwtHandler) ExtractAccessToken(ctx *gin.Context) string {
	token := ctx.GetHeader(xgin.HeaderNameAccessToken)
	if token == "" {
		return token
	}
	return strings.TrimPrefix(token, "Bearer ")
}

func (h *RedisJwtHandler) CreateSession(ctx *gin.Context, sid string, uid uint64) error {
	return h.rdb.Set(ctx, h.key(sid), uid, h.expiration).Err()
}

func (h *RedisJwtHandler) CheckSession(ctx *gin.Context, sid string, uid uint64) error {
	storedUid, err := h.rdb.Get(ctx, h.key(sid)).Uint64()
	if err != nil {
		if errors.Is(err, redis.Nil) {
			return errors.New("been signed out")
		}
		return err
	}
	if storedUid != uid {
		return errors.New("session user mismatch")
	}
	return nil
}

func (h *RedisJwtHandler) RefreshSession(ctx *gin.Context, sid string) error {
	return h.rdb.Expire(ctx, h.key(sid), h.expiration).Err()
}

func (h *RedisJwtHandler) ClearSession(ctx *gin.Context, sid string) error {
	return h.rdb.Del(ctx, h.key(sid)).Err()
}

func (h *RedisJwtHandler) key(sid string) string {
	return fmt.Sprintf("user:sid:%s", sid)
}

func NewRedisJwtHandler(rdb redis.Cmdable, expiration time.Duration) *RedisJwtHandler {
	return &RedisJwtHandler{
		rdb:        rdb,
		expiration: expiration,
	}
}
