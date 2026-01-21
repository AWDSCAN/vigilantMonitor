package oauth

import (
	_ "vigilantMonitorServer/internal/oauth/cloudflare"
	_ "vigilantMonitorServer/internal/oauth/factory"
	_ "vigilantMonitorServer/internal/oauth/generic"
	_ "vigilantMonitorServer/internal/oauth/github"
	_ "vigilantMonitorServer/internal/oauth/qq"
)

func All() {
	//empty function to ensure all OIDC providers are registered
}
