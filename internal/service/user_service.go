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

	AddContact(ctx context.Context, applicantID, targetID uint64, message string) error
}

var _ UserService = (*DefaultUserService)(nil)

type DefaultUserService struct {
	bizUserRepo            repo.BizUserRepo
	contactApplicationRepo repo.ContactApplicationRepo
	channelApplicationRepo repo.ChannelApplicationRepo
}

func NewDefaultUserService(
	bizUserRepo repo.BizUserRepo,
	contactApplicationRepo repo.ContactApplicationRepo,
	channelApplicationRepo repo.ChannelApplicationRepo,
) *DefaultUserService {
	return &DefaultUserService{
		bizUserRepo:            bizUserRepo,
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

func (s *DefaultUserService) AddContact(ctx context.Context, applicantID, targetID uint64, message string) error {
	// 查询用户信息。
	bizUser, err := s.bizUserRepo.FindByID(ctx, targetID)
	if err != nil {
		if errors.Is(err, errs.ErrRecordNotFound) {
			return errors.New("target user is not exists")
		}
		return err
	}

	// 提交申请
	ca := domain.ContactApplication{
		ApplicantID:        applicantID,
		TargetID:           targetID,
		TargetName:         bizUser.Nickname,
		TargetAvatar:       bizUser.Avatar,
		ApplicationStatus:  domain.ApplicationStatusPending,
		ApplicationMessage: message,
	}

	_, err = s.contactApplicationRepo.Save(ctx, ca)
	if err != nil {
		return err
	}

	return nil
}
