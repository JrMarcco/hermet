package providers

import (
	"context"
	"time"

	"github.com/jrmarcco/hermet/internal/pkg/xmongo"
	"github.com/spf13/viper"
	"go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"
	"go.mongodb.org/mongo-driver/v2/mongo/readpref"
	"go.uber.org/fx"
	"go.uber.org/zap"
)

type mongoFxResult struct {
	fx.Out

	Client       *mongo.Client
	MongoManager *xmongo.MongoManager
}

func newMongoClient(zapLogger *zap.Logger, lifecycle fx.Lifecycle) (mongoFxResult, error) {
	cfg := mongoConfig{}
	if err := viper.UnmarshalKey("mongo", &cfg); err != nil {
		return mongoFxResult{}, err
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
		return mongoFxResult{}, err
	}

	mongoManger := xmongo.NewShardingManager(client, transMongoConfig(cfg))

	lifecycle.Append(fx.Hook{
		OnStart: func(ctx context.Context) error {
			startupCtx, cancel := context.WithTimeout(ctx, cfg.StartupTimeout)
			defer cancel()

			if err := client.Ping(startupCtx, readpref.Primary()); err != nil {
				return err
			}
			zapLogger.Info("[hermet-ioc] successfully connected to mongo", zap.String("uri", cfg.URI))

			if err := mongoManger.InitSharding(ctx); err != nil {
				return err
			}
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

	return mongoFxResult{
		Client:       client,
		MongoManager: mongoManger,
	}, nil
}

type mongoConfig struct {
	URI     string `mapstructure:"uri"`
	DBName  string `mapstructure:"db_name"`
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

	Sharding []mongoSharding `mapstructure:"sharding"`
}

type mongoSharding struct {
	CollectionName string `mapstructure:"collection_name"`
	Key            string `mapstructure:"key"`
	Type           string `mapstructure:"type"`
}

func transMongoConfig(cfg mongoConfig) xmongo.Config {
	collections := make([]xmongo.ShardingColl, 0, len(cfg.Sharding))
	for _, s := range cfg.Sharding {
		collections = append(collections, xmongo.ShardingColl{
			CollectionName: s.CollectionName,
			Key:            s.Key,
			Type:           s.Type,
		})
	}
	return xmongo.Config{
		DBName:        cfg.DBName,
		ShardingColls: collections,
	}
}
