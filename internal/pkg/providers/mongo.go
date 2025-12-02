package providers

import (
	"context"
	"fmt"
	"time"

	"github.com/spf13/viper"
	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"
	"go.mongodb.org/mongo-driver/v2/mongo/readpref"
	"go.uber.org/fx"
	"go.uber.org/zap"
)

type shardingManager struct {
	client *mongo.Client
	logger *zap.Logger
}

func (sm *shardingManager) initSharding(ctx context.Context) {
	adminDB := sm.client.Database("admin")
	targetDB := sm.client.Database("hermet")

	// 启用数据库分片。
	res := adminDB.RunCommand(ctx, bson.D{{Key: "enableSharding", Value: targetDB.Name()}})
	if err := res.Err(); err != nil {
		// 这里通常是因为生产环境已经启用分片，所以打印日志即可。
		sm.logger.Info("[hermet-ioc] enable sharding result: %v", zap.Error(err))
	}

	// 设置集合分片。
	coll := targetDB.Collection("message")
	_, err := coll.Indexes().CreateOne(ctx, mongo.IndexModel{
		Keys: bson.D{{Key: "cid", Value: "hashed"}},
	})
	if err != nil {
		sm.logger.Info("[hermet-ioc] create collection index result: %v", zap.String("collection", coll.Name()), zap.Error(err))
	}

	// 执行分片命令。
	res = adminDB.RunCommand(ctx, bson.D{
		{Key: "shardingCollection", Value: fmt.Sprintf("%s.%s", targetDB.Name(), coll.Name())},
		{Key: "key", Value: bson.D{{Key: "cid", Value: "hashed"}}},
	})
	if err := res.Err(); err != nil {
		sm.logger.Info("[hermet-ioc] sharding collection result: %v", zap.String("collection", coll.Name()), zap.Error(err))
	}

	sm.logger.Info("[hermet-ioc] sharding rule initialized")
}

func newShardingManager(client *mongo.Client, logger *zap.Logger) *shardingManager {
	return &shardingManager{
		client: client,
		logger: logger,
	}
}

func newMongoClient(zapLogger *zap.Logger, lifecycle fx.Lifecycle) (*mongo.Client, error) {
	type config struct {
		URI     string `mapstructure:"uri"`
		AppName string `mapstructure:"app_name"`

		AuthSource string `mapstructure:"auth_source"`
		Username   string `mapstructure:"username"`
		Password   string `mapstructure:"password"`

		MaxPoolSize            uint64        `mapstructure:"max_pool_size"`
		MaxConnIdleTime        time.Duration `mapstructure:"max_conn_idle_time"`
		ConnectTimeout         time.Duration `mapstructure:"connect_timeout"`
		ServerSelectionTimeout time.Duration `mapstructure:"server_selection_timeout"`

		StartupTimeout  time.Duration `mapstructure:"startup_timeout"`
		ShutdownTimeout time.Duration `mapstructure:"shutdown_timeout"`
	}

	cfg := config{}
	if err := viper.UnmarshalKey("mongo", &cfg); err != nil {
		return nil, err
	}

	opts := options.Client().
		ApplyURI(cfg.URI).
		SetAppName(cfg.AppName).
		SetMaxPoolSize(cfg.MaxPoolSize).
		SetMaxConnIdleTime(cfg.MaxConnIdleTime).
		SetConnectTimeout(cfg.ConnectTimeout).
		SetServerSelectionTimeout(cfg.ServerSelectionTimeout)

	if cfg.Username != "" {
		cred := options.Credential{Username: cfg.Username, Password: cfg.Password}
		if cfg.AuthSource != "" {
			cred.AuthSource = cfg.AuthSource
		}
		opts.SetAuth(cred)
	}

	client, err := mongo.Connect(opts)
	if err != nil {
		return nil, err
	}

	lifecycle.Append(fx.Hook{
		OnStart: func(ctx context.Context) error {
			startupCtx, cancel := context.WithTimeout(ctx, cfg.StartupTimeout)
			defer cancel()

			if err := client.Ping(startupCtx, readpref.Primary()); err != nil {
				return err
			}

			zapLogger.Info("[hermet-ioc] successfully connected to mongo", zap.String("uri", cfg.URI))

			shardingManager := newShardingManager(client, zapLogger)
			shardingManager.initSharding(ctx)

			return nil
		},
		OnStop: func(ctx context.Context) error {
			stopCtx, cancel := context.WithTimeout(ctx, cfg.ShutdownTimeout)
			defer cancel()

			if err := client.Disconnect(stopCtx); err != nil {
				zapLogger.Error("[hermet-ioc] failed to disconnect from mongo", zap.Error(err))
				return err
			}

			zapLogger.Info("[hermet-ioc] successfully disconnected from mongo")
			return nil
		},
	})

	return client, nil
}
