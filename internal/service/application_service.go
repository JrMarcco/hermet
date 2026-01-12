package service

import (
	"context"
	"errors"
	"fmt"

	"github.com/jrmarcco/hermet/internal/domain"
	"github.com/jrmarcco/hermet/internal/errs"
	"github.com/jrmarcco/hermet/internal/repo"
)

type ApplicationService interface {
	ApplyContact(ctx context.Context, event domain.ContactApplicantEvent) error

	ReviewContactApplication(ctx context.Context, event domain.ContactReviewEvent) error

	GetContactApplications(ctx context.Context, targetID uint64) ([]domain.ContactApplication, error)
}

var _ ApplicationService = (*DefaultApplicationService)(nil)

type DefaultApplicationService struct {
	bizUserRepo            repo.BizUserRepo
	userContactRepo        repo.UserContactRepo
	contactApplicationRepo repo.ContactApplicationRepo
	channelApplicationRepo repo.ChannelApplicationRepo
}

func NewDefaultApplicationService(
	bizUserRepo repo.BizUserRepo,
	userContactRepo repo.UserContactRepo,
	contactApplicationRepo repo.ContactApplicationRepo,
	channelApplicationRepo repo.ChannelApplicationRepo,
) *DefaultApplicationService {
	return &DefaultApplicationService{
		bizUserRepo:            bizUserRepo,
		userContactRepo:        userContactRepo,
		contactApplicationRepo: contactApplicationRepo,
		channelApplicationRepo: channelApplicationRepo,
	}
}

func (s *DefaultApplicationService) ApplyContact(ctx context.Context, event domain.ContactApplicantEvent) error {
	// 判断是否已经存在联系人。
	uc, err := s.userContactRepo.FindByUserIDAndContactID(ctx, event.ApplicantID, event.TargetID)
	if err != nil && !errors.Is(err, errs.ErrRecordNotFound) {
		return err
	}

	// 已经存在联系人。
	if uc.ID != 0 {
		return fmt.Errorf("%w: contact already exists", errs.ErrInvalidParam)
	}

	// 查询申请人信息。
	bizUser, err := s.bizUserRepo.FindByID(ctx, event.ApplicantID)
	if err != nil {
		if errors.Is(err, errs.ErrRecordNotFound) {
			return errors.New("target user is not exists")
		}
		return err
	}

	// 提交申请
	ca := domain.ContactApplication{
		ApplicantID:        event.ApplicantID,
		TargetID:           event.TargetID,
		ApplicantName:      bizUser.Nickname,
		ApplicantAvatar:    bizUser.Avatar,
		ApplicationStatus:  domain.ApplicationStatusPending,
		ApplicationMessage: event.Message,
		Source:             event.Source,
	}

	_, err = s.contactApplicationRepo.Save(ctx, ca)
	if err != nil {
		return err
	}

	// TODO: 向 target 用户发送申请通知。
	// 向 target 用户发送申请通知。

	return nil
}

func (s *DefaultApplicationService) ReviewContactApplication(ctx context.Context, event domain.ContactReviewEvent) error {
	var err error
	switch event.Status {
	case domain.ApplicationStatusRejected:
		err = s.rejectContactApplication(ctx, event.ApplicationID)
	case domain.ApplicationStatusApproved:
		err = s.approveContactApplication(ctx, event.ApplicationID)
	default:
		return fmt.Errorf("%w: invalid status", errs.ErrInvalidParam)
	}

	if err != nil {
		return fmt.Errorf("failed to review contact application: %w", err)
	}

	// TODO: 向 applicant 用户发送通知。
	// 向 applicant 用户发送通知。

	return nil
}

// rejectContactApplication 拒绝联系人申请。
func (s *DefaultApplicationService) rejectContactApplication(_ context.Context, _ uint64) error {
	// TODO: not implemented
	panic("not implemented")
}

// approveContactApplication 批准联系人申请。
func (s *DefaultApplicationService) approveContactApplication(_ context.Context, _ uint64) error {
	// TODO: not implemented
	panic("not implemented")
}

func (s *DefaultApplicationService) GetContactApplications(ctx context.Context, targetID uint64) ([]domain.ContactApplication, error) {
	return s.contactApplicationRepo.ListPendingByTargetID(ctx, targetID)
}
