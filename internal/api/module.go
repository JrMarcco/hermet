package api

import (
	"github.com/jrmarcco/hermet/internal/pkg/xgin"
	"go.uber.org/fx"
)

var APIFxModule = fx.Module(
	"api",
	fx.Provide(
		fx.Annotate(
			NewAuthHandler,
			fx.As(new(xgin.RouteRegistry)),
			fx.ResultTags(`group:"api_registry"`),
		),

		fx.Annotate(
			NewContactHandler,
			fx.As(new(xgin.RouteRegistry)),
			fx.ResultTags(`group:"api_registry"`),
		),

		// TODO: 临时 api 接口。
		fx.Annotate(
			NewAdminHandler,
			fx.As(new(xgin.RouteRegistry)),
			fx.ResultTags(`group:"api_registry"`),
		),
	),
)
