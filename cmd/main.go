package main

import (
	"github.com/JrMarcco/hermet/internal/ioc"
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
		ioc.LoggerFxOpt,

		// 初始化 mongo db client。
		ioc.MongoFxOpt,

		// 初始化 redis client。
		ioc.RedisFxOpt,

		// 初始化 kafka client。
		ioc.KafkaFxOpt,

		// 初始化 jwt manager。
		ioc.JwtManagerOpt,

		// 初始化 middleware。
		ioc.MiddlewareBuilderOpt,

		// 初始化 app。
		ioc.AppFxOpt,
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
