package main

import (
	"fmt"
	"net/url"
	"os"
	"strconv"

	"github.com/joho/godotenv"
	"github.com/juho05/log"
)

type ConfigData struct {
	Port        int
	SubsonicURL *url.URL
	LogLevel    log.Severity
}

var Config ConfigData

func loadConfig() error {
	godotenv.Load()
	subURLStr := os.Getenv("SUBSONIC_URL")
	if subURLStr == "" {
		return fmt.Errorf("SUBSONIC_URL environment variable is required")
	}
	subURL, err := url.Parse(subURLStr)
	if err != nil {
		return fmt.Errorf("invalid value for SUBSONIC_URL")
	}

	portStr := os.Getenv("PORT")
	if portStr == "" {
		portStr = "8080"
	}
	port, err := strconv.Atoi(portStr)
	if err != nil || port <= 0 || port > 65535 {
		return fmt.Errorf("invalid value for PORT")
	}

	logLevelStr := os.Getenv("LOG_LEVEL")
	if logLevelStr == "" {
		logLevelStr = "4"
	}
	logLevel, err := strconv.Atoi(logLevelStr)
	if err != nil || logLevel < int(log.NONE) || logLevel > int(log.TRACE) {
		return fmt.Errorf("invalid value for LOG_LEVEL")
	}

	Config = ConfigData{
		Port:        port,
		SubsonicURL: subURL,
		LogLevel:    log.Severity(logLevel),
	}
	return nil
}
