const express = require('express')
const cors = require('cors')

const routes = require('./routes/index')
const { errorHandler } = require('./middleware/error')
const { logger } = require('./middleware/logger')

const app = express()

app.use(cors())
app.use(express.json())
app.use(logger)

app.use('/api', routes)

app.use(errorHandler)

module.exports = app
