package errs

import "errors"

var (
	ErrUnauthorized = errors.New("unauthorized")

	ErrInvalidUser        = errors.New("invalid user")
	ErrInvalidAccountType = errors.New("invalid account type")
)
