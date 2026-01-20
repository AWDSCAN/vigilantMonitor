-- Komari Monitor MySQL Database Schema
-- This schema is generated based on SQLite models and ensures 1:1 field mapping
-- Character Set: utf8mb4, Collation: utf8mb4_unicode_ci

SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;
SET FOREIGN_KEY_CHECKS = 0;

-- ================================
-- Schema Version Table
-- ================================
CREATE TABLE IF NOT EXISTS `schema_versions` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `version` VARCHAR(50) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ================================
-- Users Table
-- ================================
CREATE TABLE IF NOT EXISTS `users` (
  `uuid` VARCHAR(36) NOT NULL,
  `username` VARCHAR(50) NOT NULL,
  `passwd` VARCHAR(255) NOT NULL COMMENT 'Hashed password',
  `sso_type` VARCHAR(20) DEFAULT NULL COMMENT 'OAuth provider type',
  `sso_id` VARCHAR(100) DEFAULT NULL COMMENT 'OAuth provider user ID',
  `two_factor` VARCHAR(255) DEFAULT NULL COMMENT '2FA secret',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`uuid`),
  UNIQUE KEY `idx_username` (`username`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ================================
-- Sessions Table
-- ================================
CREATE TABLE IF NOT EXISTS `sessions` (
  `session` VARCHAR(255) NOT NULL,
  `uuid` VARCHAR(36) NOT NULL,
  `user_agent` TEXT,
  `ip` VARCHAR(100) DEFAULT NULL,
  `login_method` VARCHAR(50) DEFAULT NULL,
  `latest_online` TIMESTAMP NULL DEFAULT NULL,
  `latest_user_agent` TEXT,
  `latest_ip` VARCHAR(100) DEFAULT NULL,
  `expires` TIMESTAMP NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`session`),
  KEY `idx_sessions_uuid` (`uuid`),
  CONSTRAINT `fk_users_sessions` FOREIGN KEY (`uuid`) REFERENCES `users` (`uuid`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ================================
-- Clients Table
-- ================================
CREATE TABLE IF NOT EXISTS `clients` (
  `uuid` VARCHAR(36) NOT NULL,
  `token` VARCHAR(255) NOT NULL,
  `name` VARCHAR(100) DEFAULT NULL,
  `cpu_name` VARCHAR(100) DEFAULT NULL,
  `virtualization` VARCHAR(50) DEFAULT NULL,
  `arch` VARCHAR(50) DEFAULT NULL,
  `cpu_cores` INT DEFAULT NULL,
  `os` VARCHAR(100) DEFAULT NULL,
  `kernel_version` VARCHAR(100) DEFAULT NULL,
  `gpu_name` VARCHAR(100) DEFAULT NULL,
  `ipv4` VARCHAR(100) DEFAULT NULL,
  `ipv6` VARCHAR(100) DEFAULT NULL,
  `region` VARCHAR(100) DEFAULT NULL,
  `remark` LONGTEXT,
  `public_remark` LONGTEXT,
  `mem_total` BIGINT DEFAULT NULL,
  `swap_total` BIGINT DEFAULT NULL,
  `disk_total` BIGINT DEFAULT NULL,
  `version` VARCHAR(100) DEFAULT NULL,
  `weight` INT DEFAULT NULL,
  `price` DOUBLE DEFAULT NULL,
  `billing_cycle` INT DEFAULT NULL,
  `auto_renewal` TINYINT(1) DEFAULT 0 COMMENT 'Auto renewal flag',
  `currency` VARCHAR(20) DEFAULT '$',
  `expired_at` TIMESTAMP NULL DEFAULT NULL,
  `group` VARCHAR(100) DEFAULT NULL,
  `tags` TEXT COMMENT 'Tags split by semicolon',
  `hidden` TINYINT(1) DEFAULT 0,
  `traffic_limit` BIGINT DEFAULT NULL,
  `traffic_limit_type` VARCHAR(10) DEFAULT 'max' COMMENT 'sum/max/min/up/down',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`uuid`),
  UNIQUE KEY `idx_token` (`token`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ================================
-- Records Table (Short-term metrics)
-- ================================
CREATE TABLE IF NOT EXISTS `records` (
  `client` VARCHAR(36) NOT NULL,
  `time` TIMESTAMP NOT NULL,
  `cpu` DECIMAL(5,2) DEFAULT NULL COMMENT 'CPU usage percentage',
  `gpu` DECIMAL(5,2) DEFAULT NULL COMMENT 'GPU usage percentage',
  `ram` BIGINT DEFAULT NULL,
  `ram_total` BIGINT DEFAULT NULL,
  `swap` BIGINT DEFAULT NULL,
  `swap_total` BIGINT DEFAULT NULL,
  `load` DECIMAL(5,2) DEFAULT NULL,
  `temp` DECIMAL(5,2) DEFAULT NULL,
  `disk` BIGINT DEFAULT NULL,
  `disk_total` BIGINT DEFAULT NULL,
  `net_in` BIGINT DEFAULT NULL,
  `net_out` BIGINT DEFAULT NULL,
  `net_total_up` BIGINT DEFAULT NULL,
  `net_total_down` BIGINT DEFAULT NULL,
  `process` INT DEFAULT NULL,
  `connections` INT DEFAULT NULL,
  `connections_udp` INT DEFAULT NULL,
  KEY `idx_records_client` (`client`),
  KEY `idx_records_time` (`time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ================================
-- Records Long Term Table
-- ================================
CREATE TABLE IF NOT EXISTS `records_long_term` (
  `client` VARCHAR(36) NOT NULL,
  `time` TIMESTAMP NOT NULL,
  `cpu` DECIMAL(5,2) DEFAULT NULL,
  `gpu` DECIMAL(5,2) DEFAULT NULL,
  `ram` BIGINT DEFAULT NULL,
  `ram_total` BIGINT DEFAULT NULL,
  `swap` BIGINT DEFAULT NULL,
  `swap_total` BIGINT DEFAULT NULL,
  `load` DECIMAL(5,2) DEFAULT NULL,
  `temp` DECIMAL(5,2) DEFAULT NULL,
  `disk` BIGINT DEFAULT NULL,
  `disk_total` BIGINT DEFAULT NULL,
  `net_in` BIGINT DEFAULT NULL,
  `net_out` BIGINT DEFAULT NULL,
  `net_total_up` BIGINT DEFAULT NULL,
  `net_total_down` BIGINT DEFAULT NULL,
  `process` INT DEFAULT NULL,
  `connections` INT DEFAULT NULL,
  `connections_udp` INT DEFAULT NULL,
  KEY `idx_records_long_term_client` (`client`),
  KEY `idx_records_long_term_time` (`time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ================================
-- GPU Records Table
-- ================================
CREATE TABLE IF NOT EXISTS `gpu_records` (
  `client` VARCHAR(36) NOT NULL,
  `time` TIMESTAMP NOT NULL,
  `device_index` INT NOT NULL COMMENT 'GPU device index (0,1,2...)',
  `device_name` VARCHAR(100) DEFAULT NULL COMMENT 'GPU model name',
  `mem_total` BIGINT DEFAULT NULL COMMENT 'Total GPU memory in bytes',
  `mem_used` BIGINT DEFAULT NULL COMMENT 'Used GPU memory in bytes',
  `utilization` DECIMAL(5,2) DEFAULT NULL COMMENT 'GPU utilization percentage',
  `temperature` INT DEFAULT NULL COMMENT 'GPU temperature in Celsius',
  KEY `idx_gpu_records_client` (`client`),
  KEY `idx_gpu_records_time` (`time`),
  KEY `idx_gpu_records_device_index` (`device_index`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ================================
-- GPU Records Long Term Table
-- ================================
CREATE TABLE IF NOT EXISTS `gpu_records_long_term` (
  `client` VARCHAR(36) NOT NULL,
  `time` TIMESTAMP NOT NULL,
  `device_index` INT NOT NULL,
  `device_name` VARCHAR(100) DEFAULT NULL,
  `mem_total` BIGINT DEFAULT NULL,
  `mem_used` BIGINT DEFAULT NULL,
  `utilization` DECIMAL(5,2) DEFAULT NULL,
  `temperature` INT DEFAULT NULL,
  KEY `idx_gpu_records_long_term_client` (`client`),
  KEY `idx_gpu_records_long_term_time` (`time`),
  KEY `idx_gpu_records_long_term_device_index` (`device_index`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ================================
-- Logs Table
-- ================================
CREATE TABLE IF NOT EXISTS `logs` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `ip` VARCHAR(45) DEFAULT NULL COMMENT 'IPv4 or IPv6 address',
  `uuid` VARCHAR(36) DEFAULT NULL,
  `message` TEXT NOT NULL,
  `msg_type` VARCHAR(20) NOT NULL,
  `time` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ================================
-- Clipboards Table
-- ================================
CREATE TABLE IF NOT EXISTS `clipboards` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `text` LONGTEXT,
  `name` VARCHAR(255) DEFAULT NULL,
  `weight` INT DEFAULT NULL,
  `remark` TEXT,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ================================
-- Offline Notifications Table
-- ================================
CREATE TABLE IF NOT EXISTS `offline_notifications` (
  `client` VARCHAR(36) NOT NULL,
  `enable` TINYINT(1) DEFAULT 0,
  `grace_period` INT NOT NULL DEFAULT 180 COMMENT 'Grace period in seconds (default 3 minutes)',
  `last_notified` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`client`),
  UNIQUE KEY `idx_offline_notifications_client` (`client`),
  CONSTRAINT `fk_offline_notifications_client` FOREIGN KEY (`client`) REFERENCES `clients` (`uuid`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ================================
-- Load Notifications Table
-- ================================
CREATE TABLE IF NOT EXISTS `load_notifications` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(255) DEFAULT NULL,
  `clients` LONGTEXT COMMENT 'JSON array of client UUIDs',
  `metric` VARCHAR(50) NOT NULL DEFAULT 'cpu' COMMENT 'Monitored metric: cpu/ram/load',
  `threshold` DECIMAL(5,2) NOT NULL DEFAULT 80.00 COMMENT 'Threshold percentage',
  `ratio` DECIMAL(5,2) NOT NULL DEFAULT 0.80 COMMENT 'Time ratio for threshold breach',
  `interval` INT NOT NULL DEFAULT 15 COMMENT 'Monitoring interval in minutes',
  `last_notified` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ================================
-- Ping Tasks Table
-- ================================
CREATE TABLE IF NOT EXISTS `ping_tasks` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(255) NOT NULL,
  `clients` LONGTEXT COMMENT 'JSON array of client UUIDs',
  `type` VARCHAR(12) NOT NULL DEFAULT 'icmp' COMMENT 'Ping type: icmp/tcp/http',
  `target` VARCHAR(255) NOT NULL,
  `interval` INT NOT NULL DEFAULT 60 COMMENT 'Interval in seconds',
  PRIMARY KEY (`id`),
  KEY `idx_ping_tasks_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ================================
-- Ping Records Table
-- ================================
CREATE TABLE IF NOT EXISTS `ping_records` (
  `client` VARCHAR(36) NOT NULL,
  `task_id` INT UNSIGNED NOT NULL,
  `time` TIMESTAMP NOT NULL,
  `value` INT NOT NULL COMMENT 'Ping value in milliseconds',
  KEY `idx_ping_records_client` (`client`),
  KEY `idx_ping_records_task_id` (`task_id`),
  KEY `idx_ping_records_time` (`time`),
  CONSTRAINT `fk_ping_records_client` FOREIGN KEY (`client`) REFERENCES `clients` (`uuid`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_ping_records_task` FOREIGN KEY (`task_id`) REFERENCES `ping_tasks` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ================================
-- OIDC Providers Table
-- ================================
CREATE TABLE IF NOT EXISTS `oidc_providers` (
  `name` VARCHAR(100) NOT NULL,
  `addition` LONGTEXT,
  PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ================================
-- Message Sender Providers Table
-- ================================
CREATE TABLE IF NOT EXISTS `message_sender_providers` (
  `name` VARCHAR(100) NOT NULL,
  `addition` LONGTEXT,
  PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ================================
-- Theme Configurations Table
-- ================================
CREATE TABLE IF NOT EXISTS `theme_configurations` (
  `short` VARCHAR(100) NOT NULL,
  `data` LONGTEXT,
  PRIMARY KEY (`short`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ================================
-- Tasks Table
-- ================================
CREATE TABLE IF NOT EXISTS `tasks` (
  `task_id` VARCHAR(36) NOT NULL,
  `clients` LONGTEXT COMMENT 'JSON array of client UUIDs',
  `command` TEXT,
  PRIMARY KEY (`task_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ================================
-- Task Results Table
-- ================================
CREATE TABLE IF NOT EXISTS `task_results` (
  `task_id` VARCHAR(36) NOT NULL,
  `client` VARCHAR(36) NOT NULL,
  `result` LONGTEXT,
  `exit_code` INT DEFAULT NULL,
  `finished_at` TIMESTAMP NULL DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY `idx_task_results_task_id` (`task_id`),
  CONSTRAINT `fk_task_results_task` FOREIGN KEY (`task_id`) REFERENCES `tasks` (`task_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_task_results_client` FOREIGN KEY (`client`) REFERENCES `clients` (`uuid`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;

-- ================================
-- End of Schema
-- ================================
