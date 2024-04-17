package main

import (
	"sync"
	"time"
)

type token struct {
	expires  time.Time
	username string
}

type AuthService struct {
	tokens sync.Map
}

func NewAuthService() *AuthService {
	return &AuthService{}
}

func (a *AuthService) LoginUser(username string) (authToken string, expires time.Time) {
	authToken = generateToken(32)
	expires = time.Now().Add(24 * time.Hour)
	a.tokens.Store(authToken, token{
		expires:  time.Now().Add(24 * time.Hour),
		username: username,
	})
	return authToken, expires
}
