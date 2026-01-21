package messageSender

import (
	_ "vigilantMonitorServer/internal/messageSender/bark"
	_ "vigilantMonitorServer/internal/messageSender/email"
	_ "vigilantMonitorServer/internal/messageSender/empty"
	_ "vigilantMonitorServer/internal/messageSender/javascript"
	_ "vigilantMonitorServer/internal/messageSender/serverchan3"
	_ "vigilantMonitorServer/internal/messageSender/serverchanturbo"
	_ "vigilantMonitorServer/internal/messageSender/telegram"
	_ "vigilantMonitorServer/internal/messageSender/webhook"
)

func All() {
}
