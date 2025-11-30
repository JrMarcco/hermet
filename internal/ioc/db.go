package ioc

import (
	"context"
	"fmt"
	"time"

	"github.com/JrMarcco/hermet/internal/pkg/xgorm"
	_ "github.com/lib/pq"
	"github.com/spf13/viper"
	"go.uber.org/fx"
	"go.uber.org/zap"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

var DBFxOpt = fx.Module("db", fx.Provide(initDB))

type DBFxParams struct {
	fx.In

	Logger    *zap.Logger
	Lifecycle fx.Lifecycle
}

func initDB(params DBFxParams) *gorm.DB {
	type config struct {
		DSN                       string        `mapstructure:"dsn"`
		LogLevel                  string        `mapstructure:"log_level"`
		SlowThreshold             time.Duration `mapstructure:"slow_threshold"`
		IgnoreRecordNotFoundError bool          `mapstructure:"ignore_record_not_found_error"`
	}

	cfg := config{}
	if err := viper.UnmarshalKey("db", &cfg); err != nil {
		panic(err)
	}

	var level logger.LogLevel
	switch cfg.LogLevel {
	case "silent":
		level = logger.Silent
	case "error":
		level = logger.Error
	case "warn":
		level = logger.Warn
	case "info":
		level = logger.Info
	default:
		panic("invalid log level")
	}

	logger := xgorm.NewZapLogger(
		params.Logger,
		xgorm.WithLogLevel(level),
		xgorm.WithSlowThreshold(cfg.SlowThreshold),
		xgorm.WithIgnoreRecordNotFoundError(cfg.IgnoreRecordNotFoundError),
	)

	db, err := gorm.Open(postgres.Open(cfg.DSN), &gorm.Config{
		Logger: logger,
	})
	if err != nil {
		panic(err)
	}

	sqlDB, err := db.DB()
	if err != nil {
		panic(err)
	}

	params.Lifecycle.Append(fx.Hook{
		OnStop: func(_ context.Context) error {
			if err := sqlDB.Close(); err != nil {
				params.Logger.Error("[hermet-ioc-db] failed to close db connection", zap.Error(err))
				return fmt.Errorf("failed to close db connection: %w", err)
			}
			params.Logger.Info("[hermet-ioc-db] db connection closed")
			return nil
		},
	})

	return db
}
