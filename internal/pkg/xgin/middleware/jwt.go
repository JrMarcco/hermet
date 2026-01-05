package middleware

import (
	"net/http"

	"github.com/gin-gonic/gin"
	webjwt "github.com/jrmarcco/hermet/internal/api/jwt"
	"github.com/jrmarcco/hermet/internal/pkg/xgin"
	"github.com/jrmarcco/jit/xjwt"
	"github.com/jrmarcco/jit/xset"
	authv1 "github.com/jrmarcco/synp-api/api/go/auth/v1"
)

var _ xgin.HandlerFuncBuilder = (*JwtBuilder)(nil)

type JwtBuilder struct {
	handler   webjwt.Handler
	atManager xjwt.Manager[authv1.JwtPayload]
	ignores   xset.Set[string]
}

func NewJwtBuilder(
	handler webjwt.Handler,
	atManager xjwt.Manager[authv1.JwtPayload],
	ignores xset.Set[string],
) *JwtBuilder {
	return &JwtBuilder{
		handler:   handler,
		atManager: atManager,
		ignores:   ignores,
	}
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

		ctx.Set(xgin.ContextKeyAuthUser, xgin.ContextUser{
			BID: decrypted.Data.BizId,
			UID: decrypted.Data.UserId,
			SID: decrypted.Data.SessionId,
		})
		ctx.Next()
	}
}
