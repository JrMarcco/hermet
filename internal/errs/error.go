package errs

import "errors"

var (
	ErrUnauthorized = errors.New("unauthorized")

	ErrInvalidParam = errors.New("invalid param")

	ErrInvalidUser        = errors.New("invalid user")
	ErrInvalidAccountType = errors.New("invalid account type")

	ErrRecordNotFound = errors.New("record not found")
)
