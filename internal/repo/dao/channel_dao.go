package dao

import (
	"context"
	"database/sql"

	"gorm.io/gorm"
)

type Channel struct {
	ID uint64 `gorm:"column:id"`

	Avatar      sql.NullString `gorm:"column:avatar"`
	ChannelName sql.NullString `gorm:"column:channel_name"`

	ChannelType   string `gorm:"column:channel_type"`
	ChannelStatus string `gorm:"column:channel_status"`

	Creator uint64 `gorm:"column:creator"`

	CreateAt int64 `gorm:"column:create_at"`
	UpdateAt int64 `gorm:"column:update_at"`
}

type ChannelDao interface {
	Save(ctx context.Context, channel Channel) (Channel, error)
}

var _ ChannelDao = (*DefaultChannelDao)(nil)

type DefaultChannelDao struct {
	db *gorm.DB
}

func NewDefaultChannelDao(db *gorm.DB) *DefaultChannelDao {
	return &DefaultChannelDao{db: db}
}

func (d *DefaultChannelDao) Save(_ context.Context, _ Channel) (Channel, error) {
	// now := time.Now().UnixMilli()

	// channel.CreateAt = now
	// channel.UpdateAt = now

	// TODO: not implemented
	panic("not implemented")
}
