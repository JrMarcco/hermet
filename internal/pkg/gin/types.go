package gin

import "github.com/gin-gonic/gin"

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
