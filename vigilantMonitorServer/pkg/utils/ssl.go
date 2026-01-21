package utils

import (
	"crypto/ecdsa"
	"crypto/elliptic"
	"crypto/rand"
	"crypto/rsa"
	"crypto/x509"
	"crypto/x509/pkix"
	"encoding/pem"
	"fmt"
	"math/big"
	"net"
	"os"
	"path/filepath"
	"strings"
	"time"
)

// SSLCertConfig SSL证书配置
type SSLCertConfig struct {
	Organization string   // 组织名称
	Country      string   // 国家代码
	Province     string   // 省份
	Locality     string   // 城市
	CommonName   string   // 通用名称（域名）
	DNSNames     []string // DNS名称列表
	IPAddresses  []net.IP // IP地址列表
	ValidDays    int      // 证书有效期（天）
	KeyType      string   // 密钥类型：rsa 或 ecdsa
	KeySize      int      // RSA密钥大小：2048, 4096（仅用于RSA）
}

// DefaultSSLCertConfig 返回默认SSL证书配置
func DefaultSSLCertConfig() SSLCertConfig {
	return SSLCertConfig{
		Organization: "Komari Monitor",
		Country:      "US",
		Province:     "State",
		Locality:     "City",
		CommonName:   "localhost",
		DNSNames:     []string{"localhost", "*.localhost"},
		IPAddresses:  []net.IP{net.ParseIP("127.0.0.1"), net.ParseIP("::1")},
		ValidDays:    3650, // 10年
		KeyType:      "ecdsa",
		KeySize:      2048,
	}
}

// GenerateSelfSignedCert 生成自签名SSL证书
func GenerateSelfSignedCert(config SSLCertConfig, certPath, keyPath string) error {
	// 创建目录
	certDir := filepath.Dir(certPath)
	keyDir := filepath.Dir(keyPath)

	if err := os.MkdirAll(certDir, 0755); err != nil {
		return fmt.Errorf("failed to create cert directory: %w", err)
	}
	if err := os.MkdirAll(keyDir, 0755); err != nil {
		return fmt.Errorf("failed to create key directory: %w", err)
	}

	// 生成密钥对
	var privateKey interface{}
	var err error

	if strings.ToLower(config.KeyType) == "ecdsa" {
		// 使用ECDSA P-256曲线（推荐，更快且安全）
		privateKey, err = ecdsa.GenerateKey(elliptic.P256(), rand.Reader)
		if err != nil {
			return fmt.Errorf("failed to generate ECDSA key: %w", err)
		}
	} else {
		// 使用RSA
		keySize := config.KeySize
		if keySize < 2048 {
			keySize = 2048 // 最小2048位
		}
		privateKey, err = rsa.GenerateKey(rand.Reader, keySize)
		if err != nil {
			return fmt.Errorf("failed to generate RSA key: %w", err)
		}
	}

	// 生成序列号
	serialNumberLimit := new(big.Int).Lsh(big.NewInt(1), 128)
	serialNumber, err := rand.Int(rand.Reader, serialNumberLimit)
	if err != nil {
		return fmt.Errorf("failed to generate serial number: %w", err)
	}

	// 设置证书模板
	notBefore := time.Now()
	notAfter := notBefore.Add(time.Duration(config.ValidDays) * 24 * time.Hour)

	template := x509.Certificate{
		SerialNumber: serialNumber,
		Subject: pkix.Name{
			Organization: []string{config.Organization},
			Country:      []string{config.Country},
			Province:     []string{config.Province},
			Locality:     []string{config.Locality},
			CommonName:   config.CommonName,
		},
		NotBefore:             notBefore,
		NotAfter:              notAfter,
		KeyUsage:              x509.KeyUsageKeyEncipherment | x509.KeyUsageDigitalSignature,
		ExtKeyUsage:           []x509.ExtKeyUsage{x509.ExtKeyUsageServerAuth},
		BasicConstraintsValid: true,
		DNSNames:              config.DNSNames,
		IPAddresses:           config.IPAddresses,
	}

	// 创建证书
	var publicKey interface{}
	switch k := privateKey.(type) {
	case *ecdsa.PrivateKey:
		publicKey = &k.PublicKey
	case *rsa.PrivateKey:
		publicKey = &k.PublicKey
	default:
		return fmt.Errorf("unsupported key type")
	}

	derBytes, err := x509.CreateCertificate(rand.Reader, &template, &template, publicKey, privateKey)
	if err != nil {
		return fmt.Errorf("failed to create certificate: %w", err)
	}

	// 保存证书
	certOut, err := os.Create(certPath)
	if err != nil {
		return fmt.Errorf("failed to open cert file for writing: %w", err)
	}
	defer certOut.Close()

	if err := pem.Encode(certOut, &pem.Block{Type: "CERTIFICATE", Bytes: derBytes}); err != nil {
		return fmt.Errorf("failed to write certificate to file: %w", err)
	}

	// 保存私钥
	keyOut, err := os.OpenFile(keyPath, os.O_WRONLY|os.O_CREATE|os.O_TRUNC, 0600)
	if err != nil {
		return fmt.Errorf("failed to open key file for writing: %w", err)
	}
	defer keyOut.Close()

	var privBytes []byte
	var blockType string

	switch k := privateKey.(type) {
	case *ecdsa.PrivateKey:
		privBytes, err = x509.MarshalECPrivateKey(k)
		if err != nil {
			return fmt.Errorf("failed to marshal ECDSA private key: %w", err)
		}
		blockType = "EC PRIVATE KEY"
	case *rsa.PrivateKey:
		privBytes = x509.MarshalPKCS1PrivateKey(k)
		blockType = "RSA PRIVATE KEY"
	}

	if err := pem.Encode(keyOut, &pem.Block{Type: blockType, Bytes: privBytes}); err != nil {
		return fmt.Errorf("failed to write private key to file: %w", err)
	}

	return nil
}

