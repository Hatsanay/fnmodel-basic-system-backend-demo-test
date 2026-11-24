-- =============================================================================
-- production_deploy.sql — โครงสร้าง DB ทั้งหมดที่ระบบ FN Model ใช้ (รันซ้ำได้)
-- =============================================================================
--
-- ใช้ทำอะไร
--   รันไฟล์นี้ทั้งไฟล์บน DB (production / test / local) เพื่อให้โครงสร้างตรงกับโค้ดล่าสุด
--   - DB ว่าง      → สร้างตารางครบ
--   - DB เก่า      → เติมเฉพาะคอลัมน์/index/foreign key ที่ยังขาด
--   - DB ล่าสุดแล้ว → ไม่เปลี่ยนอะไร (รันซ้ำกี่ครั้งก็ได้)
--   ไม่ลบตาราง/คอลัมน์/ข้อมูลใด ๆ และไม่ใส่ข้อมูลตัวอย่าง
--
-- วิธีรัน
--   phpMyAdmin: เลือก DB ทางซ้าย → แท็บ SQL (หรือ Import) → วางทั้งไฟล์ → Go
--   ไม่มีคำสั่ง USE — จะรันกับ DB ที่เลือกอยู่
--   ลำดับ: DB test → deploy test → ทดสอบผ่าน → DB production → deploy production
--
-- ⚠ กติกา: ทุกครั้งที่แก้โครงสร้างฐานข้อมูล ต้องแก้ไฟล์นี้ด้วย
--   1. แก้ CREATE TABLE ในส่วนที่ 1 ให้เป็นโครงสร้างล่าสุด (สำหรับ DB ใหม่)
--   2. เพิ่มขั้น "ensure" ในส่วนที่ 2 ให้ DB เก่าอัปเกรดได้ (เช็คก่อนเสมอ ห้าม ALTER ตรง ๆ)
--   3. เพิ่มบรรทัดใน "ประวัติการเปลี่ยนแปลง" ด้านล่าง
--   4. รันไฟล์นี้ 2 รอบบน DB ทดลองให้ผ่านทั้งสองรอบ ก่อนเอาไปรันจริง
--
-- ประวัติการเปลี่ยนแปลง
--   2026-11-24  สร้างไฟล์ — โครงสร้างตาม dump production (dktimeh_fnmodel) + tb_branches/tb_staff
--   2026-11-24  tb_countdown_packages.package_vehicle_type (รถตัก/รถดริฟ)
-- =============================================================================

SET NAMES utf8mb4;

-- =============================================================================
-- ส่วนที่ 1: ตาราง (สร้างเมื่อยังไม่มี — โครงสร้างล่าสุด)
-- ลำดับสำคัญ: ตารางที่ถูกอ้างถึงด้วย foreign key ต้องมาก่อน
-- =============================================================================

