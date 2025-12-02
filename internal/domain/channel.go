package domain

type ChannelType string

const (
	ChannelTypeSingle = ChannelType("single")
	ChannelTypeGroup  = ChannelType("group")
)

// Channel 是整个 im 的核心抽象，表示一个聊天频道。
// 频道可以是单聊/群聊。
// 所有的通信都可以看作是发送到特定的频道，频道中的所有人都会收到消息。
type Channel struct {
	ID          uint64      `json:"id"`
	Name        string      `json:"name"`
	Avatar      string      `json:"avatar"`
	ChannelType ChannelType `json:"channelType"`

	Self ChannelMember `json:"self"` // 当前用户在频道中的成员信息
}

// ChannelMember 是频道中的成员。
type ChannelMember struct {
	ID       uint64 `json:"id"`
	Nickname string `json:"nickname"`
	Note     string `json:"note"`
	Avatar   string `json:"avatar"`
	Priority int    `json:"priority"`
	Mute     bool   `json:"mute"`
	JoinAt   int64  `json:"joinAt"`
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
