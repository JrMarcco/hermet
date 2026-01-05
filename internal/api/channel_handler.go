package api

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/jrmarcco/hermet/internal/pkg/xgin"
	"github.com/jrmarcco/hermet/internal/service"
	"go.uber.org/zap"
)

var _ xgin.RouteRegistry = (*ChannelHandler)(nil)

type ChannelHandler struct {
	svc    service.ChannelService
	logger *zap.Logger
}

func NewChannelHandler(svc service.ChannelService, logger *zap.Logger) *ChannelHandler {
	return &ChannelHandler{
		svc:    svc,
		logger: logger,
	}
}

func (h *ChannelHandler) Register(engine *gin.Engine) {
	channelv1 := engine.Group("api/v1/channel")

	channelv1.Handle(http.MethodPost, "/create-group", xgin.BU(h.CreateGroup))
}

type createGroupRequest struct {
	Name      string   `json:"name"`
	Avatar    string   `json:"avatar"`
	MemberIDs []uint64 `json:"memberIds"`
}

// CreateGroup 创建群组。
func (h *ChannelHandler) CreateGroup(_ *gin.Context, _ createGroupRequest, _ xgin.ContextUser) (xgin.R, error) {
	// TODO: not implemented
	panic("not implemented")
}
