package dao

import (
	"context"
	"fmt"

	"github.com/jrmarcco/hermet/internal/errs"
	"github.com/jrmarcco/hermet/internal/pkg/sharding"
	"github.com/jrmarcco/jit/xsync"
	"gorm.io/gorm"
)

// UserContact 【 写入侧 】用户联系人表。
// 以 UserID 为分片键。
type UserContact struct {
	ID uint64 `gorm:"column:id"`

	UserID    uint64 `gorm:"column:user_id"`
	ContactID uint64 `gorm:"column:contact_id"`

	RemarkName string   `gorm:"column:remark_name"`
	Source     string   `gorm:"column:source"`
	Tags       []string `gorm:"column:tags"`
	GroupName  string   `gorm:"column:group_name"`

	IsStarred bool `gorm:"column:is_starred"`
	IsBlocked bool `gorm:"column:is_blocked"`

	AddedAt   int64 `gorm:"column:added_at"`
	DeletedAt int64 `gorm:"column:deleted_at"`

	CreatedAt int64 `gorm:"column:created_at"`
	UpdatedAt int64 `gorm:"column:updated_at"`
}

type UserContactDao interface {
	FindByUserIDAndContactID(ctx context.Context, userID, contactID uint64) (UserContact, error)
}

var _ UserContactDao = (*DefaultUserContactDao)(nil)

type DefaultUserContactDao struct {
	dbs         *xsync.Map[string, *gorm.DB]
	shardHelper *sharding.ShardHelper
}

func NewDefaultUserContactDao(dbs *xsync.Map[string, *gorm.DB], shardHelper *sharding.ShardHelper) *DefaultUserContactDao {
	return &DefaultUserContactDao{
		dbs:         dbs,
		shardHelper: shardHelper,
	}
}

func (d *DefaultUserContactDao) FindByUserIDAndContactID(ctx context.Context, userID, contactID uint64) (UserContact, error) {
	dst, err := d.shardHelper.DstFromSharder(sharding.NewSingleIDSharder(userID))
	if err != nil {
		return UserContact{}, err
	}

	db, ok := d.dbs.Load(dst.DB)
	if !ok {
		return UserContact{}, fmt.Errorf("database not found: %w", errs.ErrRecordNotFound)
	}

	var uc UserContact
	err = db.WithContext(ctx).Table(dst.TB).Model(&UserContact{}).
		Where("user_id = ?", userID).
		Where("contact_id = ?", contactID).
		Where("deleted_at = ?", 0).
		First(&uc).Error
	if err != nil {
		return UserContact{}, err
	}

	return uc, nil
}
