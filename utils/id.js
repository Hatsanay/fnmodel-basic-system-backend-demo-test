let _seqDate = ''
let _seqLast = 0

const generateId = () => {
    const today = new Date()
    const dd   = String(today.getDate()).padStart(2, '0')
    const mm   = String(today.getMonth() + 1).padStart(2, '0')
    const yyyy = today.getFullYear()
    const dateKey = `${dd}${mm}${yyyy}`

    if (_seqDate !== dateKey) { _seqDate = dateKey; _seqLast = 0 }
    _seqLast++

    return `${dateKey}${String(_seqLast).padStart(7, '0')}`
}

// เรียกครั้งเดียวตอน server เริ่ม — ดึง max running number วันนี้จาก DB
// เพื่อไม่ให้ counter ชนกับ record เก่าหลัง restart
const initIdCounter = async (pool) => {
    const today = new Date()
    const dd   = String(today.getDate()).padStart(2, '0')
    const mm   = String(today.getMonth() + 1).padStart(2, '0')
    const yyyy = today.getFullYear()
    const prefix = `${dd}${mm}${yyyy}`

    const [[{ max_seq }]] = await pool.execute(
        `SELECT MAX(CAST(SUBSTRING(id, 9) AS UNSIGNED)) AS max_seq FROM (
            SELECT CONVERT(point_transactions_id  USING utf8mb4) AS id FROM tb_point_transactions  WHERE point_transactions_id     LIKE ?
            UNION ALL
            SELECT CONVERT(customers_id           USING utf8mb4) AS id FROM tb_customers            WHERE customers_id              LIKE ?
            UNION ALL
            SELECT CONVERT(reward_redemptions_id  USING utf8mb4) AS id FROM tb_reward_redemptions   WHERE reward_redemptions_id     LIKE ?
            UNION ALL
            SELECT CONVERT(package_id             USING utf8mb4) AS id FROM tb_countdown_packages   WHERE package_id                LIKE ?
         ) t`,
        [`${prefix}%`, `${prefix}%`, `${prefix}%`, `${prefix}%`]
    )

    _seqDate = prefix
    _seqLast = Number(max_seq) || 0
    console.log(`✔ ID counter initialized → ${prefix} (last: ${_seqLast})`)
}

module.exports = { generateId, initIdCounter }
