package api_rpc

import (
	"github.com/gin-gonic/gin"
	"github.com/gookit/event"
	"vigilantMonitorServer/internal/eventType"
)

func init() {
	event.On(eventType.ServerInitializeStart, event.ListenerFunc(func(e event.Event) error {
		r := e.Get("engine").(*gin.Engine)
		RegisterRouters("/api/rpc2", r)
		return nil
	}))
}
