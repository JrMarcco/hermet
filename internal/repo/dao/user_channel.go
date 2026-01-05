package dao

import "gorm.io/gorm"

type UserChannel struct{}

func (UserChannel) TableName() string {
	return "user_channel"
}

type UserChannelDao interface{}

var _ UserChannelDao = (*DefaultUserChannelDao)(nil)

type DefaultUserChannelDao struct {
	db *gorm.DB
}

func NewDefaultUserChannelDao(db *gorm.DB) *DefaultUserChannelDao {
	return &DefaultUserChannelDao{db: db}
}
