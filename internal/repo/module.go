package repo

import (
	"go.uber.org/fx"
)

var RepoFxModule = fx.Module(
	"repo",
	fx.Provide(
		// biz user repo
		fx.Annotate(
			NewDefaultBizUserRepo,
			fx.As(new(BizUserRepo)),
		),

		// user contact repo
		fx.Annotate(
			NewDefaultUserContactRepo,
			fx.As(new(UserContactRepo)),
		),
		// contact application repo
		fx.Annotate(
			NewDefaultContactApplicationRepo,
			fx.As(new(ContactApplicationRepo)),
		),

		// channel application repo
		fx.Annotate(
			NewDefaultChannelApplicationRepo,
			fx.As(new(ChannelApplicationRepo)),
		),

		// message repo
		fx.Annotate(
			NewDefaultMessageRepo,
			fx.As(new(MessageRepo)),
		),
	),
)
