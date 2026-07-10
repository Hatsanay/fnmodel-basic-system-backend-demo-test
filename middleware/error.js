const { fail } = require('../utils/response')

const errorHandler = (err, req, res, next) => {
    const status = err.status || 500
    console.error(`✘ [${status}] ${err.message}`)
    if (err.sql) console.error(`  SQL: ${err.sql}`)
    fail(res, err.message || 'Internal server error', null, status)
}

module.exports = { errorHandler }
