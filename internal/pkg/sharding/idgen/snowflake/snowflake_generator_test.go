package snowflake

import (
	"testing"

	"github.com/stretchr/testify/require"
)

func TestGenerator_NextId(t *testing.T) {
	t.Parallel()

	g := NewGenerator()

	shardValue := uint64(42)
	id1, err := g.NextID(shardValue)
	require.NoError(t, err)
	id2, err := g.NextID(shardValue)
	require.NoError(t, err)

	if id1 == id2 {
		t.Errorf("NextId() generated same ID: %d", id1)
	}

	extracted := ExtractShardVal(id1)
	expected := shardValue & hashMask
	if extracted != expected {
		t.Errorf("ExtractShardVal() = %v, want %v", extracted, expected)
	}
}

func TestGenerator_ConsistentSharding(t *testing.T) {
	t.Parallel()

	g := NewGenerator()

	shardValue := uint64(100)
	ids := make([]uint64, 10)
	for i := range 10 {
		id, err := g.NextID(shardValue)
		require.NoError(t, err)
		ids[i] = id
	}

	// 所有 ID 提取的分片值应该相同。
	expected := shardValue & hashMask
	for i, id := range ids {
		extracted := ExtractShardVal(id)
		if extracted != expected {
			t.Errorf("ID[%d] ExtractShardVal() = %v, want %v", i, extracted, expected)
		}
	}
}

func TestExtractFunctions(t *testing.T) {
	t.Parallel()

	g := NewGenerator()
	shardValue := uint64(123)
	id, err := g.NextID(shardValue)
	require.NoError(t, err)

	t.Run("ExtractHash", func(t *testing.T) {
		t.Parallel()

		extracted := ExtractShardVal(id)
		expected := shardValue & hashMask
		if extracted != expected {
			t.Errorf("ExtractShardVal() = %v, want %v", extracted, expected)
		}
	})
}

func TestGenerator_DifferentShardValues(t *testing.T) {
	t.Parallel()

	g := NewGenerator()

	// 测试不同的分片值生成的 ID 能正确区分。
	tests := []uint64{0, 1, 100, 1023, 1024, 65535}

	for _, shardValue := range tests {
		id, err := g.NextID(shardValue)
		require.NoError(t, err)

		extracted := ExtractShardVal(id)
		expected := shardValue & hashMask

		if extracted != expected {
			t.Errorf("shardValue=%d, ExtractShardVal() = %v, want %v",
				shardValue, extracted, expected)
		}
	}
}

func BenchmarkGenerator_NextId(b *testing.B) {
	g := NewGenerator()
	shardValue := uint64(42)

	b.ResetTimer()
	for b.Loop() {
		_, err := g.NextID(shardValue)
		require.NoError(b, err)
	}
}

func BenchmarkExtractHash(b *testing.B) {
	g := NewGenerator()
	id, err := g.NextID(42)
	require.NoError(b, err)

	for b.Loop() {
		_ = ExtractShardVal(id)
	}
}