-- สาขา (ยังไม่ได้ใช้ในโค้ด แต่มี foreign key อ้างถึง)
CREATE TABLE IF NOT EXISTS tb_branches (
  branches_id         VARCHAR(15) NOT NULL,
  branches_name       VARCHAR(50),
  branches_address    TEXT,
  branches_phone      VARCHAR(20),
  branches_status     ENUM('active','inactive') DEFAULT 'active',
  branches_created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  branches_updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (branches_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- พนักงาน (ยังไม่ได้ใช้ในโค้ด แต่มี foreign key อ้างถึง)
CREATE TABLE IF NOT EXISTS tb_staff (
  staff_id         VARCHAR(15) NOT NULL,
  staff_fname      VARCHAR(50),
  staff_lname      VARCHAR(50),
  staff_email      VARCHAR(255),
  staff_password   VARCHAR(255),
  staff_role       ENUM('admin','owner','manager','staff'),
  staff_branch_id  VARCHAR(15) NULL,
  staff_status     ENUM('active','inactive') DEFAULT 'active',
  staff_created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  staff_updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (staff_id),
  UNIQUE KEY uq_staff_email (staff_email),
  KEY idx_staff_branch (staff_branch_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ลูกค้า (สมัครอัตโนมัติจากเบอร์ตอนสะสมแต้ม)
CREATE TABLE IF NOT EXISTS tb_customers (
  customers_id                   VARCHAR(15) NOT NULL,
  customers_fname                VARCHAR(50) DEFAULT NULL,
  customers_lname                VARCHAR(50) DEFAULT NULL,
  customers_phone                VARCHAR(10) DEFAULT NULL,
  customers_password             VARCHAR(255) DEFAULT NULL,
  customers_point                INT DEFAULT NULL,
  customers_must_change_password TINYINT(1) DEFAULT 1,
  customers_status               ENUM('active','inactive') DEFAULT 'active',
  customers_created_at           DATETIME DEFAULT CURRENT_TIMESTAMP,
  customers_updated_at           DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (customers_id),
  UNIQUE KEY uq_customers_phone (customers_phone)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ledger แต้ม (delta: + ได้ / - ใช้)
CREATE TABLE IF NOT EXISTS tb_point_transactions (
  point_transactions_id          VARCHAR(15) NOT NULL,
  point_transactions_customer_id VARCHAR(15) DEFAULT NULL,
  point_transactions_delta       INT DEFAULT NULL,
  point_transactions_type        ENUM('earn_payment','redeem','bonus','adjust','expire') DEFAULT NULL,
  point_transactions_amount_paid DECIMAL(10,2) DEFAULT NULL,
  point_transactions_ref_sale_id VARCHAR(15) DEFAULT NULL,
  point_transactions_branch_id   VARCHAR(15) DEFAULT NULL,
  point_transactions_created_by  VARCHAR(15) DEFAULT NULL,
  point_transactions_note        VARCHAR(50) DEFAULT NULL,
  point_transactions_created_at  DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (point_transactions_id),
  KEY idx_pt_customer (point_transactions_customer_id),
  KEY idx_pt_customer_created (point_transactions_customer_id, point_transactions_created_at),
  KEY fk_pt_branch (point_transactions_branch_id),
  KEY fk_pt_staff (point_transactions_created_by)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ของรางวัล (status 'cancel' = ลบแบบ soft เมื่อมีประวัติแลกแล้ว)
CREATE TABLE IF NOT EXISTS tb_rewards (
  rewards_id             VARCHAR(15) NOT NULL,
  rewards_name           VARCHAR(50) DEFAULT NULL,
  rewards_type           ENUM('discount','item','privilege','free_time') DEFAULT 'discount',
  rewards_points_cost    INT DEFAULT NULL,
  rewards_discount_value DECIMAL(10,2) DEFAULT NULL,
  rewards_stock          INT DEFAULT NULL,
  rewards_free_seconds   INT DEFAULT NULL COMMENT 'จำนวนวินาทีเล่นฟรี (เฉพาะ type=free_time)',
  rewards_status         ENUM('active','inactive','cancel') DEFAULT 'active',
  rewards_created_at     DATETIME DEFAULT CURRENT_TIMESTAMP,
  rewards_updated_at     DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (rewards_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ประวัติการแลกรางวัล (snapshot ค่า ณ ตอนแลก)
CREATE TABLE IF NOT EXISTS tb_reward_redemptions (
  reward_redemptions_id             VARCHAR(15) NOT NULL,
  reward_redemptions_customer_id    VARCHAR(15) DEFAULT NULL,
  reward_redemptions_reward_id      VARCHAR(15) DEFAULT NULL,
  reward_redemptions_points_used    INT DEFAULT NULL,
  reward_redemptions_reward_type    ENUM('discount','item','privilege','free_time') DEFAULT NULL,
  reward_redemptions_discount_value DECIMAL(10,2) DEFAULT NULL,
  reward_redemptions_free_seconds   INT DEFAULT NULL COMMENT 'snapshot วินาทีเล่นฟรี ณ ตอนแลก',
  reward_redemptions_ref_sale_id    VARCHAR(15) DEFAULT NULL,
  reward_redemptions_ref_session_id VARCHAR(15) DEFAULT NULL COMMENT 'ใช้เวลาฟรีกับรอบเล่นไหน',
  reward_redemptions_point_tx_id    VARCHAR(15) DEFAULT NULL,
  reward_redemptions_branch_id      VARCHAR(15) DEFAULT NULL,
  reward_redemptions_status         ENUM('redeemed','used','cancelled') DEFAULT 'redeemed',
  reward_redemptions_created_at     DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (reward_redemptions_id),
  KEY idx_rr_customer (reward_redemptions_customer_id),
  KEY idx_rr_reward (reward_redemptions_reward_id),
  KEY fk_rr_pointtx (reward_redemptions_point_tx_id),
  KEY fk_rr_branch (reward_redemptions_branch_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- package เหมาเวลา (รถตัก Class A/B/C, รถดริฟ Class B เท่านั้น)
CREATE TABLE IF NOT EXISTS tb_countdown_packages (
  package_id            VARCHAR(20) NOT NULL,
  package_vehicle_type  ENUM('excavator','drift') NOT NULL DEFAULT 'excavator' COMMENT 'ประเภทรถ: excavator = รถตัก, drift = รถดริฟ',
  package_class         ENUM('A','B','C') NOT NULL,
  package_seconds       INT NOT NULL COMMENT 'ระยะเวลาแพ็กเกจ (วินาที)',
  package_price         DECIMAL(10,2) NOT NULL COMMENT 'ราคาแพ็กเกจ (บาท)',
  package_alert_seconds INT NOT NULL DEFAULT 120 COMMENT 'แจ้งเตือนก่อนหมดเวลากี่วินาที',
  package_status        ENUM('active','inactive') NOT NULL DEFAULT 'active',
  package_created_at    DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (package_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;


-- =============================================================================
-- ส่วนที่ 2: อัปเกรด DB เก่า (ทำเฉพาะเมื่อยังขาด)
-- รูปแบบทุกขั้น: เช็ค information_schema → ถ้าขาดค่อยรัน ALTER, ถ้ามีแล้วรัน DO 0 (ไม่ทำอะไร)
-- =============================================================================

-- ─── คอลัมน์ ─────────────────────────────────────────────────────────────────

-- tb_customers.customers_point
SET @sql := IF((SELECT COUNT(*) FROM information_schema.COLUMNS
                WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'tb_customers' AND COLUMN_NAME = 'customers_point') = 0,
  'ALTER TABLE tb_customers ADD COLUMN customers_point INT DEFAULT NULL AFTER customers_password',
  'DO 0');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- tb_rewards.rewards_free_seconds
SET @sql := IF((SELECT COUNT(*) FROM information_schema.COLUMNS
                WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'tb_rewards' AND COLUMN_NAME = 'rewards_free_seconds') = 0,
  'ALTER TABLE tb_rewards ADD COLUMN rewards_free_seconds INT DEFAULT NULL COMMENT ''จำนวนวินาทีเล่นฟรี (เฉพาะ type=free_time)'' AFTER rewards_stock',
  'DO 0');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- tb_rewards.rewards_type ต้องมี 'free_time'
SET @sql := IF((SELECT COUNT(*) FROM information_schema.COLUMNS
                WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'tb_rewards' AND COLUMN_NAME = 'rewards_type'
                  AND COLUMN_TYPE LIKE '%''free_time''%') = 0,
  'ALTER TABLE tb_rewards MODIFY rewards_type ENUM(''discount'',''item'',''privilege'',''free_time'') DEFAULT ''discount''',
  'DO 0');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- tb_rewards.rewards_status ต้องมี 'cancel'
SET @sql := IF((SELECT COUNT(*) FROM information_schema.COLUMNS
                WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'tb_rewards' AND COLUMN_NAME = 'rewards_status'
                  AND COLUMN_TYPE LIKE '%''cancel''%') = 0,
  'ALTER TABLE tb_rewards MODIFY rewards_status ENUM(''active'',''inactive'',''cancel'') DEFAULT ''active''',
  'DO 0');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- tb_reward_redemptions.reward_redemptions_reward_type ต้องมี 'free_time'
SET @sql := IF((SELECT COUNT(*) FROM information_schema.COLUMNS
                WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'tb_reward_redemptions' AND COLUMN_NAME = 'reward_redemptions_reward_type'
                  AND COLUMN_TYPE LIKE '%''free_time''%') = 0,
  'ALTER TABLE tb_reward_redemptions MODIFY reward_redemptions_reward_type ENUM(''discount'',''item'',''privilege'',''free_time'') DEFAULT NULL',
  'DO 0');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- tb_reward_redemptions.reward_redemptions_free_seconds
SET @sql := IF((SELECT COUNT(*) FROM information_schema.COLUMNS
                WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'tb_reward_redemptions' AND COLUMN_NAME = 'reward_redemptions_free_seconds') = 0,
  'ALTER TABLE tb_reward_redemptions ADD COLUMN reward_redemptions_free_seconds INT DEFAULT NULL COMMENT ''snapshot วินาทีเล่นฟรี ณ ตอนแลก'' AFTER reward_redemptions_discount_value',
  'DO 0');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- tb_reward_redemptions.reward_redemptions_ref_session_id
SET @sql := IF((SELECT COUNT(*) FROM information_schema.COLUMNS
                WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'tb_reward_redemptions' AND COLUMN_NAME = 'reward_redemptions_ref_session_id') = 0,
  'ALTER TABLE tb_reward_redemptions ADD COLUMN reward_redemptions_ref_session_id VARCHAR(15) DEFAULT NULL COMMENT ''ใช้เวลาฟรีกับรอบเล่นไหน'' AFTER reward_redemptions_ref_sale_id',
  'DO 0');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- tb_countdown_packages.package_vehicle_type (2026-11-24 รถดริฟ)
SET @sql := IF((SELECT COUNT(*) FROM information_schema.COLUMNS
                WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'tb_countdown_packages' AND COLUMN_NAME = 'package_vehicle_type') = 0,
  'ALTER TABLE tb_countdown_packages ADD COLUMN package_vehicle_type ENUM(''excavator'',''drift'') NOT NULL DEFAULT ''excavator'' COMMENT ''ประเภทรถ: excavator = รถตัก, drift = รถดริฟ'' AFTER package_id',
  'DO 0');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ─── index ───────────────────────────────────────────────────────────────────

-- tb_customers.uq_customers_phone (กันเบอร์ซ้ำตอนสมัครอัตโนมัติ)
SET @sql := IF((SELECT COUNT(*) FROM information_schema.STATISTICS
                WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'tb_customers' AND INDEX_NAME = 'uq_customers_phone') = 0,
  'ALTER TABLE tb_customers ADD UNIQUE KEY uq_customers_phone (customers_phone)',
  'DO 0');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- tb_point_transactions.idx_pt_customer_created (ดึงประวัติแต้มล่าสุด)
SET @sql := IF((SELECT COUNT(*) FROM information_schema.STATISTICS
                WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'tb_point_transactions' AND INDEX_NAME = 'idx_pt_customer_created') = 0,
  'ALTER TABLE tb_point_transactions ADD KEY idx_pt_customer_created (point_transactions_customer_id, point_transactions_created_at)',
  'DO 0');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ─── foreign key ─────────────────────────────────────────────────────────────

-- fk_staff_branch
SET @sql := IF((SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS
                WHERE CONSTRAINT_SCHEMA = DATABASE() AND TABLE_NAME = 'tb_staff' AND CONSTRAINT_NAME = 'fk_staff_branch' AND CONSTRAINT_TYPE = 'FOREIGN KEY') = 0,
  'ALTER TABLE tb_staff ADD CONSTRAINT fk_staff_branch FOREIGN KEY (staff_branch_id) REFERENCES tb_branches (branches_id)',
  'DO 0');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- fk_pt_customer
SET @sql := IF((SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS
                WHERE CONSTRAINT_SCHEMA = DATABASE() AND TABLE_NAME = 'tb_point_transactions' AND CONSTRAINT_NAME = 'fk_pt_customer' AND CONSTRAINT_TYPE = 'FOREIGN KEY') = 0,
  'ALTER TABLE tb_point_transactions ADD CONSTRAINT fk_pt_customer FOREIGN KEY (point_transactions_customer_id) REFERENCES tb_customers (customers_id)',
  'DO 0');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- fk_pt_branch
SET @sql := IF((SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS
                WHERE CONSTRAINT_SCHEMA = DATABASE() AND TABLE_NAME = 'tb_point_transactions' AND CONSTRAINT_NAME = 'fk_pt_branch' AND CONSTRAINT_TYPE = 'FOREIGN KEY') = 0,
  'ALTER TABLE tb_point_transactions ADD CONSTRAINT fk_pt_branch FOREIGN KEY (point_transactions_branch_id) REFERENCES tb_branches (branches_id)',
  'DO 0');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- fk_pt_staff
SET @sql := IF((SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS
                WHERE CONSTRAINT_SCHEMA = DATABASE() AND TABLE_NAME = 'tb_point_transactions' AND CONSTRAINT_NAME = 'fk_pt_staff' AND CONSTRAINT_TYPE = 'FOREIGN KEY') = 0,
  'ALTER TABLE tb_point_transactions ADD CONSTRAINT fk_pt_staff FOREIGN KEY (point_transactions_created_by) REFERENCES tb_staff (staff_id)',
  'DO 0');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- fk_rr_customer
SET @sql := IF((SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS
                WHERE CONSTRAINT_SCHEMA = DATABASE() AND TABLE_NAME = 'tb_reward_redemptions' AND CONSTRAINT_NAME = 'fk_rr_customer' AND CONSTRAINT_TYPE = 'FOREIGN KEY') = 0,
  'ALTER TABLE tb_reward_redemptions ADD CONSTRAINT fk_rr_customer FOREIGN KEY (reward_redemptions_customer_id) REFERENCES tb_customers (customers_id)',
  'DO 0');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- fk_rr_reward
SET @sql := IF((SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS
                WHERE CONSTRAINT_SCHEMA = DATABASE() AND TABLE_NAME = 'tb_reward_redemptions' AND CONSTRAINT_NAME = 'fk_rr_reward' AND CONSTRAINT_TYPE = 'FOREIGN KEY') = 0,
  'ALTER TABLE tb_reward_redemptions ADD CONSTRAINT fk_rr_reward FOREIGN KEY (reward_redemptions_reward_id) REFERENCES tb_rewards (rewards_id)',
  'DO 0');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- fk_rr_pointtx
SET @sql := IF((SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS
                WHERE CONSTRAINT_SCHEMA = DATABASE() AND TABLE_NAME = 'tb_reward_redemptions' AND CONSTRAINT_NAME = 'fk_rr_pointtx' AND CONSTRAINT_TYPE = 'FOREIGN KEY') = 0,
  'ALTER TABLE tb_reward_redemptions ADD CONSTRAINT fk_rr_pointtx FOREIGN KEY (reward_redemptions_point_tx_id) REFERENCES tb_point_transactions (point_transactions_id)',
  'DO 0');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- fk_rr_branch
SET @sql := IF((SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS
                WHERE CONSTRAINT_SCHEMA = DATABASE() AND TABLE_NAME = 'tb_reward_redemptions' AND CONSTRAINT_NAME = 'fk_rr_branch' AND CONSTRAINT_TYPE = 'FOREIGN KEY') = 0,
  'ALTER TABLE tb_reward_redemptions ADD CONSTRAINT fk_rr_branch FOREIGN KEY (reward_redemptions_branch_id) REFERENCES tb_branches (branches_id)',
  'DO 0');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- =============================================================================
-- จบ — ตรวจผลได้ด้วย:  SHOW CREATE TABLE tb_countdown_packages;
-- =============================================================================
