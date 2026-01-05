package idgen

// Generator 是 ID 生成器的接口。
type Generator interface {
	// NextID 生成 ID，需要传入分片值 ( 用于嵌入到 ID 中以支持分片 )。
	NextID(shardVal uint64) (uint64, error)
}
