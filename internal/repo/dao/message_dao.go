package dao

import (
	"context"

	"go.mongodb.org/mongo-driver/v2/mongo"
)

type Message struct {
	ID uint64 `bson:"id"`

	CID uint64 `bson:"cid"`
	SID uint64 `bson:"sid"`

	MID string `bson:"mid"`

	Content     []byte `bson:"content"`
	ContentType int32  `bson:"contentType"`

	SendAt int64 `bson:"sendAt"`
}

type MessageDao interface {
	Save(ctx context.Context, message *Message) error
}

var _ MessageDao = (*DefaultMessageDao)(nil)

type DefaultMessageDao struct {
	coll *mongo.Collection
}

// Save 保存消息。
// 注意：message 必须是指针类型，因为 MongoDB 的插入操作会修改 message 的值 ( 如 ID 回传) 。
// 同时 Content 字段为 []byte，使用指针类型可以有效避免内存拷贝。
func (d *DefaultMessageDao) Save(ctx context.Context, message *Message) error {
	_, err := d.coll.InsertOne(ctx, message)
	return err
}
