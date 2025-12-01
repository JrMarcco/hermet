package providers

import (
	"context"
	"fmt"
	"time"

	"github.com/JrMarcco/hermet/internal/pkg/xgorm"
	"github.com/spf13/viper"
	"go.uber.org/fx"
	"go.uber.org/zap"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

func newDBClient(zapLogger *zap.Logger, lifecycle fx.Lifecycle) (*gorm.DB, error) {
	type config struct {
		DSN                       string        `mapstructure:"dsn"`
		LogLevel                  string        `mapstructure:"log_level"`
		SlowThreshold             time.Duration `mapstructure:"slow_threshold"`
		IgnoreRecordNotFoundError bool          `mapstructure:"ignore_record_not_found_error"`
	}

	cfg := config{}
	if err := viper.UnmarshalKey("db", &cfg); err != nil {
		return nil, err
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
		zapLogger,
		xgorm.WithLogLevel(level),
		xgorm.WithSlowThreshold(cfg.SlowThreshold),
		xgorm.WithIgnoreRecordNotFoundError(cfg.IgnoreRecordNotFoundError),
	)

	db, err := gorm.Open(postgres.Open(cfg.DSN), &gorm.Config{
		Logger: logger,
	})
	if err != nil {
		return nil, err
	}

	sqlDB, err := db.DB()
	if err != nil {
		return nil, err
	}

	lifecycle.Append(fx.Hook{
		OnStop: func(_ context.Context) error {
			if err := sqlDB.Close(); err != nil {
				zapLogger.Error("[hermet-ioc-db] failed to close db connection", zap.Error(err))
				return fmt.Errorf("failed to close db connection: %w", err)
			}
			zapLogger.Info("[hermet-ioc-db] db connection closed")
			return nil
		},
	})

	return db, nil
}
