const logger = (req, res, next) => {
    const start = Date.now()

    res.on('finish', () => {
        const ms = Date.now() - start
        const body = Object.keys(req.body || {}).length
            ? `\n  body: ${JSON.stringify(req.body)}`
            : ''
        console.log(`[${new Date().toISOString()}] ${req.method} ${req.originalUrl} → ${res.statusCode} (${ms}ms)${body}`)
    })

    next()
}

module.exports = { logger }
