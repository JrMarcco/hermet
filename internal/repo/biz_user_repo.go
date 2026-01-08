package repo

import (
	"context"

	"github.com/jrmarcco/hermet/internal/domain"
	"github.com/jrmarcco/hermet/internal/repo/dao"
)

//go:generate mockgen -source=biz_user_repo.go -destination=mock/biz_user_repo.mock.go -package=repomock -typed BizUserRepo

type BizUserRepo interface {
	FindByID(ctx context.Context, id uint64) (domain.BizUser, error)
	FindByEmail(ctx context.Context, email string) (domain.BizUser, error)
}

var _ BizUserRepo = (*DefaultBizUserRepo)(nil)

type DefaultBizUserRepo struct {
	dao dao.BizUserDao
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
