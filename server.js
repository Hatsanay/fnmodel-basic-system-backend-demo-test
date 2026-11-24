require('dotenv').config()
const app  = require('./app')
const pool = require('./config/db')
const { initIdCounter } = require('./utils/id')

const PORT   = process.env.PORT    || 3000
const DB     = process.env.DB_NAME || ''
const HOST   = process.env.DB_HOST || ''
const DB_RETRY_MS = 30000

// สถานะ DB ให้ GET /api/v1/health อ่าน
// แอปเปิดขึ้นเสมอแม้ต่อ DB ไม่ได้ → /health บอกรหัส error ได้ (แทนที่จะตายเงียบเป็น 503)
// เก็บแค่ err.code (เช่น ER_ACCESS_DENIED_ERROR) ไม่เก็บข้อความเต็ม กันข้อมูล DB หลุด
app.locals.dbStatus = { ok: false, error: 'STARTING' }

const connectDb = async () => {
    try {
        const conn = await pool.getConnection()
        conn.release()
        console.log(`✔ DB connected  → ${HOST}/${DB}`)
        await initIdCounter(pool)          // ต้องสำเร็จก่อนสร้าง ID ใหม่ ไม่งั้น ID ชนของเดิม
        app.locals.dbStatus = { ok: true, error: null }
    } catch (err) {
        app.locals.dbStatus = { ok: false, error: err.code || 'DB_ERROR' }
        console.error(`✘ DB connection failed: ${err.message} — retry in ${DB_RETRY_MS / 1000}s`)
        setTimeout(connectDb, DB_RETRY_MS)
    }
}

app.listen(PORT, () => {
    console.log(`✔ Server ready  → http://localhost:${PORT}/api`)
})
connectDb()
