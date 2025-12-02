package dao

type ChannelReadRecord struct{}

func (ChannelReadRecord) TableName() string {
	return "channel_read_record"
}
