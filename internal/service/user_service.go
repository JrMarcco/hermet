package service

type UserService interface{}

var _ UserService = (*DefaultUserService)(nil)

type DefaultUserService struct{}
