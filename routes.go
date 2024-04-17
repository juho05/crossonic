package main

import (
	"errors"
	"net/http"
)

func (h *Handler) handleLogin(w http.ResponseWriter, r *http.Request) {
	type request struct {
		Username string `json:"username"`
		Password string `json:"password"`
	}
	body, err := decodeBody[request](r)
	if err != nil {
		badRequest(w)
		return
	}
	_, err = subsonicRequest[struct{}](r.Context(), body.Username, body.Password, "/ping", nil, "")
	if err != nil {
		if errors.Is(err, ErrSubsonicInvalidCredentials) {
			clientError(w, http.StatusUnauthorized)
		} else {
			serverError(w, err)
		}
		return
	}
	token, expires := h.AuthService.CreateAuthToken(body.Username, body.Password)
	type response struct {
		Token       string `json:"token"`
		Expires     int64  `json:"expires"`
		SubsonicURL string `json:"subsonicURL"`
	}
	respond(w, http.StatusOK, response{
		Token:       token,
		Expires:     expires.Unix(),
		SubsonicURL: Config.SubsonicURL.String(),
	})
}

func (h *Handler) handlePing(w http.ResponseWriter, r *http.Request) {
	username, password, ok := h.authUser(r)
	if !ok {
		clientError(w, http.StatusUnauthorized)
		return
	}
	_, err := subsonicRequest[struct{}](r.Context(), username, password, "/ping", nil, "")
	if err != nil {
		if errors.Is(err, ErrSubsonicInvalidCredentials) {
			clientError(w, http.StatusUnauthorized)
		} else {
			serverError(w, err)
		}
		return
	}
	respond(w, http.StatusOK, nil)
}
