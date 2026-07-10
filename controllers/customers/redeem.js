const pool           = require('../../config/db')
const { generateId } = require('../../utils/id')
const { ok, fail }   = require('../../utils/response')

// ───────────────────────────────────────────────────────────────
// POST /api/v1/customers/redeem
// หักแต้มลูกค้า → คืนเป็นส่วนลดบาท
// Body: { phone, points_to_use, staff_id, branch_id }
// ───────────────────────────────────────────────────────────────
const redeem = async (req, res, next) => {

    const { phone, customer_id, points_to_use, discount_amount, staff_id, branch_id } = req.body

    if (!phone && !customer_id) return fail(res, 'ต้องระบุ phone หรือ customer_id')
    if (!points_to_use || Number(points_to_use) <= 0) return fail(res, 'points_to_use ต้องมากกว่า 0')
    if (discount_amount == null || Number(discount_amount) < 0) return fail(res, 'discount_amount ต้องระบุ')

    const toUse = Number(points_to_use)

    const conn = await pool.getConnection()
    try {
        await conn.beginTransaction()

        // ─── Step 1: ค้นหาลูกค้า ──────────────────────────────────
        const [rows] = phone
            ? await conn.execute('SELECT * FROM tb_customers WHERE customers_phone = ?', [phone])
            : await conn.execute('SELECT * FROM tb_customers WHERE customers_id = ?',    [customer_id])

        const customer = rows[0]
        if (!customer) {
            await conn.rollback()
            return fail(res, 'ไม่พบลูกค้า', null, 404)
        }

        // ─── Step 2: ตรวจสอบแต้มจาก customers_point โดยตรง ────────
        const currentBalance = Number(customer.customers_point) || 0

        if (currentBalance < toUse) {
            await conn.rollback()
            return fail(res, `แต้มไม่พอ — มี ${currentBalance} แต้ม ต้องการ ${toUse} แต้ม`)
        }

        // ─── Step 3: หักแต้ม (delta ติดลบ) ───────────────────────
        await conn.execute(
            `INSERT INTO tb_point_transactions
             (point_transactions_id, point_transactions_customer_id, point_transactions_delta,
              point_transactions_type, point_transactions_branch_id, point_transactions_created_by)
             VALUES (?, ?, ?, 'redeem', ?, ?)`,
            [generateId(), customer.customers_id, -toUse, branch_id || null, staff_id || null]
        )

        // ─── Step 4: อัปเดตแต้มสุทธิใน tb_customers ─────────────
        await conn.execute(
            `UPDATE tb_customers
             SET customers_point = customers_point - ?
             WHERE customers_id = ?`,
            [toUse, customer.customers_id]
        )

        const discountAmount = Number(discount_amount)
        const newBalance     = currentBalance - toUse

        await conn.commit()

        ok(res, {
            customer_id:     customer.customers_id,
            points_used:     toUse,
            discount_amount: discountAmount,
            balance:         newBalance,
        }, `ใช้ ${toUse} แต้ม ได้ส่วนลด ${discountAmount} บาท`)

    } catch (err) {
        await conn.rollback()
        next(err)
    } finally {
        conn.release()
    }
}

module.exports = { redeem }
