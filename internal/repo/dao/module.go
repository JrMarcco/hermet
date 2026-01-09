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
			NewDefaultUserContactDao,
			fx.As(new(UserContactDao)),
			fx.ParamTags(`name:"db_sharding_clients"`, `name:"user_contact_shard_helper"`),
		),
		fx.Annotate(
			NewDefaultContactApplicationDao,
			fx.As(new(ContactApplicationDao)),
			fx.ParamTags(`name:"db_sharding_clients"`, `name:"contact_application_shard_helper"`),
		),

		fx.Annotate(
			NewDefaultChannelApplicationDao,
			fx.As(new(ChannelApplicationDao)),
			fx.ParamTags(`name:"db_sharding_clients"`, `name:"channel_application_shard_helper"`),
		),

		fx.Annotate(
			NewMongoMessageDao,
			fx.As(new(MessageDao)),
		),
	),
)
