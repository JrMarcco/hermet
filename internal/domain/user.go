package domain

// BizUser 是业务用户信息。
type BizUser struct {
	ID       uint64 `json:"id"`
	Email    string `json:"email"`
	Mobile   string `json:"mobile"`
	Avatar   string `json:"avatar"`
	Passwd   string `json:"passwd"`
	Nickname string `json:"nickname"`

	CreatedAt int64 `json:"createdAt"`
	UpdatedAt int64 `json:"updatedAt"`

	ReadRecords ChannelReadRecords `json:"readRecords"`
}
