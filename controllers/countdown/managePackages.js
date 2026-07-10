const pool = require('../../config/db')
const { generateId } = require('../../utils/id')
const { ok, fail } = require('../../utils/response')

const getAllPackages = async (req, res, next) => {
    try {
        const [rows] = await pool.execute(
            `SELECT * FROM tb_countdown_packages ORDER BY package_class, package_seconds`
        )
        ok(res, rows)
    } catch (err) { next(err) }
}

const createPackage = async (req, res, next) => {
    const { package_class, package_seconds, package_price, package_alert_seconds } = req.body
    if (!package_class || !package_seconds || package_price == null)
        return fail(res, 'ข้อมูลไม่ครบ (class, seconds, price จำเป็น)')
    try {
        const id = generateId()
        await pool.execute(
            `INSERT INTO tb_countdown_packages (package_id, package_class, package_seconds, package_price, package_alert_seconds)
             VALUES (?, ?, ?, ?, ?)`,
            [id, package_class, Number(package_seconds), Number(package_price), Number(package_alert_seconds) || 120]
        )
        ok(res, { package_id: id }, 'สร้าง package สำเร็จ')
    } catch (err) { next(err) }
}

const updatePackage = async (req, res, next) => {
    const { id } = req.params
    const { package_class, package_seconds, package_price, package_alert_seconds, package_status } = req.body
    try {
        await pool.execute(
            `UPDATE tb_countdown_packages SET
             package_class         = COALESCE(?, package_class),
             package_seconds       = COALESCE(?, package_seconds),
             package_price         = COALESCE(?, package_price),
             package_alert_seconds = COALESCE(?, package_alert_seconds),
             package_status        = COALESCE(?, package_status)
             WHERE package_id = ?`,
            [
                package_class  || null,
                package_seconds != null ? Number(package_seconds) : null,
                package_price   != null ? Number(package_price)   : null,
                package_alert_seconds != null ? Number(package_alert_seconds) : null,
                package_status || null,
                id
            ]
        )
        ok(res, null, 'อัพเดต package สำเร็จ')
    } catch (err) { next(err) }
}

const deletePackage = async (req, res, next) => {
    const { id } = req.params
    try {
        await pool.execute(`DELETE FROM tb_countdown_packages WHERE package_id = ?`, [id])
        ok(res, null, 'ลบ package สำเร็จ')
    } catch (err) { next(err) }
}

module.exports = { getAllPackages, createPackage, updatePackage, deletePackage }
