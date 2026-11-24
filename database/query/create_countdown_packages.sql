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
