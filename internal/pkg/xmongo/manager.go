package xmongo

import (
	"context"
	"errors"
	"fmt"
	"log/slog"

	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
)

type Config struct {
	DBName        string
	ShardingColls []ShardingColl
}

type ShardingColl struct {
	CollectionName string
	Key            string
	Type           string // "hashed" or 1 ( range ascending )
}

type MongoManager struct {
	client *mongo.Client
	config Config
}

// InitSharding 初始化或验证分片。
func (m *MongoManager) InitSharding(ctx context.Context) error {
	adminDB := m.client.Database("admin")

	// 启用数据分片。
	res := adminDB.RunCommand(ctx, bson.D{{Key: "enableSharding", Value: m.config.DBName}})
	if err := res.Err(); err != nil {
		if !m.isIgnorableError(err) {
			return err
		}
		slog.Info("enable mongo sharding failed, may be already enabled", "error", err)
	}

	targetDB := m.client.Database(m.config.DBName)
	for _, sc := range m.config.ShardingColls {
		// 创建集合索引。
		coll := targetDB.Collection(sc.CollectionName)
		_, err := coll.Indexes().CreateOne(ctx, mongo.IndexModel{
			Keys: bson.D{{Key: sc.Key, Value: sc.Type}},
		})
		if err != nil {
			if !m.isIgnorableError(err) {
				return err
			}
			slog.Info(
				"create collection index failed, may be index already exists",
				"database", m.config.DBName,
				"collection", sc.CollectionName,
				"key", sc.Key,
				"type", sc.Type,
				"error", err,
			)
		}

		// 设置集合分片。
		res = adminDB.RunCommand(ctx, bson.D{
			{Key: "shardCollection", Value: fmt.Sprintf("%s.%s", m.config.DBName, sc.CollectionName)},
			{Key: "key", Value: bson.D{{Key: sc.Key, Value: sc.Type}}},
		})
		if err := res.Err(); err != nil {
			if !m.isIgnorableError(err) {
				return err
			}
			slog.Info(
				"shard collection failed, may be already sharded",
				"database", m.config.DBName,
				"collection", sc.CollectionName,
				"key", sc.Key,
				"type", sc.Type,
				"error", err,
			)
		}
	}

	slog.Info("sharding rules initialized/verified")
	return nil
}

// isIgnorableError 判断是否是可忽略的错误。
func (m *MongoManager) isIgnorableError(err error) bool {
	var cmdErr mongo.CommandError
	if errors.As(err, &cmdErr) {
		// code 23: AlreadyInitialized ( 常见于 enableSharding, shardCollection )。
		// code 48: NamespaceExists ( 常见于资源创建时 )。
		if cmdErr.Code == 23 || cmdErr.Code == 48 {
			return true
		}
		// 某些旧版本或特定命令可能返回 "already sharded" 但 code != 23，
		// 如果要更精确的判断这么可以增肌字符串判断作为兜底。
		// 通常使用 code 判断就足够了。
	}
	return false
}

func (m *MongoManager) Collection(name string) *mongo.Collection {
	return m.client.Database(m.config.DBName).Collection(name)
}

func NewShardingManager(client *mongo.Client, config Config) *MongoManager {
	return &MongoManager{
		client: client,
		config: config,
	}
}
