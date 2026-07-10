require('dotenv').config()
const app  = require('./app')
const pool = require('./config/db')
const { initIdCounter } = require('./utils/id')

const PORT   = process.env.PORT    || 3000
const DB     = process.env.DB_NAME || ''
const HOST   = process.env.DB_HOST || ''

pool.getConnection()
    .then(async conn => {
        conn.release()
        console.log(`✔ DB connected  → ${HOST}/${DB}`)
        await initIdCounter(pool)
        app.listen(PORT, () => {
            console.log(`✔ Server ready  → http://localhost:${PORT}/api`)
        })
    })
    .catch(err => {
        console.error(`✘ DB connection failed: ${err.message}`)
        process.exit(1)
    })
