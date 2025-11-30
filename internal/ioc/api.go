package ioc

import (
	"time"

	"github.com/JrMarcco/hermet/internal/api"
	webjwt "github.com/JrMarcco/hermet/internal/api/jwt"
	"github.com/JrMarcco/hermet/internal/pkg/xgin"
	"github.com/JrMarcco/hermet/internal/service"
	"github.com/redis/go-redis/v9"
	"github.com/spf13/viper"
	"go.uber.org/fx"
	"go.uber.org/zap"
)

var APIFxOpt = fx.Module(
	"api",
	fx.Provide(
		fx.Annotate(
			initRedisJwtHandler,
			fx.As(new(webjwt.Handler)),
		),

		fx.Annotate(
			initUserHandler,
			fx.As(new(xgin.RouteRegistry)),
			fx.ResultTags(`group:"api_registry"`),
		),
	),
)

type redisJwtHandlerFxParams struct {
	fx.In

	Rdb redis.Cmdable
}

func initRedisJwtHandler(params redisJwtHandlerFxParams) *webjwt.RedisJwtHandler {
	var expiration time.Duration
	if err := viper.UnmarshalKey("session.expiration", &expiration); err != nil {
		panic(err)
	}
	return webjwt.NewRedisJwtHandler(params.Rdb, expiration)
}

type userHandlerFxParams struct {
	Handler webjwt.Handler
	Svc     service.UserService
	Logger  *zap.Logger
}

func initUserHandler(params userHandlerFxParams) *api.UserHandler {
	return api.NewUserHandler(params.Handler, params.Svc, params.Logger)
}
