package internal

import (
	// Import all internal packages to ensure their init() functions are executed
	_ "vigilantMonitorServer/internal/api_rpc"
	_ "vigilantMonitorServer/internal/api_v1"
	_ "vigilantMonitorServer/internal/client"
	_ "vigilantMonitorServer/internal/cloudflared"
	_ "vigilantMonitorServer/internal/common"
	_ "vigilantMonitorServer/internal/conf"
	_ "vigilantMonitorServer/internal/database"
	_ "vigilantMonitorServer/internal/eventType"
	_ "vigilantMonitorServer/internal/geoip"
	_ "vigilantMonitorServer/internal/jsruntime"
	_ "vigilantMonitorServer/internal/log"
	_ "vigilantMonitorServer/internal/messageSender"
	_ "vigilantMonitorServer/internal/mjpeg"
	_ "vigilantMonitorServer/internal/nezha"
	_ "vigilantMonitorServer/internal/notifier"
	_ "vigilantMonitorServer/internal/oauth"
	_ "vigilantMonitorServer/internal/patch"
	_ "vigilantMonitorServer/internal/pingSchedule"
	_ "vigilantMonitorServer/internal/plugin"
	_ "vigilantMonitorServer/internal/renewal"
	_ "vigilantMonitorServer/internal/restore"
	_ "vigilantMonitorServer/internal/ws"
)

func All() {}
