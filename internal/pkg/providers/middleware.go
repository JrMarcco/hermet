package providers

import (
	"net/http"
	"net/url"
	"slices"
	"strings"
	"time"

	"github.com/JrMarcco/hermet/internal/api/jwt"
	"github.com/JrMarcco/hermet/internal/pkg/xgin"
	"github.com/JrMarcco/hermet/internal/pkg/xgin/middleware"
	"github.com/JrMarcco/jit/xjwt"
	"github.com/JrMarcco/jit/xset"
	"github.com/spf13/viper"
	"go.uber.org/fx"
)

func newCorsBuilder() *middleware.CorsBuilder {
	type config struct {
		MaxAge    int      `mapstructure:"max_age"`
		Hostnames []string `mapstructure:"hostnames"`
	}
	cfg := config{}
	if err := viper.UnmarshalKey("cors", &cfg); err != nil {
		panic(err)
	}

	builder := middleware.NewCorsBuilder().
		AllowCredentials(true).
		AllowMethods([]string{http.MethodGet, http.MethodPost, http.MethodPut, http.MethodDelete, http.MethodOptions}).
		AllowHeaders([]string{"Content-Length", "Content-Type", "Authorization", "Accept", "Origin", xgin.HeaderNameAccessToken}).
		MaxAge(time.Duration(cfg.MaxAge) * time.Second).
		AllowOriginFunc(func(origin string) bool {
			if origin == "" {
				return false
			}
			u, err := url.Parse(origin)
			if err != nil {
				return false
			}
			reqHostname := u.Hostname()
			return slices.Contains(cfg.Hostnames, reqHostname)
		})
	return builder
}

type jwtBuilderFxParams struct {
	fx.In

	Handler   jwt.Handler
	AtManager xjwt.Manager[xgin.AuthUser] `name:"access-token-manager"`
}

func newJwtBuilder(params jwtBuilderFxParams) *middleware.JwtBuilder {
	var ignores []string
	if err := viper.UnmarshalKey("ignores", &ignores); err != nil {
		panic(err)
	}

	ts, err := xset.NewTreeSet(strings.Compare)
	if err != nil {
		panic(err)
	}
	for _, ignore := range ignores {
		ts.Add(ignore)
	}
	return middleware.NewJwtBuilder(params.Handler, params.AtManager, ts)
}
