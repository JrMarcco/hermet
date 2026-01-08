package dao

import (
	"context"
	"database/sql"
	"fmt"

	"github.com/jrmarcco/hermet/internal/pkg/sharding"
	"github.com/jrmarcco/jit/xsync"
	"gorm.io/gorm"
)

type BizUser struct {
	ID       uint64 `gorm:"column:id"`
	Email    string `gorm:"column:email"`
	Mobile   string `gorm:"column:mobile"`
	Passwd   string `gorm:"column:passwd"`
	Nickname string `gorm:"column:nickname"`

	Avatar sql.NullString `gorm:"column:avatar"`

	CreatedAt int64 `gorm:"column:created_at"`
	UpdatedAt int64 `gorm:"column:updated_at"`
}

func (BizUser) TableName() string {
	return "biz_user"
}

//go:generate mockgen -source=biz_user_dao.go -destination=mock/biz_user_dao.mock.go -package=daomock -typed BizUserDao

type BizUserDao interface {
	FindByID(ctx context.Context, id uint64) (BizUser, error)
	FindByEmail(ctx context.Context, email string) (BizUser, error)
}

var _ BizUserDao = (*DefaultBizUserDao)(nil)

type DefaultBizUserDao struct {
	dbs         *xsync.Map[string, *gorm.DB]
	shardHelper *sharding.ShardHelper
}

func NewDefaultBizUserDao(dbs *xsync.Map[string, *gorm.DB], shardHelper *sharding.ShardHelper) *DefaultBizUserDao {
	return &DefaultBizUserDao{
		dbs:         dbs,
		shardHelper: shardHelper,
	}
}

func (d *DefaultBizUserDao) FindByID(ctx context.Context, id uint64) (BizUser, error) {
	var user BizUser

	dst := d.shardHelper.DstFromID(id)

	db, ok := d.dbs.Load(dst.DB)
	if !ok {
		return BizUser{}, fmt.Errorf("failed to load database [ %s ]", dst.DB)
	}

	err := db.WithContext(ctx).Table(dst.TB).Model(&BizUser{}).
		Where("id = ?", id).
		First(&user).Error
	return user, err
}

func (d *DefaultBizUserDao) FindByEmail(ctx context.Context, email string) (BizUser, error) {
	var user BizUser

	dst, err := d.shardHelper.DstFromSharder(sharding.NewStringSharder(email))
	if err != nil {
		return BizUser{}, fmt.Errorf("failed to get shard destination from email [ %s ]", email)
	}

	db, ok := d.dbs.Load(dst.DB)
	if !ok {
		return BizUser{}, fmt.Errorf("failed to load database [ %s ]", dst.DB)
	}

	err = db.WithContext(ctx).Table(dst.TB).Model(&BizUser{}).
		Where("email = ?", email).
		First(&user).Error
	return user, err
}
