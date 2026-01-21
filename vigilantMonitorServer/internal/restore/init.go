package restore

import (
	"github.com/gookit/event"
	"vigilantMonitorServer/internal/eventType"
)

func init() {
	event.On(eventType.ProcessStart, event.ListenerFunc(func(e event.Event) error {
		if NeedBackupRestore() {
			return RestoreBackup()
		}
		return nil
	}), event.Max+10)
}
