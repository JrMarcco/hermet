package providers

import (
	"fmt"

	"github.com/jrmarcco/hermet/internal/pkg/sharding"
	"github.com/jrmarcco/hermet/internal/pkg/sharding/idgen"
	"github.com/jrmarcco/hermet/internal/pkg/sharding/idgen/snowflake"
	"github.com/spf13/viper"
	"go.uber.org/fx"
)

type idGenFxResult struct {
	fx.Out

	Gen       idgen.Generator
	Extractor sharding.ShardValExtractor
}

func newIDGen() (idGenFxResult, error) {
	gen := snowflake.NewGenerator()
	extractor := snowflake.NewExtractor()
	return idGenFxResult{
		Gen:       gen,
		Extractor: extractor,
	}, nil
}

func newBizUserShardHelper(gen idgen.Generator, extractor sharding.ShardValExtractor) (*sharding.ShardHelper, error) {
	type config struct {
		DBPrefix     string `mapstructure:"db_prefix"`
		TBPrefix     string `mapstructure:"tb_prefix"`
		DBShardCount uint64 `mapstructure:"db_shard_count"`
		TBShardCount uint64 `mapstructure:"tb_shard_count"`
	}

	cfg := config{}
	if err := viper.UnmarshalKey("sharding.biz_user", &cfg); err != nil {
		return nil, err
	}

	baseStrategy, err := sharding.NewModuloSharding(extractor, cfg.DBPrefix, cfg.TBPrefix, cfg.DBShardCount, cfg.TBShardCount)
	if err != nil {
		return nil, fmt.Errorf("failed to create modulo sharding: %w", err)
	}

	strategy, err := sharding.NewBalancedSharding(baseStrategy, sharding.BroadcastModeRoundRobin)
	if err != nil {
		return nil, fmt.Errorf("failed to create balanced sharding: %w", err)
	}

	helper, err := sharding.NewShardHelper(gen, strategy)
	if err != nil {
		return nil, fmt.Errorf("failed to create shard helper: %w", err)
	}

	return helper, nil
}
