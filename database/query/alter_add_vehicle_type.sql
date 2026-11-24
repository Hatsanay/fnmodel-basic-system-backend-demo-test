-- ─── เพิ่มประเภทรถให้ Package เหมาเวลา (รถตัก / รถดริฟ) ─────────────────────
-- รันบน DB test ก่อน → ทดสอบผ่าน → ค่อยรันบน DB production
-- ต้องรัน "ก่อน" deploy backend เวอร์ชันที่รองรับรถดริฟ
-- package เดิมทั้งหมดจะเป็น 'excavator' (รถตัก) อัตโนมัติ

ALTER TABLE tb_countdown_packages
  ADD COLUMN package_vehicle_type ENUM('excavator','drift') NOT NULL DEFAULT 'excavator'
      COMMENT 'ประเภทรถ: excavator = รถตัก, drift = รถดริฟ'
      AFTER package_id;
