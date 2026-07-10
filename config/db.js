const mysql = require('mysql2/promise')

const pool = mysql.createPool({
    host:             process.env.DB_HOST     || 'localhost',
    user:             process.env.DB_USER     || 'root',
    password:         process.env.DB_PASSWORD || '',
    database:         process.env.DB_NAME     || `db_fnmodel`,
    waitForConnections: true,
    connectionLimit:  10,
    timezone:         '+07:00'
})

// ตั้ง session timezone ทุก connection → MySQL NOW() / CURRENT_TIMESTAMP ใช้ UTC+7
pool.pool.on('connection', (conn) => {
    conn.query("SET time_zone = '+07:00'")
})

module.exports = pool
