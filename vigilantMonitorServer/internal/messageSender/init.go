package messageSender

import (
	"log"

	"github.com/gookit/event"
	"vigilantMonitorServer/internal/conf"
	"vigilantMonitorServer/internal/eventType"
)

func init() {
	event.On(eventType.ConfigUpdated, event.ListenerFunc(func(e event.Event) error {
		oldConf, newConf, err := conf.FromEvent(e)
		if err != nil {
			log.Printf("Failed to parse config from event: %v", err)
			return err
		}
		if newConf.Notification.NotificationMethod != oldConf.Notification.NotificationMethod {
			Initialize()
		}
		return nil
	}), event.Max)
}
