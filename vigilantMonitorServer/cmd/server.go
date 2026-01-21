package cmd

import (
	"context"
	"crypto/tls"
	"fmt"
	"log"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"

	"vigilantMonitorServer/internal"
	"vigilantMonitorServer/internal/conf"
	"vigilantMonitorServer/internal/database/auditlog"
	"vigilantMonitorServer/internal/database/records"
	"vigilantMonitorServer/internal/database/tasks"
	"vigilantMonitorServer/internal/eventType"
	logutil "vigilantMonitorServer/internal/log"
	"vigilantMonitorServer/pkg/utils"
	"vigilantMonitorServer/public"

	"github.com/gin-gonic/gin"
	"github.com/gookit/event"

	"github.com/spf13/cobra"
)

var ServerCmd = &cobra.Command{
	Use:   "server",
	Short: "Start the server",
	Long:  `Start the server`,
	Run: func(cmd *cobra.Command, args []string) {
		RunServer()
	},
}
var AllowCors bool = false

func init() {
	RootCmd.AddCommand(ServerCmd)
}

func RunServer() {
	// #region 初始化
	internal.All()
	if conf.Version != conf.Version_Development {
		gin.SetMode(gin.ReleaseMode)
	}

	r := gin.New()
	r.Use(logutil.GinLogger())
	r.Use(logutil.GinRecovery())

	r.Use(func(c *gin.Context) {
		if AllowCors {
			c.Header("Access-Control-Allow-Origin", "*")
			c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, HEAD, OPTIONS")
			c.Header("Access-Control-Allow-Headers", "Origin, Content-Length, Content-Type, Authorization, Accept, X-CSRF-Token, X-Requested-With, Set-Cookie")
			c.Header("Access-Control-Expose-Headers", "Content-Length, Authorization, Set-Cookie")
			c.Header("Access-Control-Allow-Credentials", "false")
			c.Header("Access-Control-Max-Age", "43200") // 12 hours
			if c.Request.Method == "OPTIONS" {
				c.AbortWithStatus(204)
				return
			}
		}
		c.Next()
	})

	event.On(eventType.ConfigUpdated, event.ListenerFunc(func(e event.Event) error {
		newConf := e.Get("new").(conf.Config)
		AllowCors = newConf.Site.AllowCors
		public.UpdateIndex(newConf.ToV1Format())
		return nil
	}), event.High)

	err, _ := event.Trigger(eventType.ServerInitializeStart, event.M{"engine": r})
	if err != nil {
		slog.Error("Something went wrong during ServerInitializeStart event.", slog.Any("error", err))
		os.Exit(1)
	}

	public.Static(r.Group("/"), func(handlers ...gin.HandlerFunc) {
		r.NoRoute(handlers...)
	})

	// 初始化SSL证书
	if err := initializeSSL(); err != nil {
		slog.Error("Failed to initialize SSL", slog.Any("error", err))
		os.Exit(1)
	}

	srv := &http.Server{
		Addr:    conf.Conf.Listen,
		Handler: r,
	}

	// 配置TLS
	if conf.Conf.SSL.Enabled {
		tlsConfig := &tls.Config{
			MinVersion:               tls.VersionTLS12,
			PreferServerCipherSuites: true,
			CipherSuites: []uint16{
				tls.TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384,
				tls.TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,
				tls.TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,
				tls.TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,
				tls.TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305,
				tls.TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305,
			},
		}
		srv.TLSConfig = tlsConfig
	}

	event.Trigger(eventType.ServerInitializeDone, event.M{})
	ScheduledEventTasksInit()

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, os.Interrupt, syscall.SIGTERM)

	// 启动服务器
	if conf.Conf.SSL.Enabled && conf.Conf.SSL.ForceHTTPS {
		log.Printf("Starting HTTPS server on %s ...", conf.Conf.Listen)
		log.Printf("Using certificate: %s", conf.Conf.SSL.CertFile)
		log.Printf("Using private key: %s", conf.Conf.SSL.KeyFile)

		go func() {
			if err := srv.ListenAndServeTLS(conf.Conf.SSL.CertFile, conf.Conf.SSL.KeyFile); err != nil && err != http.ErrServerClosed {
				OnFatal(err)
				event.Trigger(eventType.ProcessExit, event.M{})
				log.Fatalf("HTTPS listen error: %s\n", err)
			}
		}()
	} else if conf.Conf.SSL.Enabled && conf.Conf.SSL.RedirectToHTTPS {
		// HTTPS + HTTP重定向模式
		log.Printf("Starting HTTPS server on %s ...", conf.Conf.Listen)
		log.Printf("Using certificate: %s", conf.Conf.SSL.CertFile)
		log.Printf("Using private key: %s", conf.Conf.SSL.KeyFile)

		// 启动HTTPS服务器
		go func() {
			if err := srv.ListenAndServeTLS(conf.Conf.SSL.CertFile, conf.Conf.SSL.KeyFile); err != nil && err != http.ErrServerClosed {
				OnFatal(err)
				event.Trigger(eventType.ProcessExit, event.M{})
				log.Fatalf("HTTPS listen error: %s\n", err)
			}
		}()

		// 启动HTTP重定向服务器
		httpPort := getHTTPRedirectPort(conf.Conf.Listen)
		if httpPort != "" {
			log.Printf("Starting HTTP redirect server on %s ...", httpPort)
			redirectServer := &http.Server{
				Addr:    httpPort,
				Handler: createHTTPSRedirectHandler(),
			}
			go func() {
				if err := redirectServer.ListenAndServe(); err != nil && err != http.ErrServerClosed {
					log.Printf("HTTP redirect server error: %s\n", err)
				}
			}()
		}
	} else {
		log.Printf("Starting HTTP server on %s ...", conf.Conf.Listen)
		log.Println("⚠️  WARNING: Running without HTTPS! It is highly recommended to enable SSL for production use.")

		go func() {
			if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
				OnFatal(err)
				event.Trigger(eventType.ProcessExit, event.M{})
				log.Fatalf("HTTP listen error: %s\n", err)
			}
		}()
	}

	<-quit
	OnShutdown()
	event.Trigger(eventType.ProcessExit, event.M{})
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	if err := srv.Shutdown(ctx); err != nil {
		log.Fatalf("Server forced to shutdown: %v", err)
	}

}

