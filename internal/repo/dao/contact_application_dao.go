package dao

import (
	"context"
	"fmt"
	"time"

	"github.com/jrmarcco/hermet/internal/pkg/sharding"
	"github.com/jrmarcco/jit/xsync"
	"gorm.io/gorm"
)

// ContactApplication 联系人申请表。
// 以 TargetID ( user_id ) 为分片键。
type ContactApplication struct {
	ID uint64 `gorm:"column:id"`

	ApplicantID uint64 `gorm:"column:applicant_id"`

	TargetID     uint64 `gorm:"column:target_id"`
	TargetName   string `gorm:"column:target_name"`
	TargetAvatar string `gorm:"column:target_avatar"`

	ApplicationStatus  string `gorm:"column:application_status"`
	ApplicationMessage string `gorm:"column:application_message"`

	ReviewedAt int64 `gorm:"column:reviewed_at"`

	CreatedAt int64 `gorm:"column:created_at"`
	UpdatedAt int64 `gorm:"column:updated_at"`
}

func (ContactApplication) TableName() string {
	return "contact_application"
}

type ContactApplicationDao interface {
	Save(ctx context.Context, ca ContactApplication) (ContactApplication, error)
}

var _ ContactApplicationDao = (*DefaultContactApplicationDao)(nil)

type DefaultContactApplicationDao struct {
	dbs         *xsync.Map[string, *gorm.DB]
	shardHelper *sharding.ShardHelper
}

func NewDefaultContactApplicationDao(dbs *xsync.Map[string, *gorm.DB], shardHelper *sharding.ShardHelper) *DefaultContactApplicationDao {
	return &DefaultContactApplicationDao{
		dbs:         dbs,
		shardHelper: shardHelper,
	}
}

func (d *DefaultContactApplicationDao) Save(ctx context.Context, ca ContactApplication) (ContactApplication, error) {
	id, dst, err := d.shardHelper.NextIDAndShard(sharding.NewSingleIDSharder(ca.TargetID))
	if err != nil {
		return ContactApplication{}, err
	}

	now := time.Now().UnixMilli()

	ca.ID = id
	ca.CreatedAt = now
	ca.UpdatedAt = now

	db, ok := d.dbs.Load(dst.DB)
	if !ok {
		return ContactApplication{}, fmt.Errorf("failed to load database [ %s ]", dst.DB)
	}

	err = db.WithContext(ctx).Table(dst.TB).Model(&ContactApplication{}).Create(&ca).Error
	return ca, err
}
