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
	ID     uint64      `json:"id"`
	Name   string      `json:"name"`
	Type   ChannelType `json:"type"`
	Avatar string      `json:"avatar"`

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
