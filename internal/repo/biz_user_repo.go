package repo

import (
	"context"
	"database/sql"

	"github.com/jrmarcco/hermet/internal/domain"
	"github.com/jrmarcco/hermet/internal/repo/dao"
)

//go:generate mockgen -source=biz_user_repo.go -destination=mock/biz_user_repo.mock.go -package=repomock -typed BizUserRepo

type BizUserRepo interface {
	Save(ctx context.Context, user domain.BizUser) (domain.BizUser, error)

	FindByID(ctx context.Context, id uint64) (domain.BizUser, error)
	FindByEmail(ctx context.Context, email string) (domain.BizUser, error)
	FindByMobile(ctx context.Context, mobile string) (domain.BizUser, error)
}

var _ BizUserRepo = (*DefaultBizUserRepo)(nil)

type DefaultBizUserRepo struct {
	dao dao.BizUserDao
}

func (r *DefaultBizUserRepo) Save(ctx context.Context, user domain.BizUser) (domain.BizUser, error) {
	entity := r.toEntity(user)
	saved, err := r.dao.Save(ctx, entity)
	if err != nil {
		return domain.BizUser{}, err
	}
	return r.toDomain(saved), nil
}

func (r *DefaultBizUserRepo) FindByID(ctx context.Context, id uint64) (domain.BizUser, error) {
	entity, err := r.dao.FindByID(ctx, id)
	if err != nil {
		return domain.BizUser{}, err
	}
	return r.toDomain(entity), nil
}

func (r *DefaultBizUserRepo) FindByEmail(ctx context.Context, email string) (domain.BizUser, error) {
	entity, err := r.dao.FindByEmail(ctx, email)
	if err != nil {
		return domain.BizUser{}, err
	}
	return r.toDomain(entity), nil
}

func (r *DefaultBizUserRepo) FindByMobile(ctx context.Context, mobile string) (domain.BizUser, error) {
	entity, err := r.dao.FindByMobile(ctx, mobile)
	if err != nil {
		return domain.BizUser{}, err
	}
	return r.toDomain(entity), nil
}

func (r *DefaultBizUserRepo) toEntity(user domain.BizUser) dao.BizUser {
	e := dao.BizUser{
		ID:        user.ID,
		Email:     user.Email,
		Mobile:    user.Mobile,
		Passwd:    user.Passwd,
		Nickname:  user.Nickname,
		CreatedAt: user.CreatedAt,
		UpdatedAt: user.UpdatedAt,
	}

	e.Avatar = sql.NullString{
		String: user.Avatar,
		Valid:  user.Avatar != "",
	}

	return e
}

func (r *DefaultBizUserRepo) toDomain(user dao.BizUser) domain.BizUser {
	d := domain.BizUser{
		ID:        user.ID,
		Email:     user.Email,
		Mobile:    user.Mobile,
		Passwd:    user.Passwd,
		Nickname:  user.Nickname,
		CreatedAt: user.CreatedAt,
		UpdatedAt: user.UpdatedAt,
	}

	if user.Avatar.Valid {
		d.Avatar = user.Avatar.String
	}

	return d
}

func NewDefaultBizUserRepo(dao dao.BizUserDao) *DefaultBizUserRepo {
	return &DefaultBizUserRepo{dao: dao}
}
