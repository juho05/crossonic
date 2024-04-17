package main

import (
	"sync"
	"time"
)

type token struct {
	expires  time.Time
	username string
	// stored for subsonic api calls (secure-ish because it's only stored in memory)
	password string
}

type AuthService struct {
	tokens sync.Map
}

func NewAuthService() *AuthService {
	return &AuthService{}
}

func (a *AuthService) CreateAuthToken(username, password string) (authToken string, expires time.Time) {
	authToken = generateToken(32)
	expires = time.Now().Add(24 * time.Hour)
	a.tokens.Range(func(key, value any) bool {
		v := value.(token)
		if v.expires.Before(time.Now()) {
			a.tokens.Delete(key)
		}
		return true
	})
	a.tokens.Store(authToken, token{
		expires:  time.Now().Add(24 * time.Hour),
		username: username,
		password: password,
	})
	return authToken, expires
}

func (a *AuthService) VerifyToken(authToken string) (username, password string, ok bool) {
	value, ok := a.tokens.Load(authToken)
	if !ok {
		return "", "", false
	}
	v := value.(token)
	if v.expires.Before(time.Now()) {
		a.tokens.Delete(authToken)
		return "", "", false
	}
	return v.username, v.password, true
}
