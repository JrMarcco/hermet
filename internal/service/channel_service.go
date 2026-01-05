package service

import (
	"context"
	"fmt"

	"github.com/jrmarcco/hermet/internal/domain"
	"github.com/jrmarcco/hermet/internal/errs"
	"github.com/jrmarcco/hermet/internal/repo"
	"go.uber.org/zap"
)

type ChannelService interface {
	CreateGroup(ctx context.Context, event domain.ChannelCreatedEvent) (domain.Channel, error)
}

var _ ChannelService = (*DefaultChannelService)(nil)

type DefaultChannelService struct {
	asyncThreshold int // 同步成员写入的阈值

	channelRepo repo.ChannelRepo
	logger      *zap.Logger
}

func NewDefaultChannelService(channelRepo repo.ChannelRepo, logger *zap.Logger) *DefaultChannelService {
	return &DefaultChannelService{
		channelRepo: channelRepo,
		logger:      logger,
	}
}

func (s *DefaultChannelService) CreateGroup(ctx context.Context, event domain.ChannelCreatedEvent) (domain.Channel, error) {
	memberCnt := len(event.MemberIDs)
	if memberCnt == 0 {
		return domain.Channel{}, fmt.Errorf("%w: member is empty", errs.ErrInvalidParam)
	}

	// 根据成员数量选择创建策略。
	if memberCnt <= s.asyncThreshold {
		return s.createGroupSync(ctx, event)
	}
	return s.createGroupAsync(ctx, event)
}

// createGroupSync 同步创建群组 ( 适用于小群组 )。
func (s *DefaultChannelService) createGroupSync(_ context.Context, _ domain.ChannelCreatedEvent) (domain.Channel, error) {
	// TODO: not implemented
	panic("not implemented")
}

// createGroupAsync 异步创建群组 ( 适用于大群组 )。
func (s *DefaultChannelService) createGroupAsync(_ context.Context, _ domain.ChannelCreatedEvent) (domain.Channel, error) {
	// TODO: not implemented
	panic("not implemented")
}
