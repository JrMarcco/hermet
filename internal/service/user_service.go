package service

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/jrmarcco/hermet/internal/domain"
	"github.com/jrmarcco/hermet/internal/errs"
	"github.com/jrmarcco/hermet/internal/repo"
	"golang.org/x/crypto/bcrypt"
)

type UserService interface {
	AddUser(ctx context.Context, user domain.BizUser) error

	ContactApplicant(ctx context.Context, event domain.ContactApplicantEvent) error

	ListContactApplications(ctx context.Context, targetID uint64) ([]domain.ContactApplication, error)
}

var _ UserService = (*DefaultUserService)(nil)

type DefaultUserService struct {
	bizUserRepo            repo.BizUserRepo
	userContactRepo        repo.UserContactRepo
	contactApplicationRepo repo.ContactApplicationRepo
	channelApplicationRepo repo.ChannelApplicationRepo
}

func NewDefaultUserService(
	bizUserRepo repo.BizUserRepo,
	userContactRepo repo.UserContactRepo,
	contactApplicationRepo repo.ContactApplicationRepo,
	channelApplicationRepo repo.ChannelApplicationRepo,
) *DefaultUserService {
	return &DefaultUserService{
		bizUserRepo:            bizUserRepo,
		userContactRepo:        userContactRepo,
		contactApplicationRepo: contactApplicationRepo,
		channelApplicationRepo: channelApplicationRepo,
	}
}

func (s *DefaultUserService) AddUser(ctx context.Context, user domain.BizUser) error {
	// 生成密码。
	passwd, err := bcrypt.GenerateFromPassword([]byte("hermet@2026"), bcrypt.DefaultCost)
	if err != nil {
		return fmt.Errorf("failed to generate password: %w", err)
	}

	user.Passwd = string(passwd)

	// 设置用户状态。
	user.UserStatus = domain.UserStatusActive

	// 设置版本控制。
	user.InfoVer = 1

	// 设置时间戳。
	user.CreatedAt = time.Now().UnixMilli()
	user.UpdatedAt = user.CreatedAt

	// 添加用户。
	_, err = s.bizUserRepo.Save(ctx, user)
	if err != nil {
		return err
	}
	return nil
}

func (s *DefaultUserService) ContactApplicant(ctx context.Context, event domain.ContactApplicantEvent) error {
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

func (s *DefaultUserService) ListContactApplications(ctx context.Context, targetID uint64) ([]domain.ContactApplication, error) {
	return s.contactApplicationRepo.ListPendingByTargetID(ctx, targetID)
}
