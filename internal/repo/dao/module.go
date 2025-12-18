package dao

import "go.uber.org/fx"

var DaoFxModule = fx.Module(
	"dao",
	fx.Provide(
		fx.Annotate(
			NewDefaultBizUserDao,
			fx.As(new(BizUserDao)),
		),
		fx.Annotate(
			NewMongoMessageDao,
			fx.As(new(MessageDao)),
		),
	),
)
