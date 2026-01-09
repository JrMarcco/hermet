package dao

import "gorm.io/gorm"

type ChannelMember struct{}

type ChannelMemberDao interface{}

var _ ChannelMemberDao = (*DefaultChannelMemberDao)(nil)

type DefaultChannelMemberDao struct {
	db *gorm.DB
}

func NewDefaultChannelMemberDao(db *gorm.DB) *DefaultChannelMemberDao {
	return &DefaultChannelMemberDao{db: db}
}