// initializeSSL 初始化SSL证书
func initializeSSL() error {
	if !conf.Conf.SSL.Enabled {
		return nil
	}

	// 检查证书是否存在
	valid, err := utils.CheckSSLCertificates(conf.Conf.SSL.CertFile, conf.Conf.SSL.KeyFile)
	if err != nil {
		slog.Warn("SSL certificate check failed", slog.Any("error", err))
		valid = false
	}

	// 如果证书无效且启用了自动生成
	if !valid && conf.Conf.SSL.AutoGenerate {
		log.Println("SSL certificates not found or invalid, generating self-signed certificates...")

		config := utils.DefaultSSLCertConfig()
		config.CommonName = "vigilant-monitor"
		config.Organization = "Vigilant Monitor"

		// 从Listen地址提取主机名和IP
		listenAddr := conf.Conf.Listen
		host := strings.Split(listenAddr, ":")[0]
		if host != "" && host != "0.0.0.0" && host != "::" {
			config.DNSNames = append(config.DNSNames, host)
		}

		if err := utils.GenerateSelfSignedCert(config, conf.Conf.SSL.CertFile, conf.Conf.SSL.KeyFile); err != nil {
			return fmt.Errorf("failed to generate SSL certificates: %w", err)
		}

		log.Printf("✓ Self-signed SSL certificates generated successfully")
		log.Printf("  Certificate: %s", conf.Conf.SSL.CertFile)
		log.Printf("  Private Key: %s", conf.Conf.SSL.KeyFile)
		log.Println("⚠️  Note: Self-signed certificates will show security warnings in browsers.")
		log.Println("   For production use, please use certificates from a trusted CA.")
	} else if !valid {
		return fmt.Errorf("SSL certificates not found or invalid at %s and %s", conf.Conf.SSL.CertFile, conf.Conf.SSL.KeyFile)
	} else {
		log.Println("✓ SSL certificates loaded successfully")

		// 显示证书信息
		if certInfo, err := utils.GetSSLCertInfo(conf.Conf.SSL.CertFile); err == nil {
			log.Printf("  Subject: %s", certInfo["subject"])
			log.Printf("  Valid until: %s", certInfo["not_after"])
		}
	}

	return nil
}

