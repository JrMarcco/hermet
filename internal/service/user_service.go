package service

import (
	"context"

	"github.com/google/uuid"
	"github.com/jrmarcco/hermet/internal/errs"
	"github.com/jrmarcco/hermet/internal/pkg/xgin"
	"github.com/jrmarcco/hermet/internal/repo"
	"github.com/jrmarcco/jit/xjwt"
	authv1 "github.com/jrmarcco/synp-api/api/go/auth/v1"
	"golang.org/x/crypto/bcrypt"
)

type UserService interface {
	SignIn(ctx context.Context, account, accountType, credential string) (user xgin.ContextUser, err error)
	GenerateToken(ctx context.Context, user xgin.ContextUser) (accessToken, refreshToken string, err error)
	VerifyRefreshToken(ctx context.Context, refreshToken string) (user xgin.ContextUser, err error)
}

const accountTypeEmail = "email"

var _ UserService = (*DefaultUserService)(nil)

type DefaultUserService struct {
	repo        repo.BizUserRepo
	messageRepo repo.MessageRepo

	atManager xjwt.Manager[authv1.JwtPayload]
	rtManager xjwt.Manager[authv1.JwtPayload]
}

func (s *DefaultUserService) SignIn(ctx context.Context, account, accountType, credential string) (user xgin.ContextUser, err error) {
	switch accountType {
	case accountTypeEmail:
		return s.signInByEmail(ctx, account, credential)
	default:
		return xgin.ContextUser{}, errs.ErrInvalidAccountType
	}
}

func (s *DefaultUserService) signInByEmail(ctx context.Context, account, credential string) (xgin.ContextUser, error) {
	user, err := s.repo.FindByEmail(ctx, account)
	if err != nil {
		return xgin.ContextUser{}, err
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.Passwd), []byte(credential)); err != nil {
		return xgin.ContextUser{}, errs.ErrInvalidUser
	}

	return xgin.ContextUser{
		SID: uuid.NewString(),
		UID: user.ID,
	}, nil
}

func (s *DefaultUserService) GenerateToken(_ context.Context, user xgin.ContextUser) (accessToken, refreshToken string, err error) {
	at, err := s.atManager.Encrypt(authv1.JwtPayload{
		BizId:     user.BID,
		UserId:    user.UID,
		SessionId: user.SID,
	})
	if err != nil {
		return "", "", err
	}
	rt, err := s.rtManager.Encrypt(authv1.JwtPayload{
		BizId:     user.BID,
		UserId:    user.UID,
		SessionId: user.SID,
	})
	if err != nil {
		return "", "", err
	}
	return at, rt, nil
}

func (s *DefaultUserService) VerifyRefreshToken(_ context.Context, refreshToken string) (user xgin.ContextUser, err error) {
	decrypted, err := s.rtManager.Decrypt(refreshToken)
	if err != nil {
		return xgin.ContextUser{}, err
	}
	return xgin.ContextUser{
		BID: decrypted.Data.BizId,
		UID: decrypted.Data.UserId,
		SID: decrypted.Data.SessionId,
	}, nil
}

func NewDefaultUserService(
	repo repo.BizUserRepo,
	messageRepo repo.MessageRepo,

	atManager xjwt.Manager[authv1.JwtPayload],
	rtManager xjwt.Manager[authv1.JwtPayload],
) *DefaultUserService {
	return &DefaultUserService{
		repo:        repo,
		messageRepo: messageRepo,

		atManager: atManager,
		rtManager: rtManager,
	}
}
