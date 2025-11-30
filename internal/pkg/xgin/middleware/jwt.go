package middleware

import (
	"net/http"

	webjwt "github.com/JrMarcco/hermet/internal/api/jwt"
	"github.com/JrMarcco/hermet/internal/pkg/xgin"
	"github.com/JrMarcco/jit/xjwt"
	"github.com/JrMarcco/jit/xset"
	"github.com/gin-gonic/gin"
)

var _ xgin.HandlerFuncBuilder = (*JwtBuilder)(nil)

type JwtBuilder struct {
	handler   webjwt.Handler
	atManager xjwt.Manager[xgin.AuthUser]
	ignores   xset.Set[string]
}

func (b *JwtBuilder) Build() gin.HandlerFunc {
	return func(ctx *gin.Context) {
		if b.ignores != nil && b.ignores.Exist(ctx.Request.URL.Path) {
			ctx.Next()
			return
		}

		token := b.handler.ExtractAccessToken(ctx)
		if token == "" {
			ctx.AbortWithStatus(http.StatusUnauthorized)
			return
		}

		decrypted, err := b.atManager.Decrypt(token)
		if err != nil {
			ctx.AbortWithStatus(http.StatusUnauthorized)
			return
		}

		au := decrypted.Data

		ctx.Set(xgin.ContextKeyAuthUser, au)
		ctx.Next()
	}
}

func NewJwtBuilder(
	handler webjwt.Handler, atManager xjwt.Manager[xgin.AuthUser], ignores xset.Set[string],
) *JwtBuilder {
	return &JwtBuilder{
		handler:   handler,
		atManager: atManager,
		ignores:   ignores,
	}
}
