package domain

type UserStatus string

const (
	UserStatusActive   UserStatus = "active"
	UserStatusDisabled UserStatus = "disabled"
	UserStatusDeleted  UserStatus = "deleted"
)

type UserGender string

const (
	UserGenderUnknown UserGender = "unknown"
	UserGenderMale    UserGender = "male"
	UserGenderFemale  UserGender = "female"
)

func (ug UserGender) IsValid() bool {
	switch ug {
	case UserGenderUnknown, UserGenderMale, UserGenderFemale:
		return true
	default:
		return false
	}
}

// BizUser 是业务用户信息。
type BizUser struct {
	ID uint64 `json:"id"`

	// 账号信息。
	Email  string `json:"email"`
	Mobile string `json:"mobile"`
	Passwd string `json:"passwd"`

	// 个人信息。
	Avatar   string     `json:"avatar"`
	Nickname string     `json:"nickname"`
	Gender   UserGender `json:"gender"`
	Region   string     `json:"region"`
	Birthday int64      `json:"birthday"`
	Tagline  string     `json:"tagline"`

	// 版本控制。
	InfoVer int `json:"infoVer"`

	// 状态管理。
	UserStatus UserStatus `json:"userStatus"`
	DeletedAt  int64      `json:"deletedAt"`

	// 时间戳。
	CreatedAt int64 `json:"createdAt"`
	UpdatedAt int64 `json:"updatedAt"`
}
