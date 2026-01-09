package session

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/jrmarcco/hermet/internal/pkg/xgin/xsession"
	"github.com/redis/go-redis/v9"
)

var _ xsession.Handler = (*RedisSessionHandler)(nil)

// RedisSessionHandler 是 session 管理器，使用 Redis 存储 session。
type RedisSessionHandler struct {
	rdb        redis.Cmdable
	expiration time.Duration
}

func (h *RedisSessionHandler) CreateSession(ctx context.Context, sid string, uid uint64) error {
	return h.rdb.Set(ctx, h.key(sid), uid, h.expiration).Err()
}

func (h *RedisSessionHandler) CheckSession(ctx context.Context, sid string, uid uint64) error {
	storedUID, err := h.rdb.Get(ctx, h.key(sid)).Uint64()
	if err != nil {
		if errors.Is(err, redis.Nil) {
			return errors.New("been signed out")
		}
		return err
	}
	if storedUID != uid {
		return errors.New("session user mismatch")
	}
	return nil
}

func (h *RedisSessionHandler) RefreshSession(ctx context.Context, sid string) error {
	return h.rdb.Expire(ctx, h.key(sid), h.expiration).Err()
}

func (h *RedisSessionHandler) ClearSession(ctx context.Context, sid string) error {
	return h.rdb.Del(ctx, h.key(sid)).Err()
}

func (h *RedisSessionHandler) key(sid string) string {
	return fmt.Sprintf("user:sid:%s", sid)
}

func NewRedisSessionHandler(rdb redis.Cmdable, expiration time.Duration) (*RedisSessionHandler, error) {
	if rdb == nil {
		return nil, errors.New("redis client is nil")
	}
	if expiration <= 0 {
		return nil, errors.New("expiration must be greater than 0")
	}

	return &RedisSessionHandler{
		rdb:        rdb,
		expiration: expiration,
	}, nil
}
