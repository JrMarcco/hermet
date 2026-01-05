package sharding

import (
	"errors"
	"fmt"
)

var _ Strategy = (*ModuloSharding)(nil)

// ModuloSharding 取模分片策略。
// 使用取模算法将数据均匀分布到多个数据库和表中。
//
// 分片算法：
// 1. 计算总分片数：totalShards = dbShardCount * tbShardCount
// 2. 计算分片索引：shardIndex = shardVal % totalShards
// 3. 映射到具体库表：
//   - dbSuffix = shardIndex % dbShardCount
//   - tbSuffix = shardIndex / dbShardCount
//
// 示例：
//
//	假设 8 个库，每个库 4 张表，总共 32 个分片
//	shardVal=0  -> db_0.table_0
//	shardVal=1  -> db_1.table_0
//	shardVal=8  -> db_0.table_1
//	shardVal=31 -> db_7.table_3
type ModuloSharding struct {
	extractor ShardValExtractor

	dbPrefix string // 数据库名前缀
	tbPrefix string // 表名前缀

	dbShardCount uint64 // 分库数量
	tbShardCount uint64 // 每个库的分表数量
}

// NewModuloSharding 创建一个取模分片策略。
// - extractor: 分片值提取器，不能为 nil
// - dbPrefix: 数据库名前缀，如 "hermet_db"
// - tbPrefix: 表名前缀，如 "message"
// - dbShardCount: 分库数量，必须大于 0
// - tbShardCount: 每个库的分表数量，必须大于 0
//
// 返回错误的情况：
// - extractor 为 nil
// - 前缀为空字符串
// - 分库或分表数量为 0
func NewModuloSharding(
	extractor ShardValExtractor,
	dbPrefix string,
	tbPrefix string,
	dbShardCount uint64,
	tbShardCount uint64,
) (*ModuloSharding, error) {
	if extractor == nil {
		return nil, errors.New("extractor cannot be nil")
	}
	if dbShardCount == 0 {
		return nil, errors.New("dbShardCount must be greater than 0")
	}
	if tbShardCount == 0 {
		return nil, errors.New("tbShardCount must be greater than 0")
	}
	if dbPrefix == "" {
		return nil, errors.New("dbPrefix cannot be empty")
	}
	if tbPrefix == "" {
		return nil, errors.New("tbPrefix cannot be empty")
	}

	return &ModuloSharding{
		extractor:    extractor,
		dbPrefix:     dbPrefix,
		tbPrefix:     tbPrefix,
		dbShardCount: dbShardCount,
		tbShardCount: tbShardCount,
	}, nil
}

func (s *ModuloSharding) Shard(shardVal uint64) (Dst, error) {
	// 使用总分片数取模，确保数据均匀分布。
	totalShards := s.dbShardCount * s.tbShardCount
	shardIndex := shardVal % totalShards

	// 先按库分，再按表分，确保均匀分布。
	dbSuffix := shardIndex % s.dbShardCount
	tbSuffix := shardIndex / s.dbShardCount

	return Dst{
		DBSuffix: dbSuffix,
		TBSuffix: tbSuffix,
		DB:       fmt.Sprintf("%s_%d", s.dbPrefix, dbSuffix),
		TB:       fmt.Sprintf("%s_%d", s.tbPrefix, tbSuffix),
	}, nil
}

func (s *ModuloSharding) DstFromID(id uint64) Dst {
	shardVal := s.extractor.ExtractShardVal(id)

	totalShards := s.dbShardCount * s.tbShardCount
	shardIndex := shardVal % totalShards

	dbSuffix := shardIndex % s.dbShardCount
	tbSuffix := shardIndex / s.dbShardCount

	return Dst{
		DBSuffix: dbSuffix,
		TBSuffix: tbSuffix,
		DB:       fmt.Sprintf("%s_%d", s.dbPrefix, dbSuffix),
		TB:       fmt.Sprintf("%s_%d", s.tbPrefix, tbSuffix),
	}
}

func (s *ModuloSharding) Broadcast() []Dst {
	res := make([]Dst, s.dbShardCount*s.tbShardCount)

	for i := uint64(0); i < s.dbShardCount; i++ {
		for j := uint64(0); j < s.tbShardCount; j++ {
			res[i*s.tbShardCount+j] = Dst{
				DBSuffix: i,
				TBSuffix: j,
				DB:       fmt.Sprintf("%s_%d", s.dbPrefix, i),
				TB:       fmt.Sprintf("%s_%d", s.tbPrefix, j),
			}
		}
	}

	return res
}
