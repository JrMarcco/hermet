package middleware

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/jrmarcco/hermet/internal/pkg/xgin"
	"github.com/jrmarcco/hermet/internal/pkg/xgin/xsession"
	"github.com/jrmarcco/jit/xjwt"
	"github.com/jrmarcco/jit/xset"
	authv1 "github.com/jrmarcco/synp-api/api/go/auth/v1"
)

var _ xgin.HandlerFuncBuilder = (*JwtBuilder)(nil)

type JwtBuilder struct {
	handler   xsession.Handler
	atManager xjwt.Manager[authv1.JwtPayload]
	ignores   xset.Set[string]
}

func NewJwtBuilder(
	handler xsession.Handler,
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

		token := strings.TrimPrefix(ctx.GetHeader(xgin.HeaderNameAccessToken), "Bearer ")
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
