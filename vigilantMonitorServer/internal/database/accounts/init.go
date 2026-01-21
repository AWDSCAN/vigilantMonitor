package accounts

import (
	"log"

	"github.com/gookit/event"
	"vigilantMonitorServer/internal/database/models"
	"vigilantMonitorServer/internal/dbcore"
	"vigilantMonitorServer/internal/eventType"
)

func init() {
	event.On(eventType.ServerInitializeStart, event.ListenerFunc(func(e event.Event) error {
		var count int64 = 0
		if dbcore.GetDBInstance().Model(&models.User{}).Count(&count); count == 0 {
			user, passwd, err := CreateDefaultAdminAccount()
			if err != nil {
				return err
			}
			log.Println("Default admin account created. Username:", user, ", Password:", passwd)
		}
		return nil
	}))
}
