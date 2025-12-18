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

		// message repo
		fx.Annotate(
			NewDefaultMessageRepo,
			fx.As(new(MessageRepo)),
		),
	),
)
