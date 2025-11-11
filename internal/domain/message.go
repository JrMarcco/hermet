package domain

type Message struct {
	Id  uint64 `json:"id"`
	Mid uint64 `json:"mid"` // 这里指的是 websocket 消息的唯一 id
	Sid uint64 `json:"sid"` // sender id
	Cid uint64 `json:"cid"` // channel id

	Content     []byte `json:"content"`
	ContentType int32  `json:"content_type"`

	SendAt int64 `json:"send_at"` // 消息发送时间 ( 统一使用服务器时间 )
}
