const pool         = require('../../config/db')
const { ok, fail } = require('../../utils/response')

// GET /api/v1/rewards
const getRewards = async (req, res, next) => {
    try {
        const [rows] = await pool.execute(
            `SELECT rewards_id, rewards_name, rewards_type,
                    rewards_points_cost, rewards_discount_value,
                    rewards_stock, rewards_free_seconds, rewards_status
             FROM tb_rewards
             WHERE rewards_status = 'active'
             ORDER BY rewards_points_cost ASC`
        )
        ok(res, rows)
    } catch (err) {
        next(err)
    }
}

module.exports = { getRewards }
