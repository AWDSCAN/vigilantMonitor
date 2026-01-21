package api_v1

import (
	"github.com/gin-gonic/gin"
	"vigilantMonitorServer/internal/api_v1/resp"
	"vigilantMonitorServer/internal/database"
)

func GetPublicSettings(c *gin.Context) {
	p, e := database.GetPublicInfo()
	if e != nil {
		resp.RespondError(c, 500, e.Error())
		return
	}
	resp.RespondSuccess(c, p)
}
