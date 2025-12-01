package api

import (
	"github.com/jrmarcco/hermet/internal/pkg/xgin"
	"go.uber.org/fx"
)

var APIFxModule = fx.Module(
	"api",
	fx.Provide(
		fx.Annotate(
			NewUserHandler,
			fx.As(new(xgin.RouteRegistry)),
			fx.ResultTags(`group:"api_registry"`),
		),
	),
)
