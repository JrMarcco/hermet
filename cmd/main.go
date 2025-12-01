package main

import (
	"github.com/JrMarcco/hermet/internal/api"
	"github.com/JrMarcco/hermet/internal/app"
	"github.com/JrMarcco/hermet/internal/pkg/providers"
	"github.com/JrMarcco/hermet/internal/repo"
	"github.com/JrMarcco/hermet/internal/repo/dao"
	"github.com/JrMarcco/hermet/internal/service"
	"github.com/spf13/pflag"
	"github.com/spf13/viper"
	"go.uber.org/fx"
	"go.uber.org/fx/fxevent"
	"go.uber.org/zap"
)

func main() {
	initViper()

	fx.New(
		fx.WithLogger(func(logger *zap.Logger) fxevent.Logger {
			return &fxevent.ZapLogger{Logger: logger}
		}),

		// 初始化 zap.logger。
		providers.ZapLoggerFxModule,

		// 初始化 redis client。
		providers.RedisFxModule,

		// 初始化 db。
		providers.DBFxModule,

		// 初始化 mongo db client。
		providers.MongoFxModule,

		// 初始化 kafka client。
		providers.KafkaFxModule,

		// 初始化 jwt manager。
		providers.JwtManagerFxModule,

		// 初始化 jwt handler。
		providers.JwtHandlerFxModule,

		// 初始化 middleware。
		providers.MiddlewareFxModule,

		// 初始化 dao。
		dao.DaoFxModule,

		// 初始化 repo。
		repo.RepoFxModule,

		// 初始化 service。
		service.ServiceFxModule,

		// 初始化 web。
		api.APIFxModule,

		// 初始化 app。
		app.AppFxModule,
	).Run()
}

func initViper() {
	configFile := pflag.String("config", "etc/config.yaml", "path to config file")
	pflag.Parse()

	viper.SetConfigFile(*configFile)
	viper.SetConfigType("yaml")
	if err := viper.ReadInConfig(); err != nil {
		panic(err)
	}
}
