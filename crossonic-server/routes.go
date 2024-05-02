package main

import (
	"errors"
	"fmt"
	"net/http"
	"strconv"

	"github.com/juho05/log"
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
	if noAuth, _ := strconv.ParseBool(r.URL.Query().Get("noAuth")); noAuth {
		respond(w, http.StatusOK, "crossonic-success")
		return
	}
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
	respond(w, http.StatusOK, "crossonic-success")
}

type scrobble struct {
	TimeUnixMS    int64   `json:"timeUnixMS"`
	DurationMS    *int64  `json:"durationMS"`
	SongID        string  `json:"songID"`
	SongName      string  `json:"songName"`
	SongDuration  *int    `json:"songDuration"`
	MusicBrainzID *string `json:"musicBrainzId"`
	AlbumID       *string `json:"albumID"`
	AlbumName     *string `json:"albumName"`
	ArtistID      *string `json:"artistID"`
	ArtistName    *string `json:"artistName"`
	Update        bool    `json:"update"`
}

func (h *Handler) handleNowPlaying(w http.ResponseWriter, r *http.Request) {
	username, password, ok := h.authUser(r)
	if !ok {
		clientError(w, http.StatusUnauthorized)
		return
	}
	type request struct {
		Scrobble *scrobble `json:"scrobble"`
	}
	body, err := decodeBody[request](r)
	if err != nil {
		badRequest(w)
		return
	}
	if body.Scrobble == nil {
		// subsonic does not support setting now playing to null
		respond(w, http.StatusOK, nil)
		return
	}
	_, err = subsonicRequest[struct{}](r.Context(), username, password, "/scrobble", map[string]string{
		"submission": "false",
		"id":         body.Scrobble.SongID,
		"time":       fmt.Sprint(body.Scrobble.TimeUnixMS),
	}, "")
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

func (h *Handler) handleScrobble(w http.ResponseWriter, r *http.Request) {
	username, password, ok := h.authUser(r)
	if !ok {
		clientError(w, http.StatusUnauthorized)
		return
	}
	type request struct {
		Scrobbles []scrobble `json:"scrobbles"`
	}
	body, err := decodeBody[request](r)
	if err != nil || body.Scrobbles == nil {
		badRequest(w)
		return
	}
	var successes int
	var skipped int
	for _, s := range body.Scrobbles {
		if s.Update {
			skipped++
			log.Tracef("Skipping scrobble '%s' (id: %s) for user '%s' because updating is not yet supported.", s.SongName, s.SongID, username)
			continue
		}
		_, err = subsonicRequest[struct{}](r.Context(), username, password, "/scrobble", map[string]string{
			"submission": "true",
			"id":         s.SongID,
			"time":       fmt.Sprint(s.TimeUnixMS),
		}, "")
		if err != nil {
			log.Errorf("Failed to scrobble '%s' (id: %s) for user '%s': %s", s.SongName, s.SongID, username, err)
			if errors.Is(err, ErrSubsonicInvalidCredentials) {
				clientError(w, http.StatusUnauthorized)
				return
			}
			continue
		}
		log.Tracef("Scrobbled '%s' (id: %s) for user '%s'", s.SongName, s.SongID, username)
		successes++
	}
	if len(body.Scrobbles) > 0 && successes == 0 && skipped < len(body.Scrobbles) {
		if errors.Is(err, ErrSubsonicNotFound) {
			clientError(w, http.StatusNotFound)
		} else {
			respond(w, http.StatusInternalServerError, nil)
		}
		return
	}
	respond(w, http.StatusOK, nil)
}
