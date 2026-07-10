const pool           = require('../../config/db')
const { generateId } = require('../../utils/id')
const { ok, fail }   = require('../../utils/response')

// POST /api/v1/rewards/redeem
// Body: { phone | customer_id, reward_id }
const redeemReward = async (req, res, next) => {

    const { phone, customer_id, reward_id } = req.body

    if (!phone && !customer_id) return fail(res, 'ต้องระบุ phone หรือ customer_id')
    if (!reward_id)             return fail(res, 'ต้องระบุ reward_id')

    const conn = await pool.getConnection()
    try {
        await conn.beginTransaction()

        // ─── ค้นหาลูกค้า ─────────────────────────────────────────────
        const [custRows] = phone
            ? await conn.execute('SELECT * FROM tb_customers WHERE customers_phone = ?', [phone])
            : await conn.execute('SELECT * FROM tb_customers WHERE customers_id = ?',    [customer_id])

        const customer = custRows[0]
        if (!customer) { await conn.rollback(); return fail(res, 'ไม่พบลูกค้า', null, 404) }

        // ─── ค้นหา reward ─────────────────────────────────────────────
        const [[reward]] = await conn.execute(
            'SELECT * FROM tb_rewards WHERE rewards_id = ? AND rewards_status = ?',
            [reward_id, 'active']
        )
        if (!reward) { await conn.rollback(); return fail(res, 'ไม่พบของรางวัลหรือถูกปิดใช้งาน', null, 404) }

        // ─── ตรวจสอบ stock ─────────────────────────────────────────────
        if (reward.rewards_stock !== null && reward.rewards_stock <= 0) {
            await conn.rollback()
            return fail(res, 'ของรางวัลหมดแล้ว')
        }

        // ─── ตรวจสอบแต้ม ───────────────────────────────────────────────
        const currentBalance = Number(customer.customers_point) || 0
        const cost           = Number(reward.rewards_points_cost)

        if (currentBalance < cost) {
            await conn.rollback()
            return fail(res, `แต้มไม่พอ — มี ${currentBalance} แต้ม ต้องการ ${cost} แต้ม`)
        }

        // ─── INSERT point_transaction ──────────────────────────────────
        const pointTxId = generateId()
        await conn.execute(
            `INSERT INTO tb_point_transactions
             (point_transactions_id, point_transactions_customer_id,
              point_transactions_delta, point_transactions_type, point_transactions_note)
             VALUES (?, ?, ?, 'redeem', ?)`,
            [pointTxId, customer.customers_id, -cost, `แลก: ${reward.rewards_name}`]
        )

        // ─── UPDATE แต้มสุทธิใน tb_customers ──────────────────────────
        await conn.execute(
            'UPDATE tb_customers SET customers_point = customers_point - ? WHERE customers_id = ?',
            [cost, customer.customers_id]
        )

        // ─── INSERT tb_reward_redemptions ──────────────────────────────
        await conn.execute(
            `INSERT INTO tb_reward_redemptions
             (reward_redemptions_id, reward_redemptions_customer_id,
              reward_redemptions_reward_id, reward_redemptions_points_used,
              reward_redemptions_reward_type, reward_redemptions_discount_value,
              reward_redemptions_free_seconds, reward_redemptions_point_tx_id)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
            [
                generateId(),
                customer.customers_id,
                reward.rewards_id,
                cost,
                reward.rewards_type,
                reward.rewards_discount_value || null,
                reward.rewards_free_seconds   || null,
                pointTxId,
            ]
        )

        // ─── ลด stock (ถ้ามี) ──────────────────────────────────────────
        if (reward.rewards_stock !== null) {
            await conn.execute(
                'UPDATE tb_rewards SET rewards_stock = rewards_stock - 1 WHERE rewards_id = ?',
                [reward.rewards_id]
            )
        }

        await conn.commit()

        ok(res, {
            customer_id:  customer.customers_id,
            reward_id:    reward.rewards_id,
            reward_name:  reward.rewards_name,
            reward_type:  reward.rewards_type,
            points_used:  cost,
            new_balance:  currentBalance - cost,
            free_seconds: reward.rewards_free_seconds || null,
        }, `แลก "${reward.rewards_name}" สำเร็จ`)

    } catch (err) {
        await conn.rollback()
        next(err)
    } finally {
        conn.release()
    }
}

module.exports = { redeemReward }
