package xmongo

import "go.mongodb.org/mongo-driver/v2/mongo"

type CollManager struct {
	client *mongo.Client
	dbName string
}

func (m *CollManager) Collection(name string) *mongo.Collection {
	return m.client.Database(m.dbName).Collection(name)
}

func NewCollManager(client *mongo.Client, dbName string) *CollManager {
	return &CollManager{
		client: client,
		dbName: dbName,
	}
}
