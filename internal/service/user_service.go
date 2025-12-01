package service

import (
	"context"

	"github.com/JrMarcco/hermet/internal/errs"
	"github.com/JrMarcco/hermet/internal/pkg/xgin"
	"github.com/JrMarcco/hermet/internal/repo"
	"github.com/JrMarcco/jit/xjwt"
	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
)

type UserService interface {
	SignIn(ctx context.Context, account, accountType, credential string) (au xgin.AuthUser, err error)
	GenerateToken(ctx context.Context, au xgin.AuthUser) (accessToken, refreshToken string, err error)
	VerifyRefreshToken(ctx context.Context, refreshToken string) (au xgin.AuthUser, err error)
}

const accountTypeEmail = "email"

var _ UserService = (*DefaultUserService)(nil)

type DefaultUserService struct {
	repo repo.BizUserRepo

	atManager xjwt.Manager[xgin.AuthUser]
	rtManager xjwt.Manager[xgin.AuthUser]
}

func (s *DefaultUserService) SignIn(ctx context.Context, account, accountType, credential string) (au xgin.AuthUser, err error) {
	switch accountType {
	case accountTypeEmail:
		return s.signInByEmail(ctx, account, credential)
	default:
		return xgin.AuthUser{}, errs.ErrInvalidAccountType
	}
}

func (s *DefaultUserService) signInByEmail(ctx context.Context, account, credential string) (xgin.AuthUser, error) {
	user, err := s.repo.FindByEmail(ctx, account)
	if err != nil {
		return xgin.AuthUser{}, err
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.Passwd), []byte(credential)); err != nil {
		return xgin.AuthUser{}, errs.ErrInvalidUser
	}

	return xgin.AuthUser{
		SID: uuid.NewString(),
		UID: user.ID,
	}, nil
}

func (s *DefaultUserService) GenerateToken(_ context.Context, au xgin.AuthUser) (accessToken, refreshToken string, err error) {
	at, err := s.atManager.Encrypt(au)
	if err != nil {
		return "", "", err
	}
	rt, err := s.rtManager.Encrypt(au)
	if err != nil {
		return "", "", err
	}
	return at, rt, nil
}

func (s *DefaultUserService) VerifyRefreshToken(_ context.Context, refreshToken string) (au xgin.AuthUser, err error) {
	decrypted, err := s.rtManager.Decrypt(refreshToken)
	if err != nil {
		return xgin.AuthUser{}, err
	}
	return decrypted.Data, nil
}

func NewDefaultUserService(
	repo repo.BizUserRepo,
	atManager xjwt.Manager[xgin.AuthUser],
	rtManager xjwt.Manager[xgin.AuthUser],
) *DefaultUserService {
	return &DefaultUserService{
		repo:      repo,
		atManager: atManager,
		rtManager: rtManager,
	}
}
