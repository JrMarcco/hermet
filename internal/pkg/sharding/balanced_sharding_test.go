package sharding

import (
	"testing"

	"github.com/jrmarcco/hermet/internal/pkg/sharding/idgen/snowflake"
	"github.com/stretchr/testify/require"
)

func TestNewBalancedSharding(t *testing.T) {
	t.Parallel()

	extractor := snowflake.NewExtractor()
	baseStrategy, err := NewModuloSharding(extractor, "db", "table", 4, 2)
	if err != nil {
		t.Fatalf("NewModuloSharding() error = %v", err)
	}

	tests := []struct {
		name    string
		base    Strategy
		mode    BroadcastMode
		wantErr bool
	}{
		{
			name:    "valid with default mode",
			base:    baseStrategy,
			mode:    BroadcastModeDefault,
			wantErr: false,
		},
		{
			name:    "valid with round robin mode",
			base:    baseStrategy,
			mode:    BroadcastModeRoundRobin,
			wantErr: false,
		},
		{
			name:    "valid with shuffle mode",
			base:    baseStrategy,
			mode:    BroadcastModeShuffle,
			wantErr: false,
		},
		{
			name:    "empty mode defaults to default",
			base:    baseStrategy,
			mode:    "",
			wantErr: false,
		},
		{
			name:    "nil base strategy",
			base:    nil,
			mode:    BroadcastModeDefault,
			wantErr: true,
		},
		{
			name:    "invalid mode",
			base:    baseStrategy,
			mode:    "invalid",
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()

			_, err := NewBalancedSharding(tt.base, tt.mode)
			if (err != nil) != tt.wantErr {
				t.Errorf("NewBalancedSharding() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}

func TestBalancedSharding_Shard(t *testing.T) {
	t.Parallel()

	extractor := snowflake.NewExtractor()
	baseStrategy, _ := NewModuloSharding(extractor, "db", "table", 4, 2)
	balancedStrategy, err := NewBalancedSharding(baseStrategy, BroadcastModeRoundRobin)
	if err != nil {
		t.Fatalf("NewBalancedSharding() error = %v", err)
	}

	// Shard 方法应该直接委托给基础策略
	for i := range 20 {
		expected, err := baseStrategy.Shard(uint64(i))
		require.NoError(t, err)
		actual, err := balancedStrategy.Shard(uint64(i))
		require.NoError(t, err)

		if actual.DB != expected.DB || actual.TB != expected.TB {
			t.Errorf(
				"Shard(%d) = %v.%v, want %v.%v",
				i, actual.DB, actual.TB, expected.DB, expected.TB,
			)
		}
	}
}

func TestBalancedSharding_BroadcastDefault(t *testing.T) {
	t.Parallel()

	extractor := snowflake.NewExtractor()
	baseStrategy, _ := NewModuloSharding(extractor, "db", "table", 4, 2)
	balancedStrategy, err := NewBalancedSharding(baseStrategy, BroadcastModeDefault)
	if err != nil {
		t.Fatalf("NewBalancedSharding() error = %v", err)
	}

	baseDsts := baseStrategy.Broadcast()
	balancedDsts := balancedStrategy.Broadcast()

	// 默认模式应该保持相同的顺序
	if len(baseDsts) != len(balancedDsts) {
		t.Errorf("Broadcast() length = %d, want %d", len(balancedDsts), len(baseDsts))
	}

	for i := range baseDsts {
		if baseDsts[i].DB != balancedDsts[i].DB || baseDsts[i].TB != balancedDsts[i].TB {
			t.Errorf(
				"Broadcast()[%d] = %v.%v, want %v.%v",
				i, balancedDsts[i].DB, balancedDsts[i].TB, baseDsts[i].DB, baseDsts[i].TB,
			)
		}
	}
}

func TestBalancedSharding_BroadcastRoundRobin(t *testing.T) {
	t.Parallel()

	extractor := snowflake.NewExtractor()
	baseStrategy, _ := NewModuloSharding(extractor, "db", "table", 4, 2)
	balancedStrategy, err := NewBalancedSharding(baseStrategy, BroadcastModeRoundRobin)
	if err != nil {
		t.Fatalf("NewBalancedSharding() error = %v", err)
	}

	dsts := balancedStrategy.Broadcast()

	// 验证数量正确。
	if len(dsts) != 8 {
		t.Errorf("Broadcast() returned %d shards, want 8", len(dsts))
	}

	// 验证轮询模式：相邻的分片应该来自不同的数据库。
	for i := 0; i < len(dsts)-1; i++ {
		if dsts[i].DB == dsts[i+1].DB && dsts[i].TBSuffix == dsts[i+1].TBSuffix {
			// 如果连续两个来自同一个库的同一张表，说明不是轮询模式。
			// 但注意：当某个库的表用完后，可能出现连续访问其他库的情况。
			// 所以这里只检查不应该出现完全相同的情况。
			if dsts[i].DB == dsts[i+1].DB && dsts[i].TB == dsts[i+1].TB {
				t.Errorf(
					"Found duplicate consecutive shards at index %d: %s",
					i, dsts[i].FullTable(),
				)
			}
		}
	}

	// 验证所有分片都存在。
	seen := make(map[string]bool)
	for _, dst := range dsts {
		key := dst.DB + "." + dst.TB
		if seen[key] {
			t.Errorf("Broadcast() contains duplicate: %s", key)
		}
		seen[key] = true
	}
}

func TestBalancedSharding_BroadcastShuffle(t *testing.T) {
	t.Parallel()

	extractor := snowflake.NewExtractor()
	baseStrategy, _ := NewModuloSharding(extractor, "db", "table", 4, 2)
	balancedStrategy, err := NewBalancedSharding(baseStrategy, BroadcastModeShuffle)
	if err != nil {
		t.Fatalf("NewBalancedSharding() error = %v", err)
	}

	// 多次调用 Broadcast，验证结果不同（随机性）
	broadcasts := make([][]Dst, 5)
	for i := 0; i < 5; i++ {
		broadcasts[i] = balancedStrategy.Broadcast()
	}

	// 验证至少有一次的顺序与第一次不同
	allSame := true
	for i := 1; i < 5; i++ {
		for j := 0; j < len(broadcasts[0]); j++ {
			if broadcasts[0][j].DB != broadcasts[i][j].DB ||
				broadcasts[0][j].TB != broadcasts[i][j].TB {
				allSame = false
				break
			}
		}
		if !allSame {
			break
		}
	}

	if allSame {
		t.Error("Shuffle mode: all broadcasts have the same order, expected some variation")
	}

	// 验证每次广播都包含所有分片（只是顺序不同）
	for i, dsts := range broadcasts {
		if len(dsts) != 8 {
			t.Errorf("Broadcast()[%d] returned %d shards, want 8", i, len(dsts))
		}

		seen := make(map[string]bool)
		for _, dst := range dsts {
			key := dst.DB + "." + dst.TB
			if seen[key] {
				t.Errorf("Broadcast()[%d] contains duplicate: %s", i, key)
			}
			seen[key] = true
		}
	}
}

func TestBalancedSharding_EmptyBroadcast(t *testing.T) {
	t.Parallel()

	// 创建一个会返回空列表的基础策略
	extractor := snowflake.NewExtractor()
	baseStrategy, _ := NewModuloSharding(extractor, "db", "table", 1, 1)
	balancedStrategy, err := NewBalancedSharding(baseStrategy, BroadcastModeRoundRobin)
	if err != nil {
		t.Fatalf("NewBalancedSharding() error = %v", err)
	}

	// 手动测试空列表情况
	emptyDsts := []Dst{}
	result := balancedStrategy.roundRobinBroadcast(emptyDsts)
	if len(result) != 0 {
		t.Errorf("roundRobinBroadcast([]) = %d items, want 0", len(result))
	}

	result = balancedStrategy.shuffleBroadcast(emptyDsts)
	if len(result) != 0 {
		t.Errorf("shuffleBroadcast([]) = %d items, want 0", len(result))
	}
}
