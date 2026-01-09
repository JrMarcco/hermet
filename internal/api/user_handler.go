package api

import (
	"fmt"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/jrmarcco/hermet/internal/domain"
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
	userV1.Handle(http.MethodGet, "/contact/applications", xgin.U(h.GetContactApplications))
}

type addContactRequest struct {
	ContactID uint64 `json:"contactId"`
	Message   string `json:"message"`
	Source    string `json:"source"` // 添加来源 ( search=搜索添加 / qrcode=扫码添加 / group=群聊添加 )
}

// AddContact 添加联系人。
// 注意：这里只提交联系人申请，不会立即添加联系人。
func (h *UserHandler) AddContact(ctx *gin.Context, req addContactRequest, au xgin.ContextUser) (xgin.R, error) {
	if req.ContactID == au.UID {
		return xgin.R{}, fmt.Errorf("%w: can not add self as contact", errs.ErrInvalidParam)
	}

	source := domain.UserContactSource(req.Source)
	if !source.IsValid() {
		return xgin.R{}, fmt.Errorf("%w: invalid source", errs.ErrInvalidParam)
	}

	event := domain.ContactApplicantEvent{
		ApplicantID: au.UID,
		TargetID:    req.ContactID,
		Message:     req.Message,
		Source:      source,
	}
	if err := h.svc.AddContact(ctx, event); err != nil {
		return xgin.R{}, err
	}

	return xgin.R{
		Code: http.StatusOK,
	}, nil
}

// GetContactApplications 获取联系人申请。
// 这里是获取向当前登录用户发送的联系人的人申请。
func (h *UserHandler) GetContactApplications(ctx *gin.Context, au xgin.ContextUser) (xgin.R, error) {
	applications, err := h.svc.ListContactApplications(ctx, au.UID)
	if err != nil {
		return xgin.R{}, err
	}

	return xgin.R{
		Code: http.StatusOK,
		Data: applications,
	}, nil
}
