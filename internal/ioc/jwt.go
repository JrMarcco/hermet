package ioc

import (
	"time"

	"github.com/JrMarcco/hermet/internal/pkg/xgin"
	"github.com/JrMarcco/jit/xjwt"
	"github.com/spf13/viper"
	"go.uber.org/fx"
)

var JwtManagerOpt = fx.Module(
	"jwt",
	fx.Provide(
		fx.Annotate(
			initAccessTokenManager,
			fx.ResultTags(`name:"access-token-manager"`),
		),
		fx.Annotate(
			initRefreshTokenManager,
			fx.ResultTags(`name:"refresh-token-manager"`),
		),
	),
)

type jwtTokenConfig struct {
	Issuer     string        `mapstructure:"issuer"`
	Expiration time.Duration `mapstructure:"expiration"`
}

type jwtConfig struct {
	Private string         `mapstructure:"private"`
	Public  string         `mapstructure:"public"`
	Access  jwtTokenConfig `mapstructure:"access"`
	Refresh jwtTokenConfig `mapstructure:"refresh"`
}

// loadJwtConfig 加载配置
func loadJwtConfig() *jwtConfig {
	cfg := &jwtConfig{}
	if err := viper.UnmarshalKey("jwt", cfg); err != nil {
		panic(err)
	}
	return cfg
}

// initAccessTokenManager 创建用于 Access Token 的 Manager
func initAccessTokenManager() xjwt.Manager[xgin.AuthUser] {
	cfg := loadJwtConfig()

	claimsCfg := xjwt.NewClaimsConfig(
		xjwt.WithExpiration(cfg.Access.Expiration),
		xjwt.WithIssuer(cfg.Access.Issuer),
	)

	manager, err := xjwt.NewEd25519ManagerBuilder[xgin.AuthUser](cfg.Private, cfg.Public).
		ClaimsConfig(claimsCfg).
		Build()
	if err != nil {
		panic(err)
	}
	return manager
}

// initRefreshTokenManager 创建用于 Refresh Token 的 Manager
func initRefreshTokenManager() xjwt.Manager[xgin.AuthUser] {
	cfg := loadJwtConfig()

	claimsCfg := xjwt.NewClaimsConfig(
		xjwt.WithExpiration(cfg.Access.Expiration),
		xjwt.WithIssuer(cfg.Refresh.Issuer),
	)

	manager, err := xjwt.NewEd25519ManagerBuilder[xgin.AuthUser](cfg.Private, cfg.Public).
		ClaimsConfig(claimsCfg).
		Build()
	if err != nil {
		panic(err)
	}
	return manager
}
