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
	Avatar      string      `json:"avatar"`
	ChannelName string      `json:"channelName"`
	ChannelType ChannelType `json:"channelType"`

	Self ChannelMember `json:"self"` // 当前用户在频道中的成员信息
}

// ChannelMember 是频道中的成员。
type ChannelMember struct {
	CID uint64 `json:"cid"`
	UID uint64 `json:"uid"`

	UserRole       string `json:"userRole"`
	UserProfileVer int    `json:"userProfileVer"`

	Avatar        string `json:"avatar"`
	Alias         string `json:"alias"`
	Nickname      string `json:"nickname"`
	PriorityOrder int    `json:"priorityOrder"`

	Mute   bool  `json:"mute"`
	JoinAt int64 `json:"joinAt"`
}

// ChannelReadRecord 是频道中消息阅读记录。
// 记录了当前频道阅读到的最后一条消息的 ID。
type ChannelReadRecord struct {
	CID           uint64 `json:"cid"`
	LastMessageID uint64 `json:"lastMessageId"`
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