// CheckSSLCertificates 检查SSL证书是否存在且有效
func CheckSSLCertificates(certPath, keyPath string) (bool, error) {
	// 检查文件是否存在
	if _, err := os.Stat(certPath); os.IsNotExist(err) {
		return false, nil
	}
	if _, err := os.Stat(keyPath); os.IsNotExist(err) {
		return false, nil
	}

	// 读取证书文件
	certPEM, err := os.ReadFile(certPath)
	if err != nil {
		return false, fmt.Errorf("failed to read certificate: %w", err)
	}

	block, _ := pem.Decode(certPEM)
	if block == nil {
		return false, fmt.Errorf("failed to decode certificate PEM")
	}

	cert, err := x509.ParseCertificate(block.Bytes)
	if err != nil {
		return false, fmt.Errorf("failed to parse certificate: %w", err)
	}

	// 检查证书是否过期
	now := time.Now()
	if now.Before(cert.NotBefore) || now.After(cert.NotAfter) {
		return false, fmt.Errorf("certificate expired or not yet valid")
	}

	return true, nil
}

// GetSSLCertInfo 获取SSL证书信息
func GetSSLCertInfo(certPath string) (map[string]interface{}, error) {
	certPEM, err := os.ReadFile(certPath)
	if err != nil {
		return nil, fmt.Errorf("failed to read certificate: %w", err)
	}

	block, _ := pem.Decode(certPEM)
	if block == nil {
		return nil, fmt.Errorf("failed to decode certificate PEM")
	}

	cert, err := x509.ParseCertificate(block.Bytes)
	if err != nil {
		return nil, fmt.Errorf("failed to parse certificate: %w", err)
	}

	info := map[string]interface{}{
		"subject":       cert.Subject.CommonName,
		"issuer":        cert.Issuer.CommonName,
		"serial_number": cert.SerialNumber.String(),
		"not_before":    cert.NotBefore.Format(time.RFC3339),
		"not_after":     cert.NotAfter.Format(time.RFC3339),
		"dns_names":     cert.DNSNames,
		"ip_addresses":  cert.IPAddresses,
		"is_ca":         cert.IsCA,
	}

	return info, nil
}
