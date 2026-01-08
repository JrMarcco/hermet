package sharding

import (
	"errors"

	"github.com/jrmarcco/hermet/internal/pkg/sharding/idgen"
)

// ShardHelper 分片辅助工具，整合 Strategy & ID 生成器 & Sharder。
// 提供了一站式的分片和 ID 生成服务，简化业务代码。
//
// 使用示例：
//
//	gen := snowflake.NewGenerator()
//	extractor := snowflake.NewExtractor()
//	strategy, _ := sharding.NewModuloSharding(extractor, "db", "table", 8, 4)
//	helper, _ := NewShardHelper(gen, strategy)
//
//	// 同时生成 ID 和获取分片信息
//	sharder := NewSingleIdSharder(userId)
//	id, dst := helper.NextIdAndShard(sharder)
//
//	// 根据已有 ID 获取分片信息
//	dst = helper.DstFromId(id)
//
//	注意：
//	idgen.Generator 和 ShardValExtractor 必须配套使用，否则会导致分片信息不一致。
type ShardHelper struct {
	gen      idgen.Generator // ID 生成器
	strategy Strategy        // 分片策略
}

// NewShardHelper 创建分片辅助工具。
// 参数不能为 nil。
//
// 注意：
//
//	使用此方法时，需要确保 Generator 和 Strategy 中的 Extractor 是配套的。
func NewShardHelper(gen idgen.Generator, strategy Strategy) (*ShardHelper, error) {
	if gen == nil {
		return nil, errors.New("generator cannot be nil")
	}
	if strategy == nil {
		return nil, errors.New("strategy cannot be nil")
	}

	return &ShardHelper{
		gen:      gen,
		strategy: strategy,
	}, nil
}

// NextIDAndShard 同时生成 ID 和计算分片目标。
// 这是最常用的方法，一次调用完成 ID 生成和分片计算，性能最优。
// 返回值：
// - uint64: 生成的 ID ( 包含分片信息 )
// - Dst: 分片目标信息
func (s *ShardHelper) NextIDAndShard(sharder Sharder) (uint64, Dst, error) {
	shardVal, err := sharder.ShardVal()
	if err != nil {
		return 0, Dst{}, err
	}

	id, err := s.gen.NextID(shardVal)
	if err != nil {
		return 0, Dst{}, err
	}

	dst, err := s.strategy.Shard(shardVal)
	if err != nil {
		return 0, Dst{}, err
	}

	return id, dst, nil
}

// NextID 生成 ID。
// 如果只需要 ID 而不需要立即知道分片信息，使用此方法。
// 后续可以通过 DstFromID 从 ID 中提取分片信息。
func (s *ShardHelper) NextID(sharder Sharder) (uint64, error) {
	shardVal, err := sharder.ShardVal()
	if err != nil {
		return 0, err
	}
	return s.gen.NextID(shardVal)
}

// Shard 计算分片目标。
// 适用于不需要生成 ID，只需要知道数据应该存放在哪个分片的场景。
func (s *ShardHelper) Shard(sharder Sharder) (Dst, error) {
	shardVal, err := sharder.ShardVal()
	if err != nil {
		return Dst{}, err
	}
	return s.strategy.Shard(shardVal)
}

// DstFromID 从 ID 中提取分片信息。
// 适用于根据已有 ID 查询数据的场景。
func (s *ShardHelper) DstFromID(id uint64) Dst {
	return s.strategy.DstFromID(id)
}

func (s *ShardHelper) DstFromSharder(sharder Sharder) (Dst, error) {
	shardVal, err := sharder.ShardVal()
	if err != nil {
		return Dst{}, err
	}
	return s.strategy.DstFromShardVal(shardVal), nil
}

// Broadcast 返回所有分片的目标列表。
// 适用于需要在所有分片上执行查询的场景 ( 如全量扫描 )。
func (s *ShardHelper) Broadcast() []Dst {
	return s.strategy.Broadcast()
}
