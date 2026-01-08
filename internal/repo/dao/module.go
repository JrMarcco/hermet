package dao

import "go.uber.org/fx"

var DaoFxModule = fx.Module(
	"dao",
	fx.Provide(
		fx.Annotate(
			NewDefaultBizUserDao,
			fx.As(new(BizUserDao)),
			fx.ParamTags(`name:"db_sharding_clients"`, `name:"biz_user_shard_helper"`),
		),
		fx.Annotate(
			NewMongoMessageDao,
			fx.As(new(MessageDao)),
		),
	),
)
