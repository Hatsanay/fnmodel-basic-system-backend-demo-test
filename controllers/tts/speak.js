const https = require('https')

const speak = (req, res, next) => {
    const text = req.query.text
    if (!text) return res.status(400).json({ success: false, message: 'text is required' })

    const url = `https://translate.google.com/translate_tts?ie=UTF-8&q=${encodeURIComponent(text)}&tl=th&client=tw-ob`

    https.get(url, { headers: { 'User-Agent': 'Mozilla/5.0' } }, (stream) => {
        res.setHeader('Content-Type', 'audio/mpeg')
        res.setHeader('Cache-Control', 'no-cache')
        stream.pipe(res)
    }).on('error', next)
}

module.exports = { speak }
