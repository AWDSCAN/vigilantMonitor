/*
 Navicat Premium Dump SQL

 Source Server         : localhost
 Source Server Type    : MySQL
 Source Server Version : 80012 (8.0.12)
 Source Host           : localhost:3306
 Source Schema         : komari_db

 Target Server Type    : MySQL
 Target Server Version : 80012 (8.0.12)
 File Encoding         : 65001

 Date: 21/01/2026 13:59:32
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for clients
-- ----------------------------
DROP TABLE IF EXISTS `clients`;
CREATE TABLE `clients`  (
  `uuid` varchar(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `token` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL,
  `cpu_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL,
  `virtualization` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL,
  `arch` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL,
  `cpu_cores` bigint(20) NULL DEFAULT NULL,
  `os` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL,
  `kernel_version` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL,
  `gpu_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL,
  `ipv4` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL,
  `ipv6` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL,
  `region` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL,
  `remark` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL,
  `public_remark` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL,
  `mem_total` bigint(20) NULL DEFAULT NULL,
  `swap_total` bigint(20) NULL DEFAULT NULL,
  `disk_total` bigint(20) NULL DEFAULT NULL,
  `version` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL,
  `weight` bigint(20) NULL DEFAULT NULL,
  `price` double NULL DEFAULT NULL,
  `billing_cycle` bigint(20) NULL DEFAULT NULL,
  `auto_renewal` tinyint(1) NULL DEFAULT 0,
  `currency` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '$',
  `expired_at` timestamp NULL DEFAULT NULL,
  `group` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL,
  `tags` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL,
  `hidden` tinyint(1) NULL DEFAULT 0,
  `traffic_limit` bigint(20) NULL DEFAULT NULL,
  `traffic_limit_type` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT 'max',
  `created_at` datetime(3) NULL DEFAULT NULL,
  `updated_at` datetime(3) NULL DEFAULT NULL,
  PRIMARY KEY (`uuid`) USING BTREE,
  UNIQUE INDEX `uni_clients_token`(`token` ASC) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of clients
-- ----------------------------
INSERT INTO `clients` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', '5J23G4aeO59hiCVDC2HWSR', 'Windows测试节点', 'AMD Ryzen 7 5800H with Radeon Graphics', 'none', 'amd64', 16, 'Windows 11 Pro', '26200.7171', 'NVIDIA GeForce RTX 3050 Laptop GPU', '220.197.12.236', '2408:896c:100:93ba:3922:92eb:21a7:9e59', '🇨🇳', '', '', 34204618752, 38654705664, 2021052313600, '0.0.1', 0, 0, 0, 0, '$', NULL, '', '', 0, 0, 'max', '2026-01-21 00:44:56.509', '2026-01-21 13:14:41.746');

-- ----------------------------
-- Table structure for clipboards
-- ----------------------------
DROP TABLE IF EXISTS `clipboards`;
CREATE TABLE `clipboards`  (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `text` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL,
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL,
  `weight` bigint(20) NULL DEFAULT NULL,
  `remark` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL,
  `created_at` datetime(3) NULL DEFAULT NULL,
  `updated_at` datetime(3) NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of clipboards
-- ----------------------------

-- ----------------------------
-- Table structure for command_results
-- ----------------------------
DROP TABLE IF EXISTS `command_results`;
CREATE TABLE `command_results`  (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `task_id` varchar(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `client_uuid` varchar(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `executed` tinyint(1) NULL DEFAULT 0 COMMENT 'whether the command was executed',
  `output` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL COMMENT 'command output',
  `exit_code` int(11) NULL DEFAULT NULL,
  `error_message` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL COMMENT 'error message if execution failed',
  `executed_at` datetime(3) NULL DEFAULT NULL COMMENT 'when the command was executed',
  `created_at` datetime(3) NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_task_id`(`task_id` ASC) USING BTREE,
  INDEX `idx_client_uuid`(`client_uuid` ASC) USING BTREE,
  INDEX `idx_executed_at`(`executed_at` ASC) USING BTREE,
  CONSTRAINT `fk_command_results_task` FOREIGN KEY (`task_id`) REFERENCES `command_tasks` (`task_id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 2 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'Command execution results table' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of command_results
-- ----------------------------
INSERT INTO `command_results` VALUES (1, 'Wy64EFaRaPHLERDo', '348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, 'nt authority\\system\n', 0, '', '2026-01-21 03:49:54.357', '2026-01-21 03:49:54.026');

-- ----------------------------
-- Table structure for command_tasks
-- ----------------------------
DROP TABLE IF EXISTS `command_tasks`;
CREATE TABLE `command_tasks`  (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `task_id` varchar(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `command` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `target_os` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT 'windows, linux, or null for all',
  `target_clients` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL COMMENT 'JSON array of client UUIDs, null for all clients',
  `status` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT 'pending' COMMENT 'pending, running, completed, failed',
  `created_by` varchar(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT 'user ID',
  `total_clients` int(11) NULL DEFAULT 0 COMMENT 'total number of target clients',
  `success_count` int(11) NULL DEFAULT 0 COMMENT 'number of successful executions',
  `failed_count` int(11) NULL DEFAULT 0 COMMENT 'number of failed executions',
  `created_at` datetime(3) NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `idx_task_id`(`task_id` ASC) USING BTREE,
  INDEX `idx_status`(`status` ASC) USING BTREE,
  INDEX `idx_created_at`(`created_at` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 2 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'Command task management table' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of command_tasks
-- ----------------------------
INSERT INTO `command_tasks` VALUES (1, 'Wy64EFaRaPHLERDo', 'whoami', '', '[\"348d778c-2561-4a62-a3b1-e5cf5c2cb6c5\"]', 'completed', '85eb7fe5-c1a5-4a2f-a722-7d6539a58a79', 1, 1, 0, '2026-01-21 03:49:54.013', '2026-01-21 11:49:54.369');

-- ----------------------------
-- Table structure for gpu_records
-- ----------------------------
DROP TABLE IF EXISTS `gpu_records`;
CREATE TABLE `gpu_records`  (
  `client` varchar(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL,
  `time` datetime(3) NULL DEFAULT NULL,
  `device_index` bigint(20) NULL DEFAULT NULL,
  `device_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL,
  `mem_total` bigint(20) NULL DEFAULT NULL,
  `mem_used` bigint(20) NULL DEFAULT NULL,
  `utilization` decimal(5, 2) NULL DEFAULT NULL,
  `temperature` bigint(20) NULL DEFAULT NULL,
  INDEX `idx_gpu_records_client`(`client` ASC) USING BTREE,
  INDEX `idx_gpu_records_time`(`time` ASC) USING BTREE,
  INDEX `idx_gpu_records_device_index`(`device_index` ASC) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of gpu_records
-- ----------------------------

-- ----------------------------
-- Table structure for gpu_records_long_term
-- ----------------------------
DROP TABLE IF EXISTS `gpu_records_long_term`;
CREATE TABLE `gpu_records_long_term`  (
  `client` varchar(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `time` timestamp NOT NULL,
  `device_index` int(11) NOT NULL,
  `device_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL,
  `mem_total` bigint(20) NULL DEFAULT NULL,
  `mem_used` bigint(20) NULL DEFAULT NULL,
  `utilization` decimal(5, 2) NULL DEFAULT NULL,
  `temperature` int(11) NULL DEFAULT NULL,
  INDEX `idx_gpu_records_long_term_client`(`client` ASC) USING BTREE,
  INDEX `idx_gpu_records_long_term_time`(`time` ASC) USING BTREE,
  INDEX `idx_gpu_records_long_term_device_index`(`device_index` ASC) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of gpu_records_long_term
-- ----------------------------

-- ----------------------------
-- Table structure for load_notifications
-- ----------------------------
DROP TABLE IF EXISTS `load_notifications`;
CREATE TABLE `load_notifications`  (
  `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL,
  `clients` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL,
  `metric` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'cpu',
  `threshold` decimal(5, 2) NOT NULL DEFAULT 80.00,
  `ratio` decimal(5, 2) NOT NULL DEFAULT 0.80,
  `interval` bigint(20) NOT NULL DEFAULT 15,
  `last_notified` datetime(3) NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of load_notifications
-- ----------------------------

-- ----------------------------
-- Table structure for logs
-- ----------------------------
DROP TABLE IF EXISTS `logs`;
CREATE TABLE `logs`  (
  `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `ip` varchar(45) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL,
  `uuid` varchar(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL,
  `message` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `msg_type` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `time` datetime(3) NOT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 27 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of logs
-- ----------------------------
INSERT INTO `logs` VALUES (1, '', '', 'Failed to send event message after 3 attempts: you are using an empty message sender, please check your configuration,Login', 'error', '2026-01-20 15:35:42.451');
INSERT INTO `logs` VALUES (2, '127.0.0.1', '85eb7fe5-c1a5-4a2f-a722-7d6539a58a79', 'logged in (password)', 'login', '2026-01-20 15:35:42.516');
INSERT INTO `logs` VALUES (3, '127.0.0.1', '85eb7fe5-c1a5-4a2f-a722-7d6539a58a79', 'update settings: eula_accepted', 'info', '2026-01-20 15:35:50.199');
INSERT INTO `logs` VALUES (4, '127.0.0.1', '85eb7fe5-c1a5-4a2f-a722-7d6539a58a79', 'update settings: sitename', 'info', '2026-01-20 15:48:53.983');
INSERT INTO `logs` VALUES (5, '127.0.0.1', '85eb7fe5-c1a5-4a2f-a722-7d6539a58a79', 'update settings: description', 'info', '2026-01-20 15:48:55.005');
INSERT INTO `logs` VALUES (6, '127.0.0.1', '', 'logged out', 'logout', '2026-01-20 15:53:36.392');
INSERT INTO `logs` VALUES (7, '', '', 'Failed to send event message after 3 attempts: you are using an empty message sender, please check your configuration,Login', 'error', '2026-01-20 16:04:27.367');
INSERT INTO `logs` VALUES (8, '127.0.0.1', '85eb7fe5-c1a5-4a2f-a722-7d6539a58a79', 'logged in (password)', 'login', '2026-01-20 16:04:27.435');
INSERT INTO `logs` VALUES (9, '127.0.0.1', '85eb7fe5-c1a5-4a2f-a722-7d6539a58a79', 'update settings: private_site', 'info', '2026-01-20 16:04:48.179');
INSERT INTO `logs` VALUES (10, '127.0.0.1', '85eb7fe5-c1a5-4a2f-a722-7d6539a58a79', 'update settings: script_domain', 'info', '2026-01-20 16:04:52.554');
INSERT INTO `logs` VALUES (11, '127.0.0.1', '85eb7fe5-c1a5-4a2f-a722-7d6539a58a79', 'create client:348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 'info', '2026-01-21 00:44:56.522');
INSERT INTO `logs` VALUES (12, '', '', 'server is shutting down', 'info', '2026-01-21 01:04:42.051');
INSERT INTO `logs` VALUES (13, '', '', 'server is shutting down', 'info', '2026-01-21 01:15:41.142');
INSERT INTO `logs` VALUES (14, '127.0.0.1', '85eb7fe5-c1a5-4a2f-a722-7d6539a58a79', 'established, terminal id:ME0jSKfJOSw65ilzvsshXRHdaSZ1tbs3', 'terminal', '2026-01-21 03:45:00.004');
INSERT INTO `logs` VALUES (15, '127.0.0.1', '85eb7fe5-c1a5-4a2f-a722-7d6539a58a79', 'disconnected, terminal id:ME0jSKfJOSw65ilzvsshXRHdaSZ1tbs3, duration:5.5962986s', 'terminal', '2026-01-21 03:45:05.605');
INSERT INTO `logs` VALUES (16, '127.0.0.1', '85eb7fe5-c1a5-4a2f-a722-7d6539a58a79', 'established, terminal id:1vVgSnMRiJCyyGzLcpxom4x38q1AsTpl', 'terminal', '2026-01-21 03:47:49.974');
INSERT INTO `logs` VALUES (17, '127.0.0.1', '85eb7fe5-c1a5-4a2f-a722-7d6539a58a79', 'disconnected, terminal id:1vVgSnMRiJCyyGzLcpxom4x38q1AsTpl, duration:9.2511098s', 'terminal', '2026-01-21 03:47:59.235');
INSERT INTO `logs` VALUES (18, '127.0.0.1', '85eb7fe5-c1a5-4a2f-a722-7d6539a58a79', 'Command task created: Wy64EFaRaPHLERDo', 'info', '2026-01-21 03:49:54.042');
INSERT INTO `logs` VALUES (19, '', '', 'server encountered a fatal error: listen tcp 0.0.0.0:25774: bind: Only one usage of each socket address (protocol/network address/port) is normally permitted.', 'error', '2026-01-21 05:14:26.867');
INSERT INTO `logs` VALUES (20, '', '', 'server is shutting down', 'info', '2026-01-21 05:14:45.877');
INSERT INTO `logs` VALUES (21, '', '', 'server is shutting down', 'info', '2026-01-21 05:29:01.135');
INSERT INTO `logs` VALUES (22, '', '', 'server is shutting down', 'info', '2026-01-21 05:35:20.749');
INSERT INTO `logs` VALUES (23, '', '', 'Failed to send event message after 3 attempts: you are using an empty message sender, please check your configuration,Login', 'error', '2026-01-21 05:38:18.558');
INSERT INTO `logs` VALUES (24, '127.0.0.1', '85eb7fe5-c1a5-4a2f-a722-7d6539a58a79', 'logged in (password)', 'login', '2026-01-21 05:38:18.584');
INSERT INTO `logs` VALUES (25, '', '', 'server is shutting down', 'info', '2026-01-21 05:47:47.222');
INSERT INTO `logs` VALUES (26, '', '', 'server is shutting down', 'info', '2026-01-21 05:51:32.530');

-- ----------------------------
-- Table structure for message_sender_providers
-- ----------------------------
DROP TABLE IF EXISTS `message_sender_providers`;
CREATE TABLE `message_sender_providers`  (
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `addition` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL,
  PRIMARY KEY (`name`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of message_sender_providers
-- ----------------------------
INSERT INTO `message_sender_providers` VALUES ('bark', '{\"server_url\":\"\",\"device_key\":\"\",\"icon\":\"\",\"level\":\"\"}');
INSERT INTO `message_sender_providers` VALUES ('email', '{\"host\":\"\",\"port\":0,\"username\":\"\",\"password\":\"\",\"sender\":\"\",\"receiver\":\"\",\"use_ssl\":false,\"use_login_auth\":false}');
INSERT INTO `message_sender_providers` VALUES ('empty', '{}');
INSERT INTO `message_sender_providers` VALUES ('Javascript', '{\"script\":\"\"}');
INSERT INTO `message_sender_providers` VALUES ('Server酱³', '{\"api_url\":\"\",\"tags\":\"\"}');
INSERT INTO `message_sender_providers` VALUES ('Server酱Turbo', '{\"api_url\":\"\",\"channel\":\"\",\"noip\":\"\",\"openid\":\"\"}');
INSERT INTO `message_sender_providers` VALUES ('telegram', '{\"bot_token\":\"\",\"chat_id\":\"\",\"message_thread_id\":\"\",\"endpoint\":\"\"}');
INSERT INTO `message_sender_providers` VALUES ('webhook', '{\"url\":\"\",\"method\":\"\",\"content_type\":\"\",\"headers\":\"\",\"body\":\"\",\"username\":\"\",\"password\":\"\"}');

-- ----------------------------
-- Table structure for offline_notifications
-- ----------------------------
DROP TABLE IF EXISTS `offline_notifications`;
CREATE TABLE `offline_notifications`  (
  `client` varchar(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `enable` tinyint(1) NULL DEFAULT 0,
  `grace_period` bigint(20) NOT NULL DEFAULT 180,
  `last_notified` datetime(3) NULL DEFAULT NULL,
  PRIMARY KEY (`client`) USING BTREE,
  UNIQUE INDEX `idx_offline_notifications_client`(`client` ASC) USING BTREE,
  UNIQUE INDEX `uni_offline_notifications_client`(`client` ASC) USING BTREE,
  CONSTRAINT `fk_offline_notifications_client` FOREIGN KEY (`client`) REFERENCES `clients` (`uuid`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of offline_notifications
-- ----------------------------
INSERT INTO `offline_notifications` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 0, 180, NULL);

-- ----------------------------
-- Table structure for oidc_providers
-- ----------------------------
DROP TABLE IF EXISTS `oidc_providers`;
CREATE TABLE `oidc_providers`  (
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `addition` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL,
  PRIMARY KEY (`name`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of oidc_providers
-- ----------------------------
INSERT INTO `oidc_providers` VALUES ('CloudflareAccess', '{\"team_domain\":\"\",\"policy_aud\":\"\"}');
INSERT INTO `oidc_providers` VALUES ('generic', '{\"client_id\":\"\",\"client_secret\":\"\",\"auth_url\":\"\",\"token_url\":\"\",\"user_info_url\":\"\",\"scope\":\"\",\"user_id_field\":\"\"}');
INSERT INTO `oidc_providers` VALUES ('github', '{\"client_id\":\"\",\"client_secret\":\"\"}');
INSERT INTO `oidc_providers` VALUES ('qq', '{\"aggregation_url\":\"\",\"app_id\":\"\",\"app_key\":\"\",\"login_type\":\"\"}');

-- ----------------------------
-- Table structure for ping_records
-- ----------------------------
DROP TABLE IF EXISTS `ping_records`;
CREATE TABLE `ping_records`  (
  `client` varchar(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `task_id` int(10) UNSIGNED NOT NULL,
  `time` timestamp NOT NULL,
  `value` int(11) NOT NULL COMMENT 'Ping value in milliseconds',
  INDEX `idx_ping_records_client`(`client` ASC) USING BTREE,
  INDEX `idx_ping_records_task_id`(`task_id` ASC) USING BTREE,
  INDEX `idx_ping_records_time`(`time` ASC) USING BTREE,
  CONSTRAINT `fk_ping_records_client` FOREIGN KEY (`client`) REFERENCES `clients` (`uuid`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of ping_records
-- ----------------------------
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 03:46:54', 26);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 03:47:54', 29);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 03:48:54', 28);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 03:49:54', 34);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 03:50:54', 31);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 03:51:54', 26);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 03:52:54', 32);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 03:53:54', 31);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 03:54:54', 36);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 03:55:54', 31);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 03:56:54', 32);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 03:57:54', 29);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 03:58:54', 32);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 03:59:54', 29);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 04:00:54', 33);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 04:01:54', 35);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 04:02:54', 38);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 04:03:54', 31);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 04:04:54', 32);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 04:05:54', 31);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 04:06:54', 32);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 04:07:54', 38);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 04:08:54', 36);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 04:09:54', 36);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 04:10:54', 29);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 04:11:54', 30);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 04:12:54', 31);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 04:13:54', 28);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 04:14:54', 30);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 04:15:54', 29);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 04:16:54', 28);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 04:17:54', 33);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 04:18:54', 29);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 04:19:54', 27);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 04:20:54', 28);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 04:21:54', 27);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 04:22:54', 26);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 04:23:54', 26);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 04:24:54', 26);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 04:25:54', 26);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 04:26:54', 37);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 04:27:54', 30);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 04:28:54', 41);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 04:29:54', 35);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 04:30:54', 35);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 04:31:54', 40);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 04:32:54', 34);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 04:33:54', 39);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 04:34:54', 37);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 04:35:54', 38);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 04:36:54', 43);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 04:37:54', 36);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 04:38:54', 42);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 04:39:54', 42);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 04:40:54', 32);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 04:41:54', 33);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 04:42:54', 32);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 04:43:54', 34);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 04:44:54', 35);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 04:45:54', 35);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 04:46:54', 35);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 04:47:54', 32);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 04:48:54', 30);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 04:49:54', 34);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 04:50:54', 31);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 04:51:54', 39);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 04:52:54', 32);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 04:53:54', 28);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 04:54:54', 33);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 04:55:54', 27);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 04:56:54', 27);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 04:57:54', 32);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 04:58:54', 35);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 04:59:54', 28);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 05:00:54', 26);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 05:01:54', 26);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 05:02:54', 26);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 05:03:54', 29);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 05:04:54', 34);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 05:05:54', 29);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 05:06:54', 29);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 05:07:54', 34);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 05:08:54', 33);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 05:09:54', 24);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 05:10:54', 38);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 05:11:54', 34);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 05:12:54', 37);
INSERT INTO `ping_records` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', 1, '2026-01-21 05:13:54', 32);

-- ----------------------------
-- Table structure for ping_tasks
-- ----------------------------
DROP TABLE IF EXISTS `ping_tasks`;
CREATE TABLE `ping_tasks`  (
  `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `clients` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL,
  `type` varchar(12) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'icmp',
  `target` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `interval` bigint(20) NOT NULL DEFAULT 60,
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_ping_tasks_name`(`name` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 2 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of ping_tasks
-- ----------------------------
INSERT INTO `ping_tasks` VALUES (1, '延迟测试', '[\"348d778c-2561-4a62-a3b1-e5cf5c2cb6c5\"]', 'icmp', '223.5.5.5', 60);

-- ----------------------------
-- Table structure for records
-- ----------------------------
DROP TABLE IF EXISTS `records`;
CREATE TABLE `records`  (
  `client` varchar(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL,
  `time` datetime(3) NULL DEFAULT NULL,
  `cpu` decimal(5, 2) NULL DEFAULT NULL,
  `gpu` decimal(5, 2) NULL DEFAULT NULL,
  `ram` bigint(20) NULL DEFAULT NULL,
  `ram_total` bigint(20) NULL DEFAULT NULL,
  `swap` bigint(20) NULL DEFAULT NULL,
  `swap_total` bigint(20) NULL DEFAULT NULL,
  `load` decimal(5, 2) NULL DEFAULT NULL,
  `temp` decimal(5, 2) NULL DEFAULT NULL,
  `disk` bigint(20) NULL DEFAULT NULL,
  `disk_total` bigint(20) NULL DEFAULT NULL,
  `net_in` bigint(20) NULL DEFAULT NULL,
  `net_out` bigint(20) NULL DEFAULT NULL,
  `net_total_up` bigint(20) NULL DEFAULT NULL,
  `net_total_down` bigint(20) NULL DEFAULT NULL,
  `process` bigint(20) NULL DEFAULT NULL,
  `connections` bigint(20) NULL DEFAULT NULL,
  `connections_udp` bigint(20) NULL DEFAULT NULL,
  INDEX `idx_records_client`(`client` ASC) USING BTREE,
  INDEX `idx_records_time`(`time` ASC) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of records
-- ----------------------------

-- ----------------------------
-- Table structure for records_long_term
-- ----------------------------
DROP TABLE IF EXISTS `records_long_term`;
CREATE TABLE `records_long_term`  (
  `client` varchar(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `time` timestamp NOT NULL,
  `cpu` decimal(5, 2) NULL DEFAULT NULL,
  `gpu` decimal(5, 2) NULL DEFAULT NULL,
  `ram` bigint(20) NULL DEFAULT NULL,
  `ram_total` bigint(20) NULL DEFAULT NULL,
  `swap` bigint(20) NULL DEFAULT NULL,
  `swap_total` bigint(20) NULL DEFAULT NULL,
  `load` decimal(5, 2) NULL DEFAULT NULL,
  `temp` decimal(5, 2) NULL DEFAULT NULL,
  `disk` bigint(20) NULL DEFAULT NULL,
  `disk_total` bigint(20) NULL DEFAULT NULL,
  `net_in` bigint(20) NULL DEFAULT NULL,
  `net_out` bigint(20) NULL DEFAULT NULL,
  `net_total_up` bigint(20) NULL DEFAULT NULL,
  `net_total_down` bigint(20) NULL DEFAULT NULL,
  `process` int(11) NULL DEFAULT NULL,
  `connections` int(11) NULL DEFAULT NULL,
  `connections_udp` int(11) NULL DEFAULT NULL,
  INDEX `idx_records_long_term_client`(`client` ASC) USING BTREE,
  INDEX `idx_records_long_term_time`(`time` ASC) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of records_long_term
-- ----------------------------
INSERT INTO `records_long_term` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', '2026-01-20 19:45:00', 32.04, 0.00, 23576746188, 34204618752, 641445888, 38654705664, 0.27, 0.00, 1512186725888, 2021052313600, 24981, 90361, 40234885423, 77017093763, 485, 369, 233);
INSERT INTO `records_long_term` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', '2026-01-20 20:00:00', 27.14, 0.00, 23368161331, 34204618752, 690819123, 38654705664, 0.08, 0.00, 1511324069324, 2021052313600, 8565, 8616, 40253859619, 77038046817, 485, 337, 233);
INSERT INTO `records_long_term` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', '2026-01-20 20:00:00', 28.61, 0.00, 23569796608, 34204618752, 652455936, 38654705664, 0.14, 0.00, 1511521231872, 2021052313600, 2837, 2602, 40254900988, 77039313739, 490, 288, 229);
INSERT INTO `records_long_term` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', '2026-01-20 20:15:00', 16.95, 0.00, 23633029734, 34204618752, 637833216, 38654705664, 0.08, 0.00, 1511525950566, 2021052313600, 1613, 2508, 40261483259, 77042296196, 481, 289, 235);
INSERT INTO `records_long_term` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', '2026-01-20 20:30:00', 15.88, 0.00, 23312147456, 34204618752, 589602816, 38654705664, 0.00, 0.00, 1511526078310, 2021052313600, 1500, 1623, 40261860964, 77042797579, 480, 256, 229);
INSERT INTO `records_long_term` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', '2026-01-20 20:30:00', 17.05, 0.00, 23446549504, 34204618752, 589602816, 38654705664, 0.30, 0.00, 1511527665152, 2021052313600, 1428, 1675, 40262443551, 77043637090, 482, 277, 228);
INSERT INTO `records_long_term` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', '2026-01-20 20:45:00', 15.95, 0.00, 23593300377, 34204618752, 643633152, 38654705664, 0.29, 0.00, 1511528075161, 2021052313600, 950, 1322, 40263503237, 77045316758, 481, 296, 228);
INSERT INTO `records_long_term` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', '2026-01-20 21:00:00', 16.00, 0.00, 23642213478, 34204618752, 643633152, 38654705664, 0.39, 0.00, 1511528279296, 2021052313600, 852, 1771, 40263882981, 77045885364, 482, 265, 228);
INSERT INTO `records_long_term` VALUES ('348d778c-2561-4a62-a3b1-e5cf5c2cb6c5', '2026-01-20 21:00:00', 15.64, 0.00, 23537500160, 34204618752, 643579904, 38654705664, 0.18, 0.00, 1511528699392, 2021052313600, 1446, 1720, 40264451058, 77046813118, 481, 286, 232);

-- ----------------------------
-- Table structure for schema_versions
-- ----------------------------
DROP TABLE IF EXISTS `schema_versions`;
CREATE TABLE `schema_versions`  (
  `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `version` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 2 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of schema_versions
-- ----------------------------
INSERT INTO `schema_versions` VALUES (1, 'development');

-- ----------------------------
-- Table structure for sessions
-- ----------------------------
DROP TABLE IF EXISTS `sessions`;
CREATE TABLE `sessions`  (
  `session` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `uuid` varchar(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `user_agent` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL,
  `ip` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL,
  `login_method` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL,
  `latest_online` timestamp NULL DEFAULT NULL,
  `latest_user_agent` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL,
  `latest_ip` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL,
  `expires` timestamp NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`session`) USING BTREE,
  INDEX `idx_sessions_uuid`(`uuid` ASC) USING BTREE,
  CONSTRAINT `fk_users_sessions` FOREIGN KEY (`uuid`) REFERENCES `users` (`uuid`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of sessions
-- ----------------------------
INSERT INTO `sessions` VALUES ('5vbgjj3ac35f9VGStnUy6xF6XHolT3my', '85eb7fe5-c1a5-4a2f-a722-7d6539a58a79', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36', '127.0.0.1', 'password', '2026-01-21 13:34:50', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36', '127.0.0.1', '2026-02-19 16:04:26', '2026-01-20 16:04:27');
INSERT INTO `sessions` VALUES ('WQjxceC6K3ZddAZP3t50Z1e1YsTtuCgx', '85eb7fe5-c1a5-4a2f-a722-7d6539a58a79', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36', '127.0.0.1', 'password', '2026-01-21 13:51:29', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36', '127.0.0.1', '2026-02-20 05:38:17', '2026-01-21 05:38:19');

-- ----------------------------
-- Table structure for task_results
-- ----------------------------
DROP TABLE IF EXISTS `task_results`;
CREATE TABLE `task_results`  (
  `task_id` varchar(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `client` varchar(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `result` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL,
  `exit_code` int(11) NULL DEFAULT NULL,
  `finished_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX `idx_task_results_task_id`(`task_id` ASC) USING BTREE,
  INDEX `fk_task_results_client`(`client` ASC) USING BTREE,
  CONSTRAINT `fk_task_results_client` FOREIGN KEY (`client`) REFERENCES `clients` (`uuid`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_task_results_task` FOREIGN KEY (`task_id`) REFERENCES `tasks` (`task_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of task_results
-- ----------------------------

-- ----------------------------
-- Table structure for tasks
-- ----------------------------
DROP TABLE IF EXISTS `tasks`;
CREATE TABLE `tasks`  (
  `task_id` varchar(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `clients` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL COMMENT 'JSON array of client UUIDs',
  `command` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL,
  PRIMARY KEY (`task_id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of tasks
-- ----------------------------

-- ----------------------------
-- Table structure for theme_configurations
-- ----------------------------
DROP TABLE IF EXISTS `theme_configurations`;
CREATE TABLE `theme_configurations`  (
  `short` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `data` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL,
  PRIMARY KEY (`short`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of theme_configurations
-- ----------------------------

-- ----------------------------
-- Table structure for users
-- ----------------------------
DROP TABLE IF EXISTS `users`;
CREATE TABLE `users`  (
  `uuid` varchar(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `username` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `passwd` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `sso_type` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL,
  `sso_id` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL,
  `two_factor` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL,
  `created_at` datetime(3) NULL DEFAULT NULL,
  `updated_at` datetime(3) NULL DEFAULT NULL,
  PRIMARY KEY (`uuid`) USING BTREE,
  UNIQUE INDEX `uni_users_username`(`username` ASC) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of users
-- ----------------------------
INSERT INTO `users` VALUES ('85eb7fe5-c1a5-4a2f-a722-7d6539a58a79', 'admin', 'YQ9hMAs+dNXqIEiE0BK+hwF+dEiqausHUbusiWM4njo=', '', '', '', '2026-01-20 15:03:37.876', '2026-01-20 15:03:37.876');

SET FOREIGN_KEY_CHECKS = 1;
