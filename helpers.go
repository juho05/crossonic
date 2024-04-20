package main

import (
	"bytes"
	"context"
	"crypto/md5"
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"math/big"
	"net/http"
	"net/url"
	"runtime/debug"
	"strings"

	"github.com/juho05/log"
)

func respond(w http.ResponseWriter, status int, body any) {
	data, err := json.Marshal(body)
	if err != nil {
		serverError(w, fmt.Errorf("respond: %w", err))
		return
	}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	w.Write(data)
}

func decodeBody[T any](r *http.Request) (T, error) {
	var obj T
	err := json.NewDecoder(r.Body).Decode(&obj)
	r.Body.Close()
	return obj, err
}

func generateToken(length int) string {
	const letters = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
	ret := make([]byte, length)
	for i := 0; i < length; i++ {
		num, err := rand.Int(rand.Reader, big.NewInt(int64(len(letters))))
		if err != nil {
			panic(err)
		}
		ret[i] = letters[num.Int64()]
	}

	return string(ret)
}

func (h *Handler) authUser(r *http.Request) (username, password string, ok bool) {
	parts := strings.Split(r.Header.Get("Authorization"), " ")
	if len(parts) != 2 || parts[0] != "Bearer" {
		return "", "", false
	}
	return h.AuthService.VerifyToken(parts[1])
}

func subsonicRequest[T any](ctx context.Context, username, password, uri string, values map[string]string, dataProperty string) (T, error) {
	var obj T
	r, err := createSubsonicRequest(ctx, username, password, uri, values)
	if err != nil {
		return obj, err
	}
	return executeSubsonicRequest[T](ctx, r, dataProperty)
}

func createSubsonicRequest(ctx context.Context, username, password, uri string, values map[string]string) (*http.Request, error) {
	if !strings.HasPrefix(uri, "/") {
		uri = "/" + uri
	}
	u, err := url.Parse(uri)
	if err != nil {
		return nil, fmt.Errorf("create subsonic request: %w", err)
	}
	if values == nil {
		values = make(map[string]string)
	}
	values["u"] = username
	values["c"] = "crossonic-server"
	values["f"] = "json"
	values["v"] = "1.15.0"

	salt := generateToken(10)
	hash := md5.Sum([]byte(password + salt))
	encodedHash := hex.EncodeToString(hash[:])
	values["s"] = salt
	values["t"] = encodedHash

	query := u.Query()
	for k, v := range values {
		query.Set(k, v)
	}
	u.RawFragment = ""
	request, err := http.NewRequestWithContext(ctx, http.MethodPost, Config.SubsonicURL.String()+"/rest"+u.String(), bytes.NewBufferString(query.Encode()))
	if err != nil {
		return nil, fmt.Errorf("create subsonic request: %w", err)
	}
	request.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	return request, nil
}

var (
	ErrSubsonicInvalidResponse      = errors.New("subsonic-invalid-response")
	ErrSubsonicGeneric              = errors.New("subsonic-generic")
	ErrSubsonicBadRequest           = errors.New("subsonic-bad-request")
	ErrSubsonicIncompatibleVersions = errors.New("subsonic-incompatible-versions")
	ErrSubsonicInvalidCredentials   = errors.New("subsonic-invalid-credentials")
	ErrSubsonicNotFound             = errors.New("subsonic-not-found")
	ErrSubsonicForbidden            = errors.New("subsonic-forbidden")
	ErrSubsonicAuthTypeNotSupported = errors.New("subsonic-auth-type-not-supported")
)

func executeSubsonicRequest[T any](ctx context.Context, req *http.Request, dataProperty string) (T, error) {
	var obj T
	res, err := http.DefaultClient.Do(req)
	if err != nil {
		return obj, fmt.Errorf("execute subsonic request: %w", err)
	}
	type response struct {
		SubsonicResponse map[string]json.RawMessage `json:"subsonic-response"`
	}
	var data response
	err = json.NewDecoder(res.Body).Decode(&data)
	res.Body.Close()
	if err != nil {
		return obj, fmt.Errorf("execute subsonic request: %w", err)
	}
	if data.SubsonicResponse == nil || data.SubsonicResponse["status"] == nil {
		return obj, fmt.Errorf("missing subsonic-response or status: %w", ErrSubsonicInvalidResponse)
	}
	var status string
	err = json.Unmarshal(data.SubsonicResponse["status"], &status)
	if err != nil {
		return obj, fmt.Errorf("invalid status: %w", ErrSubsonicInvalidResponse)
	}
	if status == "ok" {
		if dataProperty != "" {
			if _, ok := data.SubsonicResponse[dataProperty]; !ok {
				return obj, fmt.Errorf("missing data property: %w", ErrSubsonicInvalidResponse)
			}
			err = json.Unmarshal(data.SubsonicResponse[dataProperty], &obj)
			if err != nil {
				return obj, fmt.Errorf("invalid data property: %w", ErrSubsonicInvalidResponse)
			}
		}
		return obj, nil
	}
	type erro struct {
		Code    int    `json:"code"`
		Message string `json:"message"`
	}
	var e erro
	err = json.Unmarshal(data.SubsonicResponse["error"], &e)
	if err != nil {
		return obj, fmt.Errorf("invalid error property: %w", ErrSubsonicInvalidResponse)
	}
	err = ErrSubsonicGeneric
	switch e.Code {
	case 10:
		err = ErrSubsonicBadRequest
	case 20, 30:
		err = ErrSubsonicIncompatibleVersions
	case 40:
		err = ErrSubsonicInvalidCredentials
	case 41:
		err = ErrSubsonicAuthTypeNotSupported
	case 50:
		err = ErrSubsonicForbidden
	case 70:
		err = ErrSubsonicNotFound
	}
	return obj, errors.Join(err, errors.New(e.Message))
}

func badRequest(w http.ResponseWriter) {
	clientError(w, http.StatusBadRequest)
}

func clientError(w http.ResponseWriter, status int) {
	http.Error(w, http.StatusText(status), status)
}

func serverError(w http.ResponseWriter, err error) {
	log.Errorf("%s\n%s", err.Error(), debug.Stack())
	http.Error(w, http.StatusText(http.StatusInternalServerError), http.StatusInternalServerError)
}
