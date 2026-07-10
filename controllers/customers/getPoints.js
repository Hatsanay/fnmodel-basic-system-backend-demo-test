const pool         = require('../../config/db')
const { ok, fail } = require('../../utils/response')

// ───────────────────────────────────────────────────────────────
// GET /api/v1/customers/points?phone=xxx
// GET /api/v1/customers/points?customer_id=xxx
// ดูข้อมูลลูกค้า + แต้มคงเหลือ + ประวัติ 20 รายการล่าสุด
// ───────────────────────────────────────────────────────────────
const getPoints = async (req, res, next) => {

    const { phone, customer_id } = req.query

    if (!phone && !customer_id) {
        return fail(res, 'ต้องระบุ phone หรือ customer_id')
    }

    try {
        // ─── Step 1: ค้นหาลูกค้า (customers_point อยู่ในแถวนี้แล้ว) ─
        const [rows] = phone
            ? await pool.execute(
                'SELECT * FROM tb_customers WHERE customers_phone = ?',
                [phone]
              )
            : await pool.execute(
                'SELECT * FROM tb_customers WHERE customers_id = ?',
                [customer_id]
              )

        const customer = rows[0]

        if (!customer) {
            return fail(res, 'ไม่พบลูกค้า', null, 404)
        }

        // ─── Step 2: ดึงประวัติ 20 รายการล่าสุด ──────────────────
        const [history] = await pool.execute(
            `SELECT
                point_transactions_id,
                point_transactions_delta,
                point_transactions_type,
                point_transactions_amount_paid,
                point_transactions_note,
                point_transactions_created_at
             FROM tb_point_transactions
             WHERE point_transactions_customer_id = ?
             ORDER BY point_transactions_created_at DESC
             LIMIT 20`,
            [customer.customers_id]
        )

        // ─── Step 3: ส่งผลลัพธ์กลับ ───────────────────────────────
        ok(res, {
            customer: {
                customers_id:     customer.customers_id,
                customers_fname:  customer.customers_fname,
                customers_lname:  customer.customers_lname,
                customers_phone:  customer.customers_phone,
                customers_status: customer.customers_status,
            },
            balance: Number(customer.customers_point) || 0,
            history,
        })

    } catch (err) {
        next(err)
    }
}

module.exports = { getPoints }
