const pool           = require('../../config/db')
const { generateId } = require('../../utils/id')
const { ok, fail }   = require('../../utils/response')

// GET /api/v1/rewards/all — ทุก record (สำหรับ admin)
const getAllRewards = async (req, res, next) => {
    try {
        const [rows] = await pool.execute(
            `SELECT rewards_id, rewards_name, rewards_type,
                    rewards_points_cost, rewards_discount_value,
                    rewards_stock, rewards_free_seconds, rewards_status
             FROM tb_rewards
             WHERE rewards_status != 'cancel'
             ORDER BY rewards_points_cost ASC`
        )
        ok(res, rows)
    } catch (err) { next(err) }
}

// POST /api/v1/rewards — สร้างรางวัลใหม่
const createReward = async (req, res, next) => {
    const { rewards_name, rewards_type, rewards_points_cost,
            rewards_discount_value, rewards_stock, rewards_free_seconds } = req.body

    if (!rewards_name)         return fail(res, 'ต้องระบุชื่อรางวัล')
    if (!rewards_type)         return fail(res, 'ต้องระบุประเภทรางวัล')
    if (!rewards_points_cost)  return fail(res, 'ต้องระบุแต้มที่ใช้')

    try {
        const id = generateId()
        await pool.execute(
            `INSERT INTO tb_rewards
             (rewards_id, rewards_name, rewards_type, rewards_points_cost,
              rewards_discount_value, rewards_stock, rewards_free_seconds, rewards_status)
             VALUES (?, ?, ?, ?, ?, ?, ?, 'active')`,
            [
                id,
                rewards_name,
                rewards_type,
                Number(rewards_points_cost),
                rewards_discount_value != null ? Number(rewards_discount_value) : null,
                rewards_stock          != null ? Number(rewards_stock)          : null,
                rewards_free_seconds   != null ? Number(rewards_free_seconds)   : null,
            ]
        )
        const [[reward]] = await pool.execute('SELECT * FROM tb_rewards WHERE rewards_id = ?', [id])
        ok(res, reward, 'สร้างรางวัลสำเร็จ')
    } catch (err) { next(err) }
}

// PUT /api/v1/rewards/:id — แก้ไขรางวัล
const updateReward = async (req, res, next) => {
    const { id } = req.params
    const { rewards_name, rewards_type, rewards_points_cost,
            rewards_discount_value, rewards_stock, rewards_free_seconds, rewards_status } = req.body

    try {
        const [[existing]] = await pool.execute('SELECT rewards_id FROM tb_rewards WHERE rewards_id = ?', [id])
        if (!existing) return fail(res, 'ไม่พบรางวัล', null, 404)

        await pool.execute(
            `UPDATE tb_rewards SET
                rewards_name             = COALESCE(?, rewards_name),
                rewards_type             = COALESCE(?, rewards_type),
                rewards_points_cost      = COALESCE(?, rewards_points_cost),
                rewards_discount_value   = ?,
                rewards_stock            = ?,
                rewards_free_seconds     = ?,
                rewards_status           = COALESCE(?, rewards_status)
             WHERE rewards_id = ?`,
            [
                rewards_name        || null,
                rewards_type        || null,
                rewards_points_cost != null ? Number(rewards_points_cost) : null,
                rewards_discount_value != null ? Number(rewards_discount_value) : null,
                rewards_stock          != null ? Number(rewards_stock)          : null,
                rewards_free_seconds   != null ? Number(rewards_free_seconds)   : null,
                rewards_status      || null,
                id,
            ]
        )
        const [[reward]] = await pool.execute('SELECT * FROM tb_rewards WHERE rewards_id = ?', [id])
        ok(res, reward, 'แก้ไขรางวัลสำเร็จ')
    } catch (err) { next(err) }
}

// DELETE /api/v1/rewards/:id — ลบรางวัล (hard delete ถ้าไม่มี redemption, soft delete ถ้ามี)
const deleteReward = async (req, res, next) => {
    const { id } = req.params
    try {
        const [[existing]] = await pool.execute('SELECT rewards_id FROM tb_rewards WHERE rewards_id = ?', [id])
        if (!existing) return fail(res, 'ไม่พบรางวัล', null, 404)

        const [[{ cnt }]] = await pool.execute(
            'SELECT COUNT(*) AS cnt FROM tb_reward_redemptions WHERE reward_redemptions_reward_id = ?', [id]
        )

        if (cnt > 0) {
            // มี history → soft delete ด้วย cancel (ซ่อนจากตาราง)
            await pool.execute("UPDATE tb_rewards SET rewards_status = 'cancel' WHERE rewards_id = ?", [id])
            ok(res, { soft: true }, 'ยกเลิกรางวัลแล้ว (มีประวัติการแลกจึงไม่ลบข้อมูล)')
        } else {
            await pool.execute('DELETE FROM tb_rewards WHERE rewards_id = ?', [id])
            ok(res, { soft: false }, 'ลบรางวัลสำเร็จ')
        }
    } catch (err) { next(err) }
}

module.exports = { getAllRewards, createReward, updateReward, deleteReward }