// getHTTPRedirectPort 获取HTTP重定向端口
func getHTTPRedirectPort(httpsAddr string) string {
	parts := strings.Split(httpsAddr, ":")
	if len(parts) < 2 {
		return ""
	}

	host := parts[0]
	if host == "" {
		host = "0.0.0.0"
	}

	// HTTPS默认443，HTTP默认80
	httpsPort := parts[len(parts)-1]
	if httpsPort == "443" {
		return host + ":80"
	}

	// 对于其他端口，不启动重定向服务器
	return ""
}

// createHTTPSRedirectHandler 创建HTTPS重定向处理器
func createHTTPSRedirectHandler() http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// 构建HTTPS URL
		httpsHost := r.Host

		// 如果当前监听在非标准端口，需要调整
		listenAddr := conf.Conf.Listen
		parts := strings.Split(listenAddr, ":")
		if len(parts) >= 2 {
			httpsPort := parts[len(parts)-1]
			if httpsPort != "443" {
				// 保持自定义端口
				hostParts := strings.Split(r.Host, ":")
				httpsHost = hostParts[0] + ":" + httpsPort
			}
		}

		httpsURL := "https://" + httpsHost + r.RequestURI
		http.Redirect(w, r, httpsURL, http.StatusMovedPermanently)
	})
}

// #region 定时任务
func DoScheduledWork() {
	tasks.ReloadPingSchedule()

	//records.DeleteRecordBefore(time.Now().Add(-time.Hour * 24 * 30))

	records.CompactRecord()

	event.On(eventType.SchedulerEvery30Minutes, event.ListenerFunc(func(e event.Event) error {
		cfg, err := conf.GetWithV1Format()
		if err != nil {
			slog.Warn("Failed to get config in scheduled task:", "error", err)
			return err
		}
		records.DeleteRecordBefore(time.Now().Add(-time.Hour * time.Duration(cfg.RecordPreserveTime)))
		records.CompactRecord()
		tasks.ClearTaskResultsByTimeBefore(time.Now().Add(-time.Hour * time.Duration(cfg.RecordPreserveTime)))
		tasks.DeletePingRecordsBefore(time.Now().Add(-time.Hour * time.Duration(cfg.PingRecordPreserveTime)))
		auditlog.RemoveOldLogs()
		return nil
	}))

	event.On(eventType.SchedulerEveryMinute, event.ListenerFunc(func(e event.Event) error {
		cfg, err := conf.GetWithV1Format()
		if err != nil {
			slog.Warn("Failed to get config in scheduled task:", "error", err)
			return err
		}
		if !cfg.RecordEnabled {
			records.DeleteAll()
			tasks.DeleteAllPingRecords()
		}

		return nil
	}))
}

func OnShutdown() {
	auditlog.Log("", "", "server is shutting down", "info")
}

func OnFatal(err error) {
	auditlog.Log("", "", "server encountered a fatal error: "+err.Error(), "error")
}

func ScheduledEventTasksInit() {
	go DoScheduledWork()
	go func() {
		every1m := time.NewTicker(1 * time.Minute)
		every5m := time.NewTicker(5 * time.Minute)
		every30m := time.NewTicker(30 * time.Minute)
		every1h := time.NewTicker(1 * time.Hour)
		every1d := time.NewTicker(24 * time.Hour)
		for {
			select {
			case <-every1m.C:
				event.Async(eventType.SchedulerEveryMinute, event.M{"interval": "1m"})
			case <-every5m.C:
				event.Async(eventType.SchedulerEvery5Minutes, event.M{"interval": "5m"})
			case <-every30m.C:
				event.Async(eventType.SchedulerEvery30Minutes, event.M{"interval": "30m"})
			case <-every1h.C:
				event.Async(eventType.SchedulerEveryHour, event.M{"interval": "1h"})
			case <-every1d.C:
				event.Async(eventType.SchedulerEveryDay, event.M{"interval": "1d"})
			}
		}
	}()
}
