package providers

import (
	"time"

	"github.com/JrMarcco/hermet/internal/pkg/xgin"
	"github.com/JrMarcco/jit/xjwt"
	"github.com/spf13/viper"
	"go.uber.org/fx"
)

type jwtFxResult struct {
	fx.Out

	AtManager xjwt.Manager[xgin.AuthUser] `name:"access-token-manager"`
	RtManager xjwt.Manager[xgin.AuthUser] `name:"refresh-token-manager"`
}

func newJwtManager() (jwtFxResult, error) {
	cfg, err := loadJwtConfig()
	if err != nil {
		return jwtFxResult{}, err
	}

	atManager, err := newAccessTokenManager(cfg)
	if err != nil {
		return jwtFxResult{}, err
	}
	rtManager, err := newRefreshTokenManager(cfg)
	if err != nil {
		return jwtFxResult{}, err
	}

	return jwtFxResult{
		AtManager: atManager,
		RtManager: rtManager,
	}, nil
}

// newAccessTokenManager 创建用于 Access Token 的 Manager
func newAccessTokenManager(cfg *jwtConfig) (xjwt.Manager[xgin.AuthUser], error) {
	claimsCfg := xjwt.NewClaimsConfig(
		xjwt.WithExpiration(cfg.Access.Expiration),
		xjwt.WithIssuer(cfg.Access.Issuer),
	)

	manager, err := xjwt.NewEd25519ManagerBuilder[xgin.AuthUser](cfg.Private, cfg.Public).
		ClaimsConfig(claimsCfg).
		Build()
	if err != nil {
		return nil, err
	}
	return manager, nil
}

// newRefreshTokenManager 创建用于 Refresh Token 的 Manager
func newRefreshTokenManager(cfg *jwtConfig) (xjwt.Manager[xgin.AuthUser], error) {
	claimsCfg := xjwt.NewClaimsConfig(
		xjwt.WithExpiration(cfg.Access.Expiration),
		xjwt.WithIssuer(cfg.Refresh.Issuer),
	)

	manager, err := xjwt.NewEd25519ManagerBuilder[xgin.AuthUser](cfg.Private, cfg.Public).
		ClaimsConfig(claimsCfg).
		Build()
	if err != nil {
		return nil, err
	}
	return manager, nil
}

// loadJwtConfig 加载配置
func loadJwtConfig() (*jwtConfig, error) {
	cfg := &jwtConfig{}
	if err := viper.UnmarshalKey("jwt", cfg); err != nil {
		return nil, err
	}
	return cfg, nil
}

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
