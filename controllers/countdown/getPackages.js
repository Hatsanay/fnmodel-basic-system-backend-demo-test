const pool = require('../../config/db')
const { ok } = require('../../utils/response')

const getPackages = async (req, res, next) => {
    try {
        const [rows] = await pool.execute(
            `SELECT * FROM tb_countdown_packages WHERE package_status = 'active' ORDER BY package_vehicle_type, package_class, package_seconds`
        )
        ok(res, rows)
    } catch (err) {
        next(err)
    }
}

module.exports = { getPackages }
