package repo

import (
	"context"

	"github.com/jrmarcco/hermet/internal/domain"
	"github.com/jrmarcco/hermet/internal/repo/dao"
)

type ContactApplicationRepo interface {
	Save(ctx context.Context, application domain.ContactApplication) (domain.ContactApplication, error)
}

var _ ContactApplicationRepo = (*DefaultContactApplicationRepo)(nil)

type DefaultContactApplicationRepo struct {
	contactApplicationDao dao.ContactApplicationDao
}

func NewDefaultContactApplicationRepo(contactApplicationDao dao.ContactApplicationDao) *DefaultContactApplicationRepo {
	return &DefaultContactApplicationRepo{
		contactApplicationDao: contactApplicationDao,
	}
}

func (r *DefaultContactApplicationRepo) Save(ctx context.Context, application domain.ContactApplication) (domain.ContactApplication, error) {
	entity, err := r.contactApplicationDao.Save(ctx, r.toEntity(application))
	if err != nil {
		return domain.ContactApplication{}, err
	}
	return r.toDomain(entity), nil
}

func (r *DefaultContactApplicationRepo) toEntity(application domain.ContactApplication) dao.ContactApplication {
	return dao.ContactApplication{
		ID:                 application.ID,
		ApplicantID:        application.ApplicantID,
		TargetID:           application.TargetID,
		TargetName:         application.TargetName,
		TargetAvatar:       application.TargetAvatar,
		ApplicationStatus:  string(application.ApplicationStatus),
		ApplicationMessage: application.ApplicationMessage,
		ReviewedAt:         application.ReviewedAt,
		CreatedAt:          application.CreatedAt,
		UpdatedAt:          application.UpdatedAt,
	}
}

func (r *DefaultContactApplicationRepo) toDomain(entity dao.ContactApplication) domain.ContactApplication {
	return domain.ContactApplication{
		ID:                 entity.ID,
		ApplicantID:        entity.ApplicantID,
		TargetID:           entity.TargetID,
		TargetName:         entity.TargetName,
		TargetAvatar:       entity.TargetAvatar,
		ApplicationStatus:  domain.ApplicationStatus(entity.ApplicationStatus),
		ApplicationMessage: entity.ApplicationMessage,
		ReviewedAt:         entity.ReviewedAt,
		CreatedAt:          entity.CreatedAt,
		UpdatedAt:          entity.UpdatedAt,
	}
}
