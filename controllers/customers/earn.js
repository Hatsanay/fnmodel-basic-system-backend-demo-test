const pool           = require('../../config/db')
const bcrypt         = require('bcryptjs')
const { generateId } = require('../../utils/id')
const { ok, fail }   = require('../../utils/response')

// ───────────────────────────────────────────────────────────────
// POST /api/v1/customers/earn
// กรอกเบอร์ลูกค้า → ค้นหา (ถ้าไม่มีสร้างใหม่) → บวกแต้ม
// ───────────────────────────────────────────────────────────────
const earn = async (req, res, next) => {

    const { phone, amount_paid, points_to_earn, branch_id, staff_id, ref_sale_id } = req.body

    if (!phone)                 return fail(res, 'phone จำเป็น')
    if (!amount_paid)           return fail(res, 'amount_paid จำเป็น')
    if (points_to_earn == null) return fail(res, 'points_to_earn จำเป็น')

    const conn = await pool.getConnection()
    try {
        await conn.beginTransaction()

        // ─── Step 1: ค้นหาลูกค้าจากเบอร์ ──────────────────────────
        let [[customer]] = await conn.execute(
            'SELECT * FROM tb_customers WHERE customers_phone = ?',
            [phone]
        )

        // ─── Step 2: ถ้าไม่มี → สร้างลูกค้าใหม่ ─────────────────────
        let created = false

        if (!customer) {
            const newId     = generateId()
            const tempPwd   = Math.random().toString(36).slice(-8)
            const hashedPwd = await bcrypt.hash(tempPwd, 10)

            await conn.execute(
                `INSERT INTO tb_customers
                 (customers_id, customers_phone, customers_password, customers_point, customers_must_change_password)
                 VALUES (?, ?, ?, 0, 1)`,
                [newId, phone, hashedPwd]
            )

            created = true

            ;[[customer]] = await conn.execute(
                'SELECT * FROM tb_customers WHERE customers_phone = ?',
                [phone]
            )

            if (!customer) throw new Error(`INSERT สำเร็จแต่ SELECT ไม่พบ phone: ${phone}`)
        }

        // ─── Step 3: ใช้แต้มที่ frontend คำนวณส่งมา ──────────────────
        const pointsEarned = Number(points_to_earn)

        // ─── Step 4: บันทึก transaction ledger ───────────────────────
        await conn.execute(
            `INSERT INTO tb_point_transactions
             (point_transactions_id, point_transactions_customer_id, point_transactions_delta,
              point_transactions_type, point_transactions_amount_paid,
              point_transactions_ref_sale_id, point_transactions_branch_id, point_transactions_created_by)
             VALUES (?, ?, ?, 'earn_payment', ?, ?, ?, ?)`,
            [
                generateId(),
                customer.customers_id,
                pointsEarned,
                Number(amount_paid),
                ref_sale_id || null,
                branch_id   || null,
                staff_id    || null,
            ]
        )

        // ─── Step 5: อัปเดตแต้มสุทธิใน tb_customers ─────────────────
        await conn.execute(
            `UPDATE tb_customers
             SET customers_point = COALESCE(customers_point, 0) + ?
             WHERE customers_id = ?`,
            [pointsEarned, customer.customers_id]
        )

        const newBalance = (Number(customer.customers_point) || 0) + pointsEarned

        await conn.commit()

        ok(res, {
            customer: {
                customers_id:     customer.customers_id,
                customers_fname:  customer.customers_fname,
                customers_lname:  customer.customers_lname,
                customers_phone:  customer.customers_phone,
                customers_status: customer.customers_status,
            },
            created,
            pointsEarned,
            balance: newBalance,
        }, created ? 'สร้างลูกค้าใหม่และบวกแต้มสำเร็จ' : 'บวกแต้มสำเร็จ')

    } catch (err) {
        await conn.rollback()
        next(err)
    } finally {
        conn.release()
    }
}

module.exports = { earn }
