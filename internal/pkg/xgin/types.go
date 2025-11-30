package xgin

import "github.com/gin-gonic/gin"

const (
	HeaderNameAccessToken = "x-access-token"
	ContextKeyAuthUser    = "auth-user"
)

// RouteRegistry 是注册路由的接口。
// HTTP Handler 通过实现这个接口，可以注册路由到 gin 引擎中。
type RouteRegistry interface {
	Register(engine *gin.Engine)
}

// R 是 HTTP Handler统一返回结构体。
type R struct {
	Code int    `json:"code"`
	Msg  string `json:"message"`
	Data any    `json:"data"`
}

type AuthUser struct {
	Sid string `json:"sid"` // session id
	Bid uint64 `json:"bid"` // biz id
	Uid uint64 `json:"uid"` // user id
}

// HandlerFuncBuilder 是构建 gin.HandlerFunc 的接口。
type HandlerFuncBuilder interface {
	Build() gin.HandlerFunc
}
