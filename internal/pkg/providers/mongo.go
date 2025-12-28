package providers

import (
	"context"
	"crypto/tls"
	"crypto/x509"
	"fmt"
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

	Client      *mongo.Client
	CollManager *xmongo.CollManager
}

func newMongoClient(zapLogger *zap.Logger, lifecycle fx.Lifecycle) (mongoFxResult, error) {
	cfg := mongoConfig{}
	if err := viper.UnmarshalKey("mongodb", &cfg); err != nil {
		return mongoFxResult{}, err
	}

	certPool := x509.NewCertPool()
	if ok := certPool.AppendCertsFromPEM([]byte(cfg.TLS.CA)); !ok {
		return mongoFxResult{}, fmt.Errorf("failed to append ca cert to pool")
	}
	clientCert, err := tls.X509KeyPair([]byte(cfg.TLS.CertPem), []byte(cfg.TLS.CertKey))
	if err != nil {
		return mongoFxResult{}, fmt.Errorf("failed to load client cert: %w", err)
	}
	tlsConfig := &tls.Config{
		MinVersion:         tls.VersionTLS13,
		InsecureSkipVerify: false,
		RootCAs:            certPool,
		Certificates:       []tls.Certificate{clientCert},
	}

	opts := options.Client().
		ApplyURI(cfg.URI).
		SetAppName(cfg.AppName).
		SetTLSConfig(tlsConfig).
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

	collManager := xmongo.NewCollManager(client, cfg.DBName)

	lifecycle.Append(fx.Hook{
		OnStart: func(ctx context.Context) error {
			startupCtx, cancel := context.WithTimeout(ctx, cfg.StartupTimeout)
			defer cancel()

			if err := client.Ping(startupCtx, readpref.Primary()); err != nil {
				return err
			}

			zapLogger.Info("[hermet-ioc] successfully connected to mongodb", zap.String("uri", cfg.URI))
			return nil
		},
		OnStop: func(ctx context.Context) error {
			stopCtx, cancel := context.WithTimeout(ctx, cfg.ShutdownTimeout)
			defer cancel()

			if err := client.Disconnect(stopCtx); err != nil {
				zapLogger.Error("[hermet-ioc] failed to disconnect from mongodb", zap.Error(err))
				return err
			}

			zapLogger.Info("[hermet-ioc] successfully disconnected from mongodb")
			return nil
		},
	})

	return mongoFxResult{
		Client:      client,
		CollManager: collManager,
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

	TLS mongoTLSConfig `mapstructure:"tls"`
}

type mongoTLSConfig struct {
	CA      string `mapstructure:"ca"`
	CertKey string `mapstructure:"cert_key"`
	CertPem string `mapstructure:"cert_pem"`
}
