package api

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/jrmarcco/hermet/internal/pkg/xgin"
	"github.com/jrmarcco/hermet/internal/service"
	"go.uber.org/zap"
)

var _ xgin.RouteRegistry = (*UserHandler)(nil)

type UserHandler struct {
	svc    service.UserService
	logger *zap.Logger
}

func NewUserHandler(svc service.UserService, logger *zap.Logger) *UserHandler {
	return &UserHandler{
		svc:    svc,
		logger: logger,
	}
}

func (h *UserHandler) Register(engine *gin.Engine) {
	userV1 := engine.Group("api/v1/user")

	userV1.Handle(http.MethodPost, "/add-contact", xgin.BU(h.AddContact))
}

type addContactRequest struct {
	ContactID uint64 `json:"contactId"`
}

func (h *UserHandler) AddContact(_ *gin.Context, _ addContactRequest, _ xgin.ContextUser) (xgin.R, error) {
	// TODO: not implemented
	panic("not implemented")
}
