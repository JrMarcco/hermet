package produce

import (
	"context"

	"github.com/JrMarcco/hermet/internal/pkg/xmq"
)

type Producer interface {
	Produce(ctx context.Context, msg *xmq.Message) error
}
