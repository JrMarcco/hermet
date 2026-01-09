package api

import (
	"fmt"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/jrmarcco/hermet/internal/errs"
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

	userV1.Handle(http.MethodPost, "/contact", xgin.BU(h.AddContact))
}

type addContactRequest struct {
	ContactID uint64 `json:"contactId"`
	Message   string `json:"message"`
}

// AddContact 添加联系人。
// 注意：这里只提交联系人申请，不会立即添加联系人。
func (h *UserHandler) AddContact(ctx *gin.Context, req addContactRequest, au xgin.ContextUser) (xgin.R, error) {
	if req.ContactID == au.UID {
		return xgin.R{}, fmt.Errorf("%w: can not add self as contact", errs.ErrInvalidParam)
	}

	if err := h.svc.AddContact(ctx, au.UID, req.ContactID, req.Message); err != nil {
		return xgin.R{}, err
	}

	return xgin.R{
		Code: http.StatusOK,
	}, nil
}
