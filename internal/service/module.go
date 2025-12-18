package service

import (
	"github.com/jrmarcco/hermet/internal/repo"
	"github.com/jrmarcco/jit/xjwt"
	authv1 "github.com/jrmarcco/synp-api/api/go/auth/v1"
	"go.uber.org/fx"
)

var ServiceFxModule = fx.Module(
	"service",
	fx.Provide(
		newUserService,
	),
)

type userServiceFxParams struct {
	fx.In

	Repo        repo.BizUserRepo
	MessageRepo repo.MessageRepo

	AtManager xjwt.Manager[authv1.JwtPayload] `name:"access-token-manager"`
	RtManager xjwt.Manager[authv1.JwtPayload] `name:"refresh-token-manager"`
}

// newUserService 作为适配器，将 fx 的参数结构体转换为普通的函数调用。
func newUserService(p userServiceFxParams) UserService {
	return NewDefaultUserService(
		p.Repo,
		p.MessageRepo,
		p.AtManager,
		p.RtManager,
	)
}
