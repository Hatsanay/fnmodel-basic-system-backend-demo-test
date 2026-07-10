// helpers สำหรับอัปเดต tb_daily_report (id=1)
// ใช้ IF() แทนการ interpolate ชื่อ column เพื่อความปลอดภัย

const addTableStats = async (conn, { cls, incomeAmt, elapsed }) => {
    await conn.execute(`
        UPDATE tb_tb_daily_report SET
          total_clients = total_clients + 1,
          count_a       = count_a  + IF(? = 'A', 1, 0),
          count_b       = count_b  + IF(? = 'B', 1, 0),
          count_c       = count_c  + IF(? = 'C', 1, 0),
          income_a      = income_a + IF(? = 'A', ?, 0),
          income_b      = income_b + IF(? = 'B', ?, 0),
          income_c      = income_c + IF(? = 'C', ?, 0),
          total_time_ms = total_time_ms + ?
        WHERE report_id = 1`,
        [cls, cls, cls, cls, incomeAmt, cls, incomeAmt, cls, incomeAmt, elapsed]
    )
}

const addPayment = async (conn, { paidAmt, payType }) => {
    await conn.execute(`
        UPDATE tb_daily_report SET
          grand_total    = grand_total + ?,
          cash_total     = cash_total     + IF(? = 'cash',     ?, 0),
          transfer_total = transfer_total + IF(? = 'transfer', ?, 0)
        WHERE report_id = 1`,
        [paidAmt, payType, paidAmt, payType, paidAmt]
    )
}

const removeTableStats = async (conn, { cls, incomeAmt, elapsed }) => {
    await conn.execute(`
        UPDATE tb_daily_report SET
          total_clients = GREATEST(0, total_clients - 1),
          count_a       = GREATEST(0, count_a  - IF(? = 'A', 1, 0)),
          count_b       = GREATEST(0, count_b  - IF(? = 'B', 1, 0)),
          count_c       = GREATEST(0, count_c  - IF(? = 'C', 1, 0)),
          income_a      = GREATEST(0, income_a - IF(? = 'A', ?, 0)),
          income_b      = GREATEST(0, income_b - IF(? = 'B', ?, 0)),
          income_c      = GREATEST(0, income_c - IF(? = 'C', ?, 0)),
          total_time_ms = GREATEST(0, total_time_ms - ?)
        WHERE report_id = 1`,
        [cls, cls, cls, cls, incomeAmt, cls, incomeAmt, cls, incomeAmt, elapsed]
    )
}

const removePayment = async (conn, { paidAmt, payType }) => {
    await conn.execute(`
        UPDATE tb_daily_report SET
          grand_total    = GREATEST(0, grand_total - ?),
          cash_total     = GREATEST(0, cash_total     - IF(? = 'cash',     ?, 0)),
          transfer_total = GREATEST(0, transfer_total - IF(? = 'transfer', ?, 0))
        WHERE report_id = 1`,
        [paidAmt, payType, paidAmt, payType, paidAmt]
    )
}

module.exports = { addTableStats, addPayment, removeTableStats, removePayment }
