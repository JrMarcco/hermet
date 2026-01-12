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

var _ xgin.RouteRegistry = (*ContactHandler)(nil)

// ContactHandler 联系人 HTTP Handler。
type ContactHandler struct {
	userSvc        service.UserService
	applicationSvc service.ApplicationService
	logger         *zap.Logger
}

func NewContactHandler(userSvc service.UserService, applicationSvc service.ApplicationService, logger *zap.Logger) *ContactHandler {
	return &ContactHandler{
		userSvc:        userSvc,
		applicationSvc: applicationSvc,
		logger:         logger,
	}
}

func (h *ContactHandler) Register(engine *gin.Engine) {
	contactV1 := engine.Group("api/v1/contact")

	contactV1.Handle(http.MethodPost, "/apply", xgin.BU(h.ApplyContact))
	contactV1.Handle(http.MethodPost, "/review", xgin.BU(h.ReviewApplication))

	contactV1.Handle(http.MethodGet, "/applications", xgin.U(h.GetApplications))
}

type applyContactReq struct {
	ContactID uint64 `json:"contactId"`
	Message   string `json:"message"`
	Source    string `json:"source"` // 添加来源 ( search=搜索添加 / qrcode=扫码添加 / group=群聊添加 )
}

// ApplyContact 联系人申请。
// 注意：这里只提交联系人申请，不会立即添加联系人。
func (h *ContactHandler) ApplyContact(ctx *gin.Context, req applyContactReq, au xgin.ContextUser) (xgin.R, error) {
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
	if err := h.applicationSvc.ApplyContact(ctx, event); err != nil {
		return xgin.R{}, err
	}

	return xgin.R{
		Code: http.StatusOK,
	}, nil
}

type reviewApplicationReq struct {
	ApplicationID uint64 `json:"applicationId"`
	Status        string `json:"status"`
}

// ReviewApplication 审批联系人申请。
// 审批通过会建立联系人关系 ( 双向映射 )，并发送通知。
func (h *ContactHandler) ReviewApplication(_ *gin.Context, _ reviewApplicationReq, _ xgin.ContextUser) (xgin.R, error) {
	// TODO: not implemented
	panic("not implemented")
}

type getApplicationsResp struct {
	ID                 uint64 `json:"id"`
	ApplicantID        uint64 `json:"applicantId"`
	ApplicantName      string `json:"applicantName"`
	ApplicantAvatar    string `json:"applicantAvatar"`
	ApplicationMessage string `json:"applicationMessage"`
	Source             string `json:"source"`
	CreatedAt          int64  `json:"createdAt"`
}

// GetApplications 获取联系人申请。
// 这里是获取向当前登录用户发送的联系人的人申请。
func (h *ContactHandler) GetApplications(ctx *gin.Context, au xgin.ContextUser) (xgin.R, error) {
	applications, err := h.applicationSvc.GetContactApplications(ctx, au.UID)
	if err != nil {
		return xgin.R{}, err
	}

	// 转换为响应对象
	responses := make([]getApplicationsResp, 0, len(applications))
	for i := range applications {
		responses = append(responses, getApplicationsResp{
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
