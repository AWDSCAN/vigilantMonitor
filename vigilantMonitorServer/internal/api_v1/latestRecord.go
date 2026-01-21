package api_v1

import (
	"github.com/gin-gonic/gin"
	"vigilantMonitorServer/internal/api_v1/resp"
	"vigilantMonitorServer/internal/api_v1/vars"
	"vigilantMonitorServer/internal/database/accounts"
	"vigilantMonitorServer/internal/database/models"
	"vigilantMonitorServer/internal/dbcore"
)

func GetClientRecentRecords(c *gin.Context) {
	uuid := c.Param("uuid")

	if uuid == "" {
		resp.RespondError(c, 400, "UUID is required")
		return
	}

	// 登录状态检查
	isLogin := false
	session, _ := c.Cookie("session_token")
	_, err := accounts.GetUserBySession(session)
	if err == nil {
		isLogin = true
	}

	// 仅在未登录时需要 Hidden 信息做过滤
	hiddenMap := map[string]bool{}
	if !isLogin {
		var hiddenClients []models.Client
		db := dbcore.GetDBInstance()
		_ = db.Select("uuid").Where("hidden = ?", true).Find(&hiddenClients).Error
		for _, cli := range hiddenClients {
			hiddenMap[cli.UUID] = true
		}

		if hiddenMap[uuid] {
			resp.RespondError(c, 400, "UUID is required") //防止未登录用户获取隐藏客户端数据
			return
		}
	}

	records, _ := vars.Records.Get(uuid)
	resp.RespondSuccess(c, records)
}
