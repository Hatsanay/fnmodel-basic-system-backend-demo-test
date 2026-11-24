# database/query

SQL ของระบบ FN Model (DB: MariaDB บน server / MySQL 8.4 ในเครื่อง, ตาราง prefix `tb_`)

## ⭐ production_deploy.sql — ไฟล์หลัก

โครงสร้าง DB **ทั้งหมด**ที่ระบบใช้ **รันซ้ำได้** (idempotent):
- DB ว่าง → สร้างครบ / DB เก่า → เติมเฉพาะที่ขาด / DB ล่าสุด → ไม่เปลี่ยนอะไร
- ไม่ลบตาราง คอลัมน์ หรือข้อมูล และไม่ใส่ข้อมูลตัวอย่าง
- รัน: phpMyAdmin → เลือก DB → แท็บ SQL → วางทั้งไฟล์ → Go (ไม่มี `USE` ในไฟล์)

> **กติกา: ทุกครั้งที่แก้โครงสร้างฐานข้อมูล ต้องแก้ `production_deploy.sql` ด้วย**
> 1. แก้ `CREATE TABLE` ในส่วนที่ 1 ให้เป็นโครงสร้างล่าสุด
> 2. เพิ่มขั้น ensure ในส่วนที่ 2 (เช็ค `information_schema` ก่อนเสมอ — ห้าม `ALTER` ตรง ๆ ที่รันซ้ำแล้ว error)
> 3. เพิ่มบรรทัดใน "ประวัติการเปลี่ยนแปลง" หัวไฟล์
> 4. ทดสอบรัน 2 รอบบน DB ทดลอง (DB ว่าง + DB โครงสร้างเดิม) ต้องผ่านทั้งสองรอบ และรอบ 2 ต้องไม่เปลี่ยนอะไร

ลำดับ deploy: รันบน DB test → deploy test → ทดสอบ → รันบน DB production → deploy production

### บันทึกการรัน production_deploy.sql

| วันที่ | local | DB test | DB production | หมายเหตุ |
|---|---|---|---|---|
| 2026-11-24 | — | ☐ | ☐ | เวอร์ชันแรก (รวม package_vehicle_type) |

(local รัน `alter_add_vehicle_type.sql` ไปแล้ว 2026-11-24 — โครงสร้างเท่ากัน)

## ไฟล์อื่น (อ้างอิงเท่านั้น)

| ไฟล์ | |
|---|---|
| `alter_add_vehicle_type.sql` | migration รถดริฟแบบเดี่ยว — **รวมอยู่ใน production_deploy.sql แล้ว** ใช้ไฟล์หลักแทน (ไฟล์นี้รันซ้ำไม่ได้) |
| `create.sql` | โครงสร้างตั้งต้นยุคแรก — **ล้าสมัย** อย่าใช้สร้าง DB |
| `create_countdown_packages.sql` | สร้าง `tb_countdown_packages` + package ตั้งต้น 4 ตัว (ข้อมูลตัวอย่าง) |
| `ss.sql` | `tb_class_config` (backend ไม่ได้ใช้) |

### ทำไม create.sql ถึงล้าสมัย
- ไม่มี `tb_customers.customers_point`, enum `rewards_status` ไม่มี `'cancel'`
- `ADD UNIQUE KEY uq_customers_phone` ซ้ำกับใน CREATE → รันทั้งไฟล์ error
- ตาราง `tb_timer_tables`, `tb_transactions`, `tb_transaction_items`, `tb_daily_report`, `tb_monthly_history`, `tb_daily_expenses`, `tb_class_config`, `tb_membership_plans`, `tb_customer_memberships` **ไม่ได้ใช้** (ยอดขาย/รายงานเก็บใน localStorage ของหน้าเว็บ) — จึงไม่อยู่ใน production_deploy.sql
