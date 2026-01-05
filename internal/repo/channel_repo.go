package repo

import (
	"context"

	"github.com/jrmarcco/hermet/internal/domain"
	"github.com/jrmarcco/hermet/internal/repo/dao"
	"gorm.io/gorm"
)

type ChannelRepo interface {
	CreateChannlSync(ctx context.Context) (domain.Channel, error)
}

var _ ChannelRepo = (*DefaultChannelRepo)(nil)

type DefaultChannelRepo struct {
	db *gorm.DB

	channelDao       dao.ChannelDao
	channelMemberDao dao.ChannelMemberDao
	userChannelDao   dao.UserChannelDao
}

func NewDefaultChannelRepo(
	db *gorm.DB,
	channelDao dao.ChannelDao,
	channelMemberDao dao.ChannelMemberDao,
	userChannelDao dao.UserChannelDao,
) *DefaultChannelRepo {
	return &DefaultChannelRepo{
		db:               db,
		channelDao:       channelDao,
		channelMemberDao: channelMemberDao,
		userChannelDao:   userChannelDao,
	}
}

func (r *DefaultChannelRepo) CreateChannlSync(_ context.Context) (domain.Channel, error) {
	// err := r.db.WithContext(ctx).Transaction(func(_ *gorm.DB) error {
	// 	// 1. 创建 channel。

	// 	// 2. 写入 channel_member。

	// 	// 3. 写入 user_channel。

	// 	return nil
	// })

	// if err != nil {
	// 	return domain.Channel{}, err
	// }

	// TODO: not implemented
	panic("not implemented")
}
