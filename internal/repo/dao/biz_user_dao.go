package dao

import (
	"context"
	"time"

	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

type BizUser struct {
	ID       uint64 `gorm:"column:id"`
	Email    string `gorm:"column:email"`
	Mobile   string `gorm:"column:mobile"`
	Avatar   string `gorm:"column:avatar"`
	Passwd   string `gorm:"column:passwd"`
	Nickname string `gorm:"column:nickname"`

	CreateAt int64 `gorm:"column:create_at"`
	UpdateAt int64 `gorm:"column:update_at"`
}

func (BizUser) TableName() string {
	return "biz_user"
}

//go:generate mockgen -source=biz_user_dao.go -destination=mock/biz_user_dao.mock.go -package=daomock -typed BizUserDao

type BizUserDao interface {
	Save(ctx context.Context, user BizUser) (BizUser, error)

	FindByID(ctx context.Context, id uint64) (BizUser, error)
	FindByEmail(ctx context.Context, email string) (BizUser, error)
	FindByMobile(ctx context.Context, mobile string) (BizUser, error)
}

var _ BizUserDao = (*DefaultBizUserDao)(nil)

type DefaultBizUserDao struct {
	db *gorm.DB
}

func (d *DefaultBizUserDao) Save(ctx context.Context, user BizUser) (BizUser, error) {
	now := time.Now().UnixMilli()
	user.CreateAt = now
	user.UpdateAt = now

	res := d.db.WithContext(ctx).Model(&BizUser{}).Clauses(clause.OnConflict{
		Columns: []clause.Column{{Name: "id"}},
		DoUpdates: clause.Assignments(map[string]any{
			"email":     user.Email,
			"avatar":    user.Avatar,
			"passwd":    user.Passwd,
			"nickname":  user.Nickname,
			"update_at": now,
		}),
	}).Create(&user)
	if res.Error != nil {
		return BizUser{}, res.Error
	}
	return user, nil
}

func (d *DefaultBizUserDao) FindByID(ctx context.Context, id uint64) (BizUser, error) {
	var user BizUser
	err := d.db.WithContext(ctx).Model(&BizUser{}).
		Where("id = ?", id).
		First(&user).Error
	return user, err
}

func (d *DefaultBizUserDao) FindByEmail(ctx context.Context, email string) (BizUser, error) {
	var user BizUser
	err := d.db.WithContext(ctx).Model(&BizUser{}).
		Where("email = ?", email).
		First(&user).Error
	return user, err
}

func (d *DefaultBizUserDao) FindByMobile(ctx context.Context, mobile string) (BizUser, error) {
	var user BizUser
	err := d.db.WithContext(ctx).Model(&BizUser{}).
		Where("mobile = ?", mobile).
		First(&user).Error
	return user, err
}

func NewDefaultBizUserDao(db *gorm.DB) *DefaultBizUserDao {
	return &DefaultBizUserDao{db: db}
}
