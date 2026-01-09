package repo

import (
	"context"
	"errors"

	"github.com/jrmarcco/hermet/internal/domain"
	"github.com/jrmarcco/hermet/internal/errs"
	"github.com/jrmarcco/hermet/internal/repo/dao"
	"gorm.io/gorm"
)

type UserContactRepo interface {
	FindByUserIDAndContactID(ctx context.Context, userID, contactID uint64) (domain.UserContact, error)
}

var _ UserContactRepo = (*DefaultUserContactRepo)(nil)

type DefaultUserContactRepo struct {
	userContactDao dao.UserContactDao
}

func NewDefaultUserContactRepo(userContactDao dao.UserContactDao) *DefaultUserContactRepo {
	return &DefaultUserContactRepo{
		userContactDao: userContactDao,
	}
}

func (r *DefaultUserContactRepo) FindByUserIDAndContactID(ctx context.Context, userID, contactID uint64) (domain.UserContact, error) {
	entity, err := r.userContactDao.FindByUserIDAndContactID(ctx, userID, contactID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return domain.UserContact{}, errs.ErrRecordNotFound
		}
		return domain.UserContact{}, err
	}
	return r.toDomain(entity), nil
}

// func (r *DefaultUserContactRepo) toEntity(uc domain.UserContact) dao.UserContact {
// 	return dao.UserContact{
// 		ID:         uc.ID,
// 		UserID:     uc.UserID,
// 		ContactID:  uc.ContactID,
// 		RemarkName: uc.RemarkName,
// 		Source:     string(uc.Source),
// 		Tags:       uc.Tags,
// 		GroupName:  uc.GroupName,
// 		IsStarred:  uc.IsStarred,
// 		IsBlocked:  uc.IsBlocked,
// 		AddedAt:    uc.AddedAt,
// 		DeletedAt:  uc.DeletedAt,
// 		CreatedAt:  uc.CreatedAt,
// 		UpdatedAt:  uc.UpdatedAt,
// 	}
// }

func (r *DefaultUserContactRepo) toDomain(uc dao.UserContact) domain.UserContact {
	return domain.UserContact{
		ID:         uc.ID,
		UserID:     uc.UserID,
		ContactID:  uc.ContactID,
		RemarkName: uc.RemarkName,
		Source:     domain.UserContactSource(uc.Source),
		Tags:       uc.Tags,
		GroupName:  uc.GroupName,
		IsStarred:  uc.IsStarred,
		IsBlocked:  uc.IsBlocked,
		AddedAt:    uc.AddedAt,
		DeletedAt:  uc.DeletedAt,
		CreatedAt:  uc.CreatedAt,
		UpdatedAt:  uc.UpdatedAt,
	}
}
