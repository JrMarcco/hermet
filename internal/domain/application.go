package domain

type ApplicationStatus string

const (
	ApplicationStatusPending  ApplicationStatus = "pending"
	ApplicationStatusApproved ApplicationStatus = "approved"
	ApplicationStatusRejected ApplicationStatus = "rejected"
)

type ContactApplication struct {
	ID uint64 `json:"id"`

	ApplicantID uint64 `json:"applicantId"` // 申请人 ID

	TargetID     uint64 `json:"targetId"`     // 目标用户 ID
	TargetName   string `json:"targetName"`   // 目标用户昵称
	TargetAvatar string `json:"targetAvatar"` // 目标用户头像

	ApplicationStatus  ApplicationStatus `json:"applicationStatus"`
	ApplicationMessage string            `json:"applicationMessage"`

	ReviewedAt int64 `json:"reviewedAt"` // 审批时间戳 ( Unix 毫秒值 )

	CreatedAt int64 `json:"createdAt"` // 创建时间戳 ( Unix 毫秒值 )
	UpdatedAt int64 `json:"updatedAt"` // 更新时间戳 ( Unix 毫秒值 )
}

// ChannelApplication 频道申请 ( 入群申请 )。
type ChannelApplication struct {
	ID uint64 `json:"id"`

	ApplicantID uint64 `json:"applicantId"` // 申请人 ID

	ChannelID     uint64 `json:"chanelId"`      // 频道 ID
	ChannelName   string `json:"channelName"`   // 频道名称
	ChannelAvatar string `json:"channelAvatar"` // 频道头像

	ApplicationStatus  ApplicationStatus `json:"applicationStatus"`
	ApplicationMessage string            `json:"applicationMessage"`

	ReviewerID uint64 `json:"reviewerId"` // 审批人 ID
	ReviewedAt int64  `json:"reviewedAt"` // 审批时间戳 ( Unix 毫秒值 )

	CreatedAt int64 `json:"createdAt"` // 创建时间戳 ( Unix 毫秒值 )
	UpdatedAt int64 `json:"updatedAt"` // 更新时间戳 ( Unix 毫秒值 )
}
