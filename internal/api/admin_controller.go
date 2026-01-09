package api

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/jrmarcco/hermet/internal/domain"
	"github.com/jrmarcco/hermet/internal/pkg/xgin"
	"github.com/jrmarcco/hermet/internal/service"
	"go.uber.org/zap"
)

var _ xgin.RouteRegistry = (*AdminHandler)(nil)

type AdminHandler struct {
	userService service.UserService
	logger      *zap.Logger
}

func NewAdminHandler(userService service.UserService, logger *zap.Logger) *AdminHandler {
	return &AdminHandler{
		userService: userService,
		logger:      logger,
	}
}

func (h *AdminHandler) Register(engine *gin.Engine) {
	adminV1 := engine.Group("api/v1/admin")

	adminV1.Handle(http.MethodPost, "/user", xgin.B(h.AddUser))
}

type addUserRequest struct {
	Email  string `json:"email"`
	Mobile string `json:"mobile"`

	Nickname string `json:"nickname"`
	Avatar   string `json:"avatar"`
	Gender   string `json:"gender"`
	Region   string `json:"region"`
	Birthday int64  `json:"birthday"`
	Tagline  string `json:"tagline"`
}

func (h *AdminHandler) AddUser(ctx *gin.Context, req addUserRequest) (xgin.R, error) {
	if err := h.userService.AddUser(ctx, domain.BizUser{
		Email:    req.Email,
		Mobile:   req.Mobile,
		Nickname: req.Nickname,
		Avatar:   req.Avatar,
		Gender:   domain.UserGender(req.Gender),
		Region:   req.Region,
		Birthday: req.Birthday,
		Tagline:  req.Tagline,
	}); err != nil {
		return xgin.R{}, err
	}

	return xgin.R{
		Code: http.StatusOK,
	}, nil
}
