package main

import (
	"log"
	"log/slog"

	"vigilantMonitorServer/cmd"
	"vigilantMonitorServer/internal/conf"
	logutil "vigilantMonitorServer/internal/log"
)

func main() {
	if conf.Version == conf.Version_Development {
		logutil.SetupGlobalLogger(slog.LevelDebug)
	} else {
		logutil.SetupGlobalLogger(slog.LevelInfo)
	}

	log.Printf("vigilant Monitor %s (hash: %s)", conf.Version, conf.CommitHash)

	cmd.Execute()
}
