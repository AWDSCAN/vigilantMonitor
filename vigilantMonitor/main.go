package main

import (
	"os"

	"vigilantMonitor/cmd"
)

func main() {
	cmd.Execute()
	os.Exit(0)
}
