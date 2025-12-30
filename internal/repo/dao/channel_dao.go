package dao

type Channel struct {
	ID          uint64 `gorm:"column:id"`
	Name        string `gorm:"column:name"`
	Avatar      string `gorm:"column:avatar"`
	ChannelType string `gorm:"column:channel_type"`

	Creator uint64 `gorm:"column:creator"`

	CreateAt int64 `gorm:"column:create_at"`
	UpdateAt int64 `gorm:"column:update_at"`
}

func (Channel) TableName() string {
	return "channel"
}
