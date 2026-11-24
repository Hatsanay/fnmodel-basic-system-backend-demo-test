SET NAMES utf8mb4 collate utf8mb4_general_ci;

-- 1) สาขา
CREATE TABLE tb_branches (
  branches_id         VARCHAR(15) NOT NULL,
  branches_name       VARCHAR(50),
  branches_address    TEXT,
  branches_phone      VARCHAR(20),
  branches_status     ENUM('active','inactive') DEFAULT 'active',
  branches_created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  branches_updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (branches_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2) พนักงาน
CREATE TABLE tb_staff (
  staff_id         VARCHAR(15) NOT NULL,
  staff_fname      VARCHAR(50),
  staff_lname      VARCHAR(50),
  staff_email      VARCHAR(255),
  staff_password   VARCHAR(255),                 -- ขยายจาก 50 เพื่อรองรับ bcrypt hash (60 ตัว)
  staff_role       ENUM('admin','owner','manager','staff'),
  staff_branch_id  VARCHAR(15) NULL,
  staff_status     ENUM('active','inactive') DEFAULT 'active',
  staff_created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  staff_updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (staff_id),
  UNIQUE KEY uq_staff_email (staff_email),
  KEY idx_staff_branch (staff_branch_id),
  CONSTRAINT fk_staff_branch FOREIGN KEY (staff_branch_id) REFERENCES tb_branches(branches_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3) ลูกค้า
CREATE TABLE tb_customers (
  customers_id                   VARCHAR(15) NOT NULL,
  customers_fname                VARCHAR(50),
  customers_lname                VARCHAR(50),
  customers_phone                VARCHAR(10),
  customers_password             VARCHAR(255),   -- ขยายจาก 50 เพื่อรองรับ bcrypt
  customers_must_change_password BOOLEAN DEFAULT TRUE,
  customers_status               ENUM('active','inactive') DEFAULT 'active',
  customers_created_at           DATETIME DEFAULT CURRENT_TIMESTAMP,
  customers_updated_at           DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (customers_id),
  UNIQUE KEY uq_customers_phone (customers_phone)   -- เบอร์ห้ามซ้ำ (ใช้ค้น+login)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4) แผนสมาชิก (เมนู)
CREATE TABLE tb_membership_plans (
  membership_plans_id               VARCHAR(15) NOT NULL,
  membership_plans_name             VARCHAR(50),
  membership_plans_type             ENUM('free','package','period') DEFAULT 'free',
  membership_plans_price            DECIMAL(10,2),
  membership_plans_sec_included     INT NULL,
  membership_plans_rounds_included  INT NULL,
  membership_plans_duration_days    INT NULL,
  membership_plans_discount_percent DOUBLE,
  membership_plans_status           ENUM('active','inactive') DEFAULT 'active',
  membership_plans_created_at       DATETIME DEFAULT CURRENT_TIMESTAMP,
  membership_plans_updated_at       DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (membership_plans_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5) สมาชิกที่ลูกค้าถือ
CREATE TABLE tb_customer_memberships (
  customer_memberships_id               VARCHAR(15) NOT NULL,
  customer_memberships_customer_id      VARCHAR(15),
  customer_memberships_plan_id          VARCHAR(15),
  customer_memberships_rounds_remaining INT NULL,
  customer_memberships_expires_at       DATETIME,
  customer_memberships_purchased_at     DATETIME DEFAULT CURRENT_TIMESTAMP,
  customer_memberships_status           ENUM('active','inactive') DEFAULT 'active',
  PRIMARY KEY (customer_memberships_id),
  KEY idx_cm_customer (customer_memberships_customer_id),
  KEY idx_cm_plan (customer_memberships_plan_id),
  CONSTRAINT fk_cm_customer FOREIGN KEY (customer_memberships_customer_id) REFERENCES tb_customers(customers_id),
  CONSTRAINT fk_cm_plan     FOREIGN KEY (customer_memberships_plan_id)     REFERENCES tb_membership_plans(membership_plans_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 6) ledger แต้ม
CREATE TABLE tb_point_transactions (
  point_transactions_id          VARCHAR(15) NOT NULL,
  point_transactions_customer_id VARCHAR(15),
  point_transactions_delta       INT,                       -- signed: + ได้ / - หัก (ห้าม UNSIGNED)
  point_transactions_type        ENUM('earn_payment','redeem','bonus','adjust','expire'),
  point_transactions_amount_paid DECIMAL(10,2),
  point_transactions_ref_sale_id VARCHAR(15),                -- ผูกกับ sale ภายหลัง
  point_transactions_branch_id   VARCHAR(15) NULL,
  point_transactions_created_by  VARCHAR(15) NULL,
  point_transactions_note        VARCHAR(50),
  point_transactions_created_at  DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (point_transactions_id),
  KEY idx_pt_customer (point_transactions_customer_id),
  KEY idx_pt_customer_created (point_transactions_customer_id, point_transactions_created_at),
  CONSTRAINT fk_pt_customer FOREIGN KEY (point_transactions_customer_id) REFERENCES tb_customers(customers_id),
  CONSTRAINT fk_pt_branch   FOREIGN KEY (point_transactions_branch_id)   REFERENCES tb_branches(branches_id),
  CONSTRAINT fk_pt_staff    FOREIGN KEY (point_transactions_created_by)  REFERENCES tb_staff(staff_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 7) ของรางวัล
CREATE TABLE tb_rewards (
  rewards_id             VARCHAR(15) NOT NULL,
  rewards_name           VARCHAR(50),
  rewards_type           ENUM('discount','item','privilege') DEFAULT 'discount',
  rewards_points_cost    INT,
  rewards_discount_value DECIMAL(10,2) NULL,    -- เฉพาะ type=discount
  rewards_stock          INT NULL,              -- เฉพาะ type=item (null=ไม่จำกัด)
  rewards_status         ENUM('active','inactive') DEFAULT 'active',
  rewards_created_at     DATETIME DEFAULT CURRENT_TIMESTAMP,
  rewards_updated_at     DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (rewards_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 8) ประวัติการแลก
CREATE TABLE tb_reward_redemptions (
  reward_redemptions_id             VARCHAR(15) NOT NULL,
  reward_redemptions_customer_id    VARCHAR(15),
  reward_redemptions_reward_id      VARCHAR(15),
  reward_redemptions_points_used    INT,                   -- snapshot
  reward_redemptions_reward_type    ENUM('discount','item','privilege'),   -- snapshot
  reward_redemptions_discount_value DECIMAL(10,2) NULL,    -- snapshot
  reward_redemptions_ref_sale_id    VARCHAR(15) NULL,
  reward_redemptions_point_tx_id    VARCHAR(15) NULL,
  reward_redemptions_branch_id      VARCHAR(15) NULL,
  reward_redemptions_status         ENUM('redeemed','used','cancelled') DEFAULT 'redeemed',
  reward_redemptions_created_at     DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (reward_redemptions_id),
  KEY idx_rr_customer (reward_redemptions_customer_id),
  KEY idx_rr_reward (reward_redemptions_reward_id),
  CONSTRAINT fk_rr_customer FOREIGN KEY (reward_redemptions_customer_id) REFERENCES tb_customers(customers_id),
  CONSTRAINT fk_rr_reward   FOREIGN KEY (reward_redemptions_reward_id)   REFERENCES tb_rewards(rewards_id),
  CONSTRAINT fk_rr_pointtx  FOREIGN KEY (reward_redemptions_point_tx_id) REFERENCES tb_point_transactions(point_transactions_id),
  CONSTRAINT fk_rr_branch   FOREIGN KEY (reward_redemptions_branch_id)   REFERENCES tb_branches(branches_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

commit;


-- 1) ให้ field ชื่อเป็น null ได้ (สมัครอัตโนมัติจากเบอร์ ยังไม่รู้ชื่อ)
ALTER TABLE tb_customers
  MODIFY customers_fname VARCHAR(50) NULL,
  MODIFY customers_lname VARCHAR(50) NULL;

-- 2) ขยาย password รองรับ bcrypt hash (60 ตัว)
ALTER TABLE tb_customers
  MODIFY customers_password VARCHAR(255) NOT NULL;

-- 3) เพิ่ม unique ที่เบอร์ (กัน record ซ้ำตอน find-or-create)
ALTER TABLE tb_customers
  ADD UNIQUE KEY uq_customers_phone (customers_phone);
  
  commit;
  

USE db_fnmodel;

CREATE TABLE tb_class_config (
  class_id        CHAR(1)       NOT NULL,
  class_base      DECIMAL(10,2) NOT NULL,
  class_per_min   DECIMAL(10,2) NOT NULL,
  PRIMARY KEY (class_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO tb_class_config (class_id, class_base, class_per_min) VALUES
  ('A', 50, 5),
  ('B', 30, 3),
  ('C', 10, 1)
ON DUPLICATE KEY UPDATE
  class_base    = VALUES(class_base),
  class_per_min = VALUES(class_per_min);


CREATE TABLE tb_timer_tables (
  table_id           INT           NOT NULL,
  table_name         VARCHAR(100)  NOT NULL DEFAULT '',
  table_elapsed      BIGINT        NOT NULL DEFAULT 0,
  table_is_running   TINYINT(1)    NOT NULL DEFAULT 0,
  table_is_finished  TINYINT(1)    NOT NULL DEFAULT 0,
  table_active_class CHAR(1)       NULL,
  table_pay_type     ENUM('cash','transfer') NULL,
  sum_minutes        INT           NULL,
  sum_class          CHAR(1)       NULL,
  sum_base           DECIMAL(10,2) NULL,
  sum_timer_cost     DECIMAL(10,2) NULL,
  sum_total          DECIMAL(10,2) NULL,
  sum_orig_total     DECIMAL(10,2) NULL,
  sum_discount       DECIMAL(10,2) NOT NULL DEFAULT 0,
  sum_elapsed        BIGINT        NULL,
  table_updated_at   DATETIME      DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (table_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;





CREATE TABLE tb_transactions (
  tx_id          BIGINT                  NOT NULL,
  tx_time_str    VARCHAR(10)             NOT NULL,
  tx_table_name  VARCHAR(100)            NOT NULL,
  tx_class       VARCHAR(10)             NOT NULL,
  tx_duration    INT                     NOT NULL DEFAULT 0,
  tx_amount      DECIMAL(10,2)           NOT NULL,
  tx_orig_amount DECIMAL(10,2)           NOT NULL DEFAULT 0,
  tx_discount    DECIMAL(10,2)           NOT NULL DEFAULT 0,
  tx_elapsed     BIGINT                  NOT NULL DEFAULT 0,
  tx_pay_type    ENUM('cash','transfer') NOT NULL,
  tx_is_basket   TINYINT(1)              NOT NULL DEFAULT 0,
  tx_created_at  DATETIME                DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (tx_id),
  KEY idx_tx_created (tx_created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE tb_transaction_items (
  item_id          INT AUTO_INCREMENT  NOT NULL,
  item_tx_id       BIGINT              NOT NULL,
  item_name        VARCHAR(100)        NOT NULL,
  item_class       CHAR(1)             NOT NULL,
  item_duration    INT                 NOT NULL DEFAULT 0,
  item_amount      DECIMAL(10,2)       NOT NULL,
  item_orig_amount DECIMAL(10,2)       NOT NULL DEFAULT 0,
  item_elapsed     BIGINT              NOT NULL DEFAULT 0,
  PRIMARY KEY (item_id),
  KEY idx_item_tx (item_tx_id),
  CONSTRAINT fk_item_tx FOREIGN KEY (item_tx_id) REFERENCES tb_transactions(tx_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE tb_daily_report (
  report_id         INT AUTO_INCREMENT  NOT NULL,
  total_clients     INT           NOT NULL DEFAULT 0,
  count_a           INT           NOT NULL DEFAULT 0,
  count_b           INT           NOT NULL DEFAULT 0,
  count_c           INT           NOT NULL DEFAULT 0,
  income_a          DECIMAL(10,2) NOT NULL DEFAULT 0,
  income_b          DECIMAL(10,2) NOT NULL DEFAULT 0,
  income_c          DECIMAL(10,2) NOT NULL DEFAULT 0,
  cash_total        DECIMAL(10,2) NOT NULL DEFAULT 0,
  transfer_total    DECIMAL(10,2) NOT NULL DEFAULT 0,
  grand_total       DECIMAL(10,2) NOT NULL DEFAULT 0,
  total_time_ms     BIGINT        NOT NULL DEFAULT 0,
  report_updated_at DATETIME      DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (report_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT IGNORE INTO tb_daily_report (report_id) VALUES (1);


CREATE TABLE tb_monthly_history (
  history_id         INT AUTO_INCREMENT NOT NULL,
  history_date_str   VARCHAR(80)   NOT NULL,
  history_date       DATE          NOT NULL,
  total_clients      INT           NOT NULL DEFAULT 0,
  count_a            INT           NOT NULL DEFAULT 0,
  count_b            INT           NOT NULL DEFAULT 0,
  count_c            INT           NOT NULL DEFAULT 0,
  income_a           DECIMAL(10,2) NOT NULL DEFAULT 0,
  income_b           DECIMAL(10,2) NOT NULL DEFAULT 0,
  income_c           DECIMAL(10,2) NOT NULL DEFAULT 0,
  cash_total         DECIMAL(10,2) NOT NULL DEFAULT 0,
  transfer_total     DECIMAL(10,2) NOT NULL DEFAULT 0,
  grand_total        DECIMAL(10,2) NOT NULL DEFAULT 0,
  total_expenses     DECIMAL(10,2) NOT NULL DEFAULT 0,
  net_profit         DECIMAL(10,2) NOT NULL DEFAULT 0,
  history_created_at DATETIME      DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (history_id),
  UNIQUE KEY uq_history_date (history_date_str)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE tb_daily_expenses (
  expense_id         INT AUTO_INCREMENT NOT NULL,
  expense_history_id INT           NOT NULL,
  expense_name       VARCHAR(200)  NOT NULL,
  expense_amount     DECIMAL(10,2) NOT NULL,
  PRIMARY KEY (expense_id),
  KEY idx_expense_history (expense_history_id),
  CONSTRAINT fk_expense_history FOREIGN KEY (expense_history_id) REFERENCES tb_monthly_history(history_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


ALTER TABLE tb_rewards
  MODIFY rewards_type enum('discount','item','privilege','free_time') 
         COLLATE utf8mb4_unicode_ci DEFAULT 'discount',
  ADD COLUMN rewards_free_seconds INT DEFAULT NULL 
      COMMENT 'จำนวนวินาทีเล่นฟรี (เฉพาะ type=free_time)' 
      AFTER rewards_stock;

ALTER TABLE tb_reward_redemptions
  MODIFY reward_redemptions_reward_type 
         enum('discount','item','privilege','free_time') 
         COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  ADD COLUMN reward_redemptions_free_seconds INT DEFAULT NULL 
      COMMENT 'snapshot วินาทีเล่นฟรี ณ ตอนแลก' 
      AFTER reward_redemptions_discount_value,
  ADD COLUMN reward_redemptions_ref_session_id varchar(15) 
         COLLATE utf8mb4_unicode_ci DEFAULT NULL 
      COMMENT 'ใช้เวลาฟรีกับรอบเล่นไหน' 
      AFTER reward_redemptions_ref_sale_id;

commit;


INSERT INTO tb_rewards
  (rewards_id, rewards_name, rewards_type, rewards_points_cost,
   rewards_discount_value, rewards_stock, rewards_free_seconds, rewards_status)
VALUES
  ('RWD000000001', 'เล่นฟรี 10 นาที',  'free_time',  10,  NULL, NULL, 600,  'active'),
  ('RWD000000002', 'ของรางวัล A',       'item',       50,  NULL, NULL, NULL, 'active'),
  ('RWD000000003', 'ของรางวัล B',       'item',       80,  NULL, NULL, NULL, 'active'),
  ('RWD000000004', 'ของรางวัล C',       'item',       100, NULL, NULL, NULL, 'active');


-- ─── สร้างตาราง countdown packages ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS tb_countdown_packages (
    package_id            VARCHAR(20)             NOT NULL PRIMARY KEY,
    package_class         ENUM('A','B','C')       NOT NULL,
    package_seconds       INT                     NOT NULL COMMENT 'ระยะเวลาแพ็กเกจ (วินาที)',
    package_price         DECIMAL(10,2)           NOT NULL COMMENT 'ราคาแพ็กเกจ (บาท)',
    package_alert_seconds INT                     NOT NULL DEFAULT 120 COMMENT 'แจ้งเตือนก่อนหมดเวลากี่วินาที',
    package_status        ENUM('active','inactive') NOT NULL DEFAULT 'active',
    package_created_at    DATETIME                DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ─── ข้อมูลเริ่มต้น (preset packages) ──────────────────────────────────────────
INSERT IGNORE INTO tb_countdown_packages
    (package_id, package_class, package_seconds, package_price, package_alert_seconds)
VALUES
    ('CD000000000001', 'A', 1800, 120.00, 120),   -- Class A  30 นาที 120 บาท
    ('CD000000000002', 'A', 3600, 200.00, 120),   -- Class A  60 นาที 200 บาท
    ('CD000000000003', 'B', 1800,  80.00, 120),   -- Class B  30 นาที  80 บาท
    ('CD000000000004', 'B', 3600, 150.00, 120);   -- Class B  60 นาที 150 บาท
