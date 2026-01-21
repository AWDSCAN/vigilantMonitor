package dbcore

import (
	"fmt"
	"log"

	"github.com/gookit/event"
	"vigilantMonitorServer/internal/conf"
	"vigilantMonitorServer/internal/eventType"
	logu "vigilantMonitorServer/internal/log"
	"gorm.io/driver/mysql"
	"gorm.io/gorm"
)

func init() {
	event.On(eventType.ProcessStart, event.ListenerFunc(func(e event.Event) error {
		var err error

		logConfig := &gorm.Config{
			Logger:                                   logu.NewGormLogger(),
			DisableForeignKeyConstraintWhenMigrating: true, // 禁用外键约束，避免迁移时的问题
		}

		// MySQL 连接
		dsn := fmt.Sprintf("%s:%s@tcp(%s:%s)/%s?charset=utf8mb4&collation=utf8mb4_unicode_ci&parseTime=True&loc=Local",
			conf.Conf.Database.DatabaseUser,
			conf.Conf.Database.DatabasePass,
			conf.Conf.Database.DatabaseHost,
			conf.Conf.Database.DatabasePort,
			conf.Conf.Database.DatabaseName)
		instance, err = gorm.Open(mysql.Open(dsn), logConfig)
		if err != nil {
			return fmt.Errorf("failed to connect to MySQL database: %w", err)
		}
		log.Printf("Using MySQL database: %s@%s:%s/%s", conf.Conf.Database.DatabaseUser, conf.Conf.Database.DatabaseHost, conf.Conf.Database.DatabasePort, conf.Conf.Database.DatabaseName)
		// 设置数据库默认字符集为 utf8mb4
		instance.Exec("SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci")

		// 检查版本号决定是否需要迁移
		if needsMigration(instance) {
			log.Println("Version changed, running database migration...")
			if err := runMigrations(instance); err != nil {
				log.Fatalf("Failed to run migrations: %v", err)
			}
			updateSchemaVersion(instance)
			log.Println("Database migration completed")
		} else {
			log.Println("Version unchanged, skipping migration")
		}

		return nil
	}), event.Max+1)

}
