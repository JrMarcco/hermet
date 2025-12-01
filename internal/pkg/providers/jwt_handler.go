package providers

import (
	"time"

	"github.com/JrMarcco/hermet/internal/api/jwt"
	"github.com/redis/go-redis/v9"
	"github.com/spf13/viper"
)

func newRedisJwtHandler(rdb redis.Cmdable) (*jwt.RedisJwtHandler, error) {
	var expiration time.Duration
	if err := viper.UnmarshalKey("hermet.session.expiration", &expiration); err != nil {
		return nil, err
	}
	return jwt.NewRedisJwtHandler(rdb, expiration)
}
