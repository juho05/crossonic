package main

import (
	"context"
	"errors"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/juho05/log"
)

func run() error {
	handler := NewHandler()
	server := http.Server{
		Addr:     fmt.Sprintf("0.0.0.0:%d", Config.Port),
		ErrorLog: log.NewStdLogger(log.ERROR),
		Handler:  handler,
	}
	closed := make(chan struct{})
	go func() {
		sigint := make(chan os.Signal, 1)
		signal.Notify(sigint, syscall.SIGINT, syscall.SIGTERM)
		<-sigint
		timeout, cancelTimeout := context.WithTimeout(context.Background(), 5*time.Second)
		log.Info("Shutting down...")
		server.Shutdown(timeout)
		cancelTimeout()
		close(closed)
	}()
	log.Infof("Listening on http://0.0.0.0:%d...", Config.Port)
	err := server.ListenAndServe()
	if errors.Is(err, http.ErrServerClosed) {
		err = nil
	}
	if err == nil {
		<-closed
	}
	return err
}

func main() {
	err := loadConfig()
	if err != nil {
		fmt.Fprintln(os.Stderr, "ERROR:", err)
		os.Exit(1)
	}
	log.SetSeverity(Config.LogLevel)
	if err := run(); err != nil {
		fmt.Fprintln(os.Stderr, "ERROR:", err)
		os.Exit(2)
	}
}
