package dao

type ChannelMember struct{}

func (ChannelMember) TableName() string {
	return "channel_member"
}
