package sharding

import (
	"context"
	"testing"
)

func TestContextWithDst(t *testing.T) {
	t.Parallel()

	dst := Dst{
		DBSuffix: 1,
		TBSuffix: 2,
		DB:       "test_db_1",
		TB:       "test_table_2",
	}

	newCtx := ContextWithDst(t.Context(), dst)

	// 验证 context 不为 nil
	if newCtx == nil {
		t.Fatal("ContextWithDst() returned nil")
	}

	// 验证可以从 context 中提取 Dst
	extractedDst, ok := DstFromContext(newCtx)
	if !ok {
		t.Fatal("DstFromContext() failed to extract Dst")
	}

	if extractedDst.DB != dst.DB || extractedDst.TB != dst.TB {
		t.Errorf("DstFromContext() = %v, want %v", extractedDst, dst)
	}
}

func TestDstFromContext_NotSet(t *testing.T) {
	t.Parallel()

	// 没有设置 Dst 的 context
	_, ok := DstFromContext(t.Context())
	if ok {
		t.Error("DstFromContext() should return false for context without Dst")
	}
}

func TestDstFromContext_WrongType(t *testing.T) {
	t.Parallel()

	// 虽然这个测试在实际使用中不太可能发生，但验证类型安全
	ctx := context.WithValue(t.Context(), dstContextKey{}, "wrong_type")

	_, ok := DstFromContext(ctx)
	if ok {
		t.Error("DstFromContext() should return false for wrong type")
	}
}

func TestDst_FullTable(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name string
		dst  Dst
		want string
	}{
		{
			name: "normal case",
			dst: Dst{
				DBSuffix: 0,
				TBSuffix: 0,
				DB:       "hermet_db_0",
				TB:       "message_0",
			},
			want: "hermet_db_0.message_0",
		},
		{
			name: "with underscores",
			dst: Dst{
				DBSuffix: 3,
				TBSuffix: 7,
				DB:       "my_app_db_3",
				TB:       "user_data_7",
			},
			want: "my_app_db_3.user_data_7",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()

			if got := tt.dst.FullTable(); got != tt.want {
				t.Errorf("FullTable() = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestContextPropagation(t *testing.T) {
	t.Parallel()

	// 测试 context 在调用链中的传递
	dst := Dst{
		DBSuffix: 5,
		TBSuffix: 3,
		DB:       "db_5",
		TB:       "table_3",
	}

	ctx := t.Context()
	ctx = ContextWithDst(ctx, dst)

	// 模拟函数调用链
	level1 := func(ctx context.Context) context.Context {
		// 验证可以读取
		extractedDst, ok := DstFromContext(ctx)
		if !ok {
			t.Error("Level 1: failed to extract Dst")
		}
		if extractedDst.DB != dst.DB {
			t.Error("Level 1: extracted wrong Dst")
		}
		return ctx
	}

	level2 := func(ctx context.Context) {
		// 验证可以读取
		extractedDst, ok := DstFromContext(ctx)
		if !ok {
			t.Error("Level 2: failed to extract Dst")
		}
		if extractedDst.TB != dst.TB {
			t.Error("Level 2: extracted wrong Dst")
		}
	}

	ctx = level1(ctx)
	level2(ctx)
}
