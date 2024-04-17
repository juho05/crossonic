package main

import (
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
)

type Handler struct {
	router      chi.Router
	AuthService *AuthService
}

func NewHandler() *Handler {
	h := &Handler{
		AuthService: NewAuthService(),
	}
	h.registerRoutes()
	return h
}

func (h *Handler) registerRoutes() {
	r := chi.NewRouter()
	r.Post("/login", h.handleLogin)
	h.router = r
}

func (h *Handler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	middleware.StripSlashes(h.router).ServeHTTP(w, r)
}
