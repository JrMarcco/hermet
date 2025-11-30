package domain

type BizUser struct {
	ID       uint64 `json:"id"`
	Email    string `json:"email"`
	Mobile   string `json:"mobile"`
	Avatar   string `json:"avatar"`
	Passwd   string `json:"passwd"`
	Nickname string `json:"nickname"`

	CreateAt int64 `json:"createAt"`
	UpdateAt int64 `json:"updateAt"`

	ReadRecords ChannelReadRecords `json:"readRecords"`
}

// ChannelReadRecords 是用户所有频道的消息阅读记录。
type ChannelReadRecords []ChannelReadRecord

func (crr ChannelReadRecords) GetLastMessageID(cid uint64) uint64 {
	for _, r := range crr {
		if r.CID == cid {
			return r.LastMessageID
		}
	}
	return 0
}

// ChannelReadRecord 是频道中消息阅读记录。
// 记录了当前频道阅读到的最后一条消息的 ID。
type ChannelReadRecord struct {
	CID           uint64 `json:"cid"`
	LastMessageID uint64 `json:"lastMessageId"`
}
