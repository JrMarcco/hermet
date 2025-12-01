package providers

import (
	"github.com/JrMarcco/hermet/internal/api/jwt"
	"github.com/JrMarcco/hermet/internal/pkg/xgin"
	"go.uber.org/fx"
)

var (
	ZapLoggerFxModule  = fx.Module("zap-logger", fx.Provide(newLogger))
	RedisFxModule      = fx.Module("redis", fx.Provide(newRedisCmdable))
	DBFxModule         = fx.Module("db", fx.Provide(newDBClient))
	MongoFxModule      = fx.Module("mongo", fx.Provide(newMongoClient))
	KafkaFxModule      = fx.Module("kafka", fx.Provide(newKafkaClient))
	JwtManagerFxModule = fx.Module("jwt-manager", fx.Provide(newJwtManager))
)

var JwtHandlerFxModule = fx.Module(
	"jwt-handler", fx.Provide(
		fx.Annotate(
			newRedisJwtHandler,
			fx.As(new(jwt.Handler)),
		),
	),
)

var MiddlewareFxModule = fx.Module(
	"middleware",
	fx.Provide(
		fx.Annotate(
			newCorsBuilder,
			fx.As(new(xgin.HandlerFuncBuilder)),
			fx.ResultTags(`group:"api_middleware"`),
		),
		fx.Annotate(
			newJwtBuilder,
			fx.As(new(xgin.HandlerFuncBuilder)),
			fx.ResultTags(`group:"api_middleware"`),
		),
	),
)
