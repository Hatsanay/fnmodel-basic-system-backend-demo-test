const ok = (res, data = null, message = 'ok', statusCode = 200) =>
    res.status(statusCode).json({ success: true, data, message, error: null })

const fail = (res, message = 'เกิดข้อผิดพลาด', error = null, statusCode = 400) =>
    res.status(statusCode).json({ success: false, data: null, message, error })

module.exports = { ok, fail }
