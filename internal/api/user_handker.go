package api

import (
	"context"
	"fmt"
	"net/http"
	"time"

	webjwt "github.com/JrMarcco/hermet/internal/api/jwt"
	"github.com/JrMarcco/hermet/internal/errs"
	"github.com/JrMarcco/hermet/internal/pkg/xgin"
	"github.com/JrMarcco/hermet/internal/service"
	"github.com/gin-gonic/gin"
	"go.uber.org/zap"
)

var _ xgin.RouteRegistry = (*UserHandler)(nil)

type UserHandler struct {
	webjwt.Handler

	svc    service.UserService
	logger *zap.Logger
}

func (h *UserHandler) Register(engine *gin.Engine) {
	userV1 := engine.Group("api/v1/user")
	userV1.Handle(http.MethodPost, "/sign-in", xgin.B(h.SignIn))
	userV1.Handle(http.MethodPost, "/refresh-token", xgin.B(h.RefreshToken))
	userV1.Handle(http.MethodPost, "/sign-out", xgin.W(h.SignOut))
}

type signInRequest struct {
	Account     string `json:"account"`
	AccountType string `json:"accountType"`
	Credential  string `json:"credential"`
}

type tokenResponse struct {
	AccessToken  string `json:"accessToken"`
	RefreshToken string `json:"refreshToken"`
}

func (h *UserHandler) SignIn(ctx *gin.Context, req signInRequest) (xgin.R, error) {
	au, err := h.svc.SignIn(ctx, req.Account, req.AccountType, req.Credential)
	if err != nil {
		return xgin.R{}, err
	}

	// 创建 seesion。
	if err := h.CreateSession(ctx, au.SID, au.UID); err != nil {
		return xgin.R{}, err
	}

	at, st, err := h.svc.GenerateToken(ctx, au)
	if err != nil {
		return xgin.R{}, err
	}

	return xgin.R{
		Code: http.StatusOK,
		Data: tokenResponse{
			AccessToken:  at,
			RefreshToken: st,
		},
	}, nil
}

type refreshTokenRequest struct {
	RefreshToken string `json:"refreshToken"`
}

func (h *UserHandler) RefreshToken(ctx *gin.Context, req refreshTokenRequest) (xgin.R, error) {
	au, err := h.svc.VerifyRefreshToken(ctx, req.RefreshToken)
	if err != nil {
		return xgin.R{}, err
	}

	// 校验 session。
	if err := h.CheckSession(ctx, au.SID, au.UID); err != nil {
		return xgin.R{}, fmt.Errorf("%w: %w", errs.ErrUnauthorized, err)
	}

	// 刷新 session 过期时间。
	if err := h.RefreshSession(ctx, au.SID); err != nil {
		// 刷新失败不中断流程，记录日志即可。
		h.logger.Error("[hermet-user-handler] failed to refresh session", zap.Error(err))
	}

	// 重新生成 access token 和 refresh token。
	at, st, err := h.svc.GenerateToken(ctx, au)
	if err != nil {
		return xgin.R{}, err
	}

	return xgin.R{
		Code: http.StatusOK,
		Data: tokenResponse{
			AccessToken:  at,
			RefreshToken: st,
		},
	}, nil
}

func (h *UserHandler) SignOut(ctx *gin.Context) (xgin.R, error) {
	val, ok := ctx.Get(xgin.ContextKeyAuthUser)
	if !ok {
		return xgin.R{
			Code: http.StatusUnauthorized,
			Msg:  "user is not signed in",
		}, nil
	}

	au, ok := val.(xgin.AuthUser)
	if !ok {
		return xgin.R{
			Code: http.StatusUnauthorized,
			Msg:  "user is not signed in",
		}, nil
	}

	go func() {
		// 异步清理 session，避免阻塞主线程。
		// 这里必须使用 context.Background()，ctx 会在请求结束后取消。
		ctx, cancel := context.WithTimeout(context.Background(), time.Second)
		defer cancel()
		if err := h.ClearSession(ctx, au.SID); err != nil {
			h.logger.Error("[hermet-user-handler] failed to clear session", zap.Error(err))
		}
	}()
	return xgin.R{
		Code: http.StatusOK,
		Msg:  "signed out",
	}, nil
}

func NewUserHandler(handler webjwt.Handler, svc service.UserService, logger *zap.Logger) *UserHandler {
	return &UserHandler{
		Handler: handler,
		svc:     svc,
		logger:  logger,
	}
}
