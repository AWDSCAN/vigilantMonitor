package admin

import (
	"github.com/gin-gonic/gin"
	"vigilantMonitorServer/internal/api_v1/resp"
	"vigilantMonitorServer/internal/database/auditlog"
	"vigilantMonitorServer/internal/database/models"
	"vigilantMonitorServer/internal/dbcore"
)

func OrderWeight(c *gin.Context) {
	var req = make(map[string]int)
	if err := c.ShouldBindJSON(&req); err != nil {
		resp.RespondError(c, 400, "Invalid or missing request body: "+err.Error())
		return
	}
	db := dbcore.GetDBInstance()
	for uuid, weight := range req {
		err := db.Model(&models.Client{}).Where("uuid = ?", uuid).Update("weight", weight).Error
		if err != nil {
			resp.RespondError(c, 500, "Failed to update client weight: "+err.Error())
			return
		}
	}
	uuid, _ := c.Get("uuid")
	auditlog.Log(c.ClientIP(), uuid.(string), "order clients", "info")
	resp.RespondSuccess(c, nil)
}
