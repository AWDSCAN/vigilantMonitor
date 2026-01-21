package pingSchedule

import (
	"github.com/gookit/event"
	"vigilantMonitorServer/internal/eventType"
)

func init() {
	event.On(eventType.ServerInitializeDone, event.ListenerFunc(func(e event.Event) error {
		return ReloadPingSchedule()
	}))
}
