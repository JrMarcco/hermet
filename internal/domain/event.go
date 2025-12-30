package domain

// EventType 事件类型。
type EventType string

const (
	// EventTypeChannelCreated 频道创建事件。
	EventTypeChannelCreated EventType = "channel.created"
	// EventTypeChannelMemberAdded 频道成员添加事件。
	EventTypeChannelMemberAdded EventType = "channel.member.added"
	// EventTypeChannelMemberRemoved 频道成员移除事件。
	EventTypeChannelMemberRemoved EventType = "channel.member.removed"
)

// ChannelCreatedEvent 频道创建事件。
type ChannelCreatedEvent struct {
	CID         uint64 `json:"cid"`
	ChannelType string `json:"channelType"`
	ChannelName string `json:"channelName"`

	Avatar    string   `json:"avatar"`
	Creator   uint64   `json:"creator"`
	MemberIDs []uint64 `json:"memberIds"` // 所有成员 ID 列表

	CreatedAt int64 `json:"createdAt"`
}

// ChannelMemberAddedEvent 频道成员添加事件。
type ChannelMemberAddedEvent struct {
	CID       uint64   `json:"cid"`
	MemberIDs []uint64 `json:"memberIds"` // 新增的成员 ID 列表
	Operator  uint64   `json:"operator"`  // 操作者
}

// ChannelMemberRemovedEvent 频道成员移除事件。
type ChannelMemberRemovedEvent struct {
	CID       uint64   `json:"cid"`
	MemberIDs []uint64 `json:"memberIds"` // 新增的成员 ID 列表
	Operator  uint64   `json:"operator"`  // 操作者
}
