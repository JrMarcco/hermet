package repo

import "github.com/jrmarcco/hermet/internal/repo/dao"

type MessageRepo interface{}

var _ MessageRepo = (*DefaultMessageRepo)(nil)

type DefaultMessageRepo struct {
	dao dao.MessageDao
}

func NewDefaultMessageRepo(dao dao.MessageDao) *DefaultMessageRepo {
	return &DefaultMessageRepo{dao: dao}
}
