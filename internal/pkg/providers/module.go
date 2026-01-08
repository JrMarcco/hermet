package providers

import (
	"github.com/jrmarcco/hermet/internal/api/jwt"
	"github.com/jrmarcco/hermet/internal/pkg/xgin"
	"go.uber.org/fx"
)

var (
	ZapLoggerFxModule  = fx.Module("zap-logger", fx.Provide(newZapLogger))
	RedisFxModule      = fx.Module("redis", fx.Provide(newRedisCmdable))
	MongoFxModule      = fx.Module("mongo", fx.Provide(newMongoClient))
	KafkaFxModule      = fx.Module("kafka", fx.Provide(newKafkaClient))
	JwtManagerFxModule = fx.Module("jwt-manager", fx.Provide(newJwtManager))
)

var DBFxModule = fx.Module(
	"db",
	fx.Provide(
		fx.Annotate(
			newDBShardingClients,
			fx.ResultTags(`name:"db_sharding_clients"`),
		),
	),
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

var ShardingFxModule = fx.Module(
	"sharding",
	fx.Provide(
		newIDGen,
		fx.Annotate(
			newBizUserShardHelper,
			fx.ResultTags(`name:"biz_user_shard_helper"`),
		),
	),
)
