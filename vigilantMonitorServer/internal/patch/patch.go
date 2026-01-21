package patch

import (
	"log"

	"github.com/gookit/event"
	"vigilantMonitorServer/internal/eventType"
)

func init() {
	event.On(eventType.ProcessStart, event.ListenerFunc(func(e event.Event) error {
		// 旧版本 SQLite 数据库迁移已废弃
		// 如需从旧版本 SQLite 迁移，请使用 scripts/migrate_sqlite_to_mysql.sh 脚本
		log.Println("Patch system: SQLite migrations are deprecated, using MySQL only")
		return nil
	}), event.Max)
}
