package domain

type ContentType int32

// Message 对应网关消息中的 body 的具体格式。
type Message struct {
	ID uint64 `json:"id"`

	CID uint64 `json:"cid"` // channel id
	SID uint64 `json:"sid"` // sender id

	MID uint64 `json:"mid"` // 这里指的是网关消息的唯一 id

	Content     []byte      `json:"content"`
	ContentType ContentType `json:"contentType"`

	SendAt int64 `json:"sendAt"` // 消息发送时间 ( 统一使用服务器时间 )
}
