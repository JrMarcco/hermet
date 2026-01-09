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

	userV1.Handle(http.MethodPost, "/contact", xgin.BU(h.ContactApplicant))
	userV1.Handle(http.MethodGet, "/contact/applications", xgin.U(h.GetContactApplications))
}

type addContactReq struct {
	ContactID uint64 `json:"contactId"`
	Message   string `json:"message"`
	Source    string `json:"source"` // 添加来源 ( search=搜索添加 / qrcode=扫码添加 / group=群聊添加 )
}

// ContactApplicant 联系人申请。
// 注意：这里只提交联系人申请，不会立即添加联系人。
func (h *UserHandler) ContactApplicant(ctx *gin.Context, req addContactReq, au xgin.ContextUser) (xgin.R, error) {
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
	if err := h.svc.ContactApplicant(ctx, event); err != nil {
		return xgin.R{}, err
	}

	return xgin.R{
		Code: http.StatusOK,
	}, nil
}

type contactApplicationResp struct {
	ID                 uint64 `json:"id"`
	ApplicantID        uint64 `json:"applicantId"`
	ApplicantName      string `json:"applicantName"`
	ApplicantAvatar    string `json:"applicantAvatar"`
	ApplicationMessage string `json:"applicationMessage"`
	Source             string `json:"source"`
	CreatedAt          int64  `json:"createdAt"`
}

// GetContactApplications 获取联系人申请。
// 这里是获取向当前登录用户发送的联系人的人申请。
func (h *UserHandler) GetContactApplications(ctx *gin.Context, au xgin.ContextUser) (xgin.R, error) {
	applications, err := h.svc.ListContactApplications(ctx, au.UID)
	if err != nil {
		return xgin.R{}, err
	}

	// 转换为响应对象
	responses := make([]contactApplicationResp, 0, len(applications))
	for i := range applications {
		responses = append(responses, contactApplicationResp{
			ID:                 applications[i].ID,
			ApplicantID:        applications[i].ApplicantID,
			ApplicantName:      applications[i].ApplicantName,
			ApplicantAvatar:    applications[i].ApplicantAvatar,
			ApplicationMessage: applications[i].ApplicationMessage,
			Source:             string(applications[i].Source),
			CreatedAt:          applications[i].CreatedAt,
		})
	}

	return xgin.R{
		Code: http.StatusOK,
		Data: responses,
	}, nil
}
