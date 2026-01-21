package cmd

import (
	"fmt"
	"log"
	"os"

	"vigilantMonitorServer/internal/conf"
	"vigilantMonitorServer/pkg/utils"

	"github.com/spf13/cobra"
)

var SSLCmd = &cobra.Command{
	Use:   "ssl",
	Short: "SSL certificate management",
	Long:  `Manage SSL certificates for HTTPS server`,
}

var sslGenerateCmd = &cobra.Command{
	Use:   "generate",
	Short: "Generate self-signed SSL certificate",
	Long:  `Generate a self-signed SSL certificate for HTTPS`,
	Run: func(cmd *cobra.Command, args []string) {
		// 配置在init中已经加载
		certFile := "./data/ssl/cert.pem"
		keyFile := "./data/ssl/key.pem"

		// 如果配置存在且有值，使用配置中的路径
		if conf.Conf.SSL.CertFile != "" {
			certFile = conf.Conf.SSL.CertFile
		}
		if conf.Conf.SSL.KeyFile != "" {
			keyFile = conf.Conf.SSL.KeyFile
		}

		// 从命令行参数获取覆盖值
		if certPath, _ := cmd.Flags().GetString("cert"); certPath != "" {
			certFile = certPath
		}
		if keyPath, _ := cmd.Flags().GetString("key"); keyPath != "" {
			keyFile = keyPath
		}

		// 生成证书配置
		config := utils.DefaultSSLCertConfig()

		if cn, _ := cmd.Flags().GetString("common-name"); cn != "" {
			config.CommonName = cn
		}
		if org, _ := cmd.Flags().GetString("organization"); org != "" {
			config.Organization = org
		}
		if days, _ := cmd.Flags().GetInt("days"); days > 0 {
			config.ValidDays = days
		}
		if keyType, _ := cmd.Flags().GetString("key-type"); keyType != "" {
			config.KeyType = keyType
		}

		fmt.Println("Generating self-signed SSL certificate...")
		fmt.Printf("  Common Name: %s\n", config.CommonName)
		fmt.Printf("  Organization: %s\n", config.Organization)
		fmt.Printf("  Valid Days: %d\n", config.ValidDays)
		fmt.Printf("  Key Type: %s\n", config.KeyType)
		fmt.Printf("  Certificate: %s\n", certFile)
		fmt.Printf("  Private Key: %s\n", keyFile)

		if err := utils.GenerateSelfSignedCert(config, certFile, keyFile); err != nil {
			log.Fatalf("Failed to generate certificate: %v", err)
		}

		fmt.Println("\n✓ SSL certificate generated successfully!")
		fmt.Println("\nTo use this certificate, update your komari.json:")
		fmt.Println(`{
  "ssl": {
    "enabled": true,
    "cert_file": "` + certFile + `",
    "key_file": "` + keyFile + `",
    "auto_generate": false,
    "force_https": true
  }
}`)
		fmt.Println("\n⚠️  Note: This is a self-signed certificate and will show security warnings in browsers.")
		fmt.Println("   For production use, please use certificates from a trusted CA (e.g., Let's Encrypt).")
	},
}

var sslInfoCmd = &cobra.Command{
	Use:   "info",
	Short: "Show SSL certificate information",
	Long:  `Display information about the current SSL certificate`,
	Run: func(cmd *cobra.Command, args []string) {
		// 配置在init中已经加载
		certFile := "./data/ssl/cert.pem"
		if conf.Conf.SSL.CertFile != "" {
			certFile = conf.Conf.SSL.CertFile
		}
		if certPath, _ := cmd.Flags().GetString("cert"); certPath != "" {
			certFile = certPath
		}

		// 检查证书文件是否存在
		if _, err := os.Stat(certFile); os.IsNotExist(err) {
			fmt.Printf("Certificate file not found: %s\n", certFile)
			return
		}

		// 获取证书信息
		info, err := utils.GetSSLCertInfo(certFile)
		if err != nil {
			log.Fatalf("Failed to read certificate: %v", err)
		}

		fmt.Println("SSL Certificate Information:")
		fmt.Println("═══════════════════════════════════════════════════════")
		fmt.Printf("Subject         : %s\n", info["subject"])
		fmt.Printf("Issuer          : %s\n", info["issuer"])
		fmt.Printf("Serial Number   : %s\n", info["serial_number"])
		fmt.Printf("Valid From      : %s\n", info["not_before"])
		fmt.Printf("Valid Until     : %s\n", info["not_after"])
		fmt.Printf("Is CA           : %v\n", info["is_ca"])

		if dnsNames, ok := info["dns_names"].([]string); ok && len(dnsNames) > 0 {
			fmt.Printf("DNS Names       : %v\n", dnsNames)
		}

		if ipAddrs := info["ip_addresses"]; ipAddrs != nil {
			fmt.Printf("IP Addresses    : %v\n", ipAddrs)
		}
		fmt.Println("═══════════════════════════════════════════════════════")
	},
}

var sslCheckCmd = &cobra.Command{
	Use:   "check",
	Short: "Check SSL certificate validity",
	Long:  `Check if SSL certificates exist and are valid`,
	Run: func(cmd *cobra.Command, args []string) {
		// 配置在init中已经加载
		certFile := "./data/ssl/cert.pem"
		keyFile := "./data/ssl/key.pem"

		if conf.Conf.SSL.CertFile != "" {
			certFile = conf.Conf.SSL.CertFile
		}
		if conf.Conf.SSL.KeyFile != "" {
			keyFile = conf.Conf.SSL.KeyFile
		}

		if certPath, _ := cmd.Flags().GetString("cert"); certPath != "" {
			certFile = certPath
		}
		if keyPath, _ := cmd.Flags().GetString("key"); keyPath != "" {
			keyFile = keyPath
		}

		fmt.Printf("Checking SSL certificates...\n")
		fmt.Printf("  Certificate: %s\n", certFile)
		fmt.Printf("  Private Key: %s\n", keyFile)
		fmt.Println()

		valid, err := utils.CheckSSLCertificates(certFile, keyFile)
		if err != nil {
			fmt.Printf("✗ Certificate check failed: %v\n", err)
			os.Exit(1)
		}

		if valid {
			fmt.Println("✓ SSL certificates are valid and ready to use!")
		} else {
			fmt.Println("✗ SSL certificates are missing or invalid")
			os.Exit(1)
		}
	},
}

func init() {
	RootCmd.AddCommand(SSLCmd)

	// Generate command flags
	sslGenerateCmd.Flags().String("cert", "", "Certificate file path (default: from config)")
	sslGenerateCmd.Flags().String("key", "", "Private key file path (default: from config)")
	sslGenerateCmd.Flags().String("common-name", "vigilant-monitor", "Common name (CN) for certificate")
	sslGenerateCmd.Flags().String("organization", "Vigilant Monitor", "Organization name")
	sslGenerateCmd.Flags().Int("days", 3650, "Certificate validity period in days")
	sslGenerateCmd.Flags().String("key-type", "ecdsa", "Key type: ecdsa or rsa")

	// Info command flags
	sslInfoCmd.Flags().String("cert", "", "Certificate file path (default: from config)")

	// Check command flags
	sslCheckCmd.Flags().String("cert", "", "Certificate file path (default: from config)")
	sslCheckCmd.Flags().String("key", "", "Private key file path (default: from config)")

	SSLCmd.AddCommand(sslGenerateCmd)
	SSLCmd.AddCommand(sslInfoCmd)
	SSLCmd.AddCommand(sslCheckCmd)
}
