package sharding

import (
	"testing"

	"github.com/jrmarcco/hermet/internal/pkg/sharding/idgen/snowflake"
	"github.com/stretchr/testify/require"
)

func TestNewShardHelper(t *testing.T) {
	t.Parallel()

	gen := snowflake.NewGenerator()
	extractor := snowflake.NewExtractor()
	strategy, _ := NewModuloSharding(extractor, "db", "table", 4, 2)

	tests := []struct {
		name     string
		gen      interface{}
		strategy Strategy
		wantErr  bool
	}{
		{
			name:     "valid parameters",
			gen:      gen,
			strategy: strategy,
			wantErr:  false,
		},
		{
			name:     "nil generator",
			gen:      nil,
			strategy: strategy,
			wantErr:  true,
		},
		{
			name:     "nil strategy",
			gen:      gen,
			strategy: nil,
			wantErr:  true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()

			var g any
			if tt.gen != nil {
				g = tt.gen
			}

			var realGen any
			if g != nil {
				realGen = g
			}

			if tt.wantErr {
				// 模拟 nil 参数的情况。
				_, err := NewShardHelper(nil, tt.strategy)
				if err == nil && tt.gen == nil {
					// 期望错误且得到错误。
					return
				}
				_, err = NewShardHelper(gen, nil)
				if err == nil && tt.strategy == nil {
					t.Error("NewShardHelper() with nil strategy should return error")
				}
			} else {
				if realGen == nil {
					return
				}
				helper, err := NewShardHelper(gen, tt.strategy)
				if err != nil {
					t.Errorf("NewShardHelper() error = %v, wantErr %v", err, tt.wantErr)
				}
				if helper == nil {
					t.Error("NewShardHelper() returned nil")
				}
			}
		})
	}
}

func TestShardHelper_NextIdAndShard(t *testing.T) {
	t.Parallel()

	gen := snowflake.NewGenerator()
	extractor := snowflake.NewExtractor()
	strategy, _ := NewModuloSharding(extractor, "db", "table", 4, 2)
	helper, err := NewShardHelper(gen, strategy)
	if err != nil {
		t.Fatalf("NewShardHelper() error = %v", err)
	}

	sharder := NewSingleIDSharder(12345)

	id, dst, err := helper.NextIDAndShard(sharder)
	require.NoError(t, err)

	// 验证 ID 不为 0。
	if id == 0 {
		t.Error("NextIdAndShard() returned ID = 0")
	}

	// 验证分片信息不为空。
	if dst.DB == "" || dst.TB == "" {
		t.Error("NextIdAndShard() returned empty Dst")
	}

	// 验证从 ID 能正确提取分片信息。
	dstFromID := helper.DstFromID(id)
	if dstFromID.DB != dst.DB || dstFromID.TB != dst.TB {
		t.Errorf(
			"DstFromId() = %v.%v, want %v.%v",
			dstFromID.DB, dstFromID.TB, dst.DB, dst.TB,
		)
	}
}

func TestShardHelper_NextId(t *testing.T) {
	t.Parallel()

	gen := snowflake.NewGenerator()
	extractor := snowflake.NewExtractor()
	strategy, _ := NewModuloSharding(extractor, "db", "table", 4, 2)
	helper, err := NewShardHelper(gen, strategy)
	if err != nil {
		t.Fatalf("NewShardHelper() error = %v", err)
	}

	sharder := NewSingleIDSharder(12345)

	id1, err := helper.NextID(sharder)
	require.NoError(t, err)

	id2, err := helper.NextID(sharder)
	require.NoError(t, err)

	// 验证 ID 不为 0。
	if id1 == 0 || id2 == 0 {
		t.Error("NextId() returned ID = 0")
	}

	// 验证每次生成的 ID 不同。
	if id1 == id2 {
		t.Error("NextId() generated duplicate IDs")
	}
}

func TestShardHelper_Shard(t *testing.T) {
	t.Parallel()

	gen := snowflake.NewGenerator()
	extractor := snowflake.NewExtractor()
	strategy, _ := NewModuloSharding(extractor, "db", "table", 4, 2)
	helper, err := NewShardHelper(gen, strategy)
	if err != nil {
		t.Fatalf("NewShardHelper() error = %v", err)
	}

	sharder := NewSingleIDSharder(12345)

	dst, err := helper.Shard(sharder)
	require.NoError(t, err)

	// 验证分片信息不为空。
	if dst.DB == "" || dst.TB == "" {
		t.Error("Shard() returned empty Dst")
	}

	// 验证相同的 sharder 产生相同的分片结果。
	dst2, err := helper.Shard(sharder)
	require.NoError(t, err)

	if dst.DB != dst2.DB || dst.TB != dst2.TB {
		t.Error("Shard() is not deterministic")
	}
}

func TestShardHelper_Broadcast(t *testing.T) {
	t.Parallel()

	gen := snowflake.NewGenerator()
	extractor := snowflake.NewExtractor()
	strategy, _ := NewModuloSharding(extractor, "db", "table", 4, 2)
	helper, err := NewShardHelper(gen, strategy)
	if err != nil {
		t.Fatalf("NewShardHelper() error = %v", err)
	}

	dsts := helper.Broadcast()

	// 验证返回了所有分片。
	expectedCount := 4 * 2
	if len(dsts) != expectedCount {
		t.Errorf("Broadcast() returned %d shards, want %d", len(dsts), expectedCount)
	}

	// 验证没有重复。
	seen := make(map[string]bool)
	for _, dst := range dsts {
		key := dst.DB + "." + dst.TB
		if seen[key] {
			t.Errorf("Broadcast() contains duplicate: %s", key)
		}
		seen[key] = true
	}
}

func TestShardHelper_Consistency(t *testing.T) {
	t.Parallel()

	// 验证 NextIdAndShard 和单独调用 NextId、Shard 的一致性。
	gen1 := snowflake.NewGenerator()
	gen2 := snowflake.NewGenerator()

	extractor := snowflake.NewExtractor()
	strategy, _ := NewModuloSharding(extractor, "db", "table", 4, 2)

	helper1, _ := NewShardHelper(gen1, strategy)
	helper2, _ := NewShardHelper(gen2, strategy)

	sharder := NewSingleIDSharder(12345)

	// 方式1：使用 NextIdAndShard。
	id1, dst1, err := helper1.NextIDAndShard(sharder)
	require.NoError(t, err)

	// 方式2：单独调用。
	id2, err := helper2.NextID(sharder)
	require.NoError(t, err)

	dst2, err := helper2.Shard(sharder)
	require.NoError(t, err)

	// ID 应该不同 ( 不同的生成器 )。
	// 但分片结果应该相同 ( 相同的 sharder )。
	if dst1.DB != dst2.DB || dst1.TB != dst2.TB {
		t.Errorf(
			"Inconsistent shard results: %v.%v vs %v.%v",
			dst1.DB, dst1.TB, dst2.DB, dst2.TB,
		)
	}

	// 验证从 ID 提取的分片信息正确。
	dstFromID1 := helper1.DstFromID(id1)
	dstFromID2 := helper2.DstFromID(id2)

	if dstFromID1.DB != dst1.DB || dstFromID1.TB != dst1.TB {
		t.Error("DstFromId inconsistent with original Dst for helper1")
	}
	if dstFromID2.DB != dst2.DB || dstFromID2.TB != dst2.TB {
		t.Error("DstFromId inconsistent with original Dst for helper2")
	}
}
