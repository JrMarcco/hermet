package service

import (
	"github.com/JrMarcco/hermet/internal/pkg/xgin"
	"github.com/JrMarcco/hermet/internal/repo"
	"github.com/JrMarcco/jit/xjwt"
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

	Repo      repo.BizUserRepo
	AtManager xjwt.Manager[xgin.AuthUser] `name:"access-token-manager"`
	RtManager xjwt.Manager[xgin.AuthUser] `name:"refresh-token-manager"`
}

// newUserService 作为适配器，将 fx 的参数结构体转换为普通的函数调用。
func newUserService(p userServiceFxParams) UserService {
	return NewDefaultUserService(
		p.Repo,
		p.AtManager,
		p.RtManager,
	)
}
