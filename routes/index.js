const router = require('express').Router()

const { earn }         = require('../controllers/customers/earn')
const { getPoints }    = require('../controllers/customers/getPoints')
const { redeem }       = require('../controllers/customers/redeem')
const { getRewards }                                          = require('../controllers/rewards/getRewards')
const { redeemReward }                                        = require('../controllers/rewards/redeemReward')
const { getAllRewards, createReward, updateReward, deleteReward } = require('../controllers/rewards/manageRewards')
const { speak }                                                                  = require('../controllers/tts/speak')
const { getPackages }                                                            = require('../controllers/countdown/getPackages')
const { getAllPackages, createPackage, updatePackage, deletePackage }             = require('../controllers/countdown/managePackages')

// ─── v1 ───────────────────────────────────────────────────────────────────────
router.post('/v1/customers/earn',    earn)         // find-or-create + บวกแต้ม
router.get('/v1/customers/points',   getPoints)    // ดูแต้ม
router.post('/v1/customers/redeem',  redeem)       // ใช้แต้มแลกส่วนลดราคา

router.get('/v1/rewards',            getRewards)   // รายการของรางวัล (active เท่านั้น)
router.post('/v1/rewards/redeem',    redeemReward) // แลกของรางวัล
router.get('/v1/rewards/all',        getAllRewards) // รายการทั้งหมด (admin)
router.post('/v1/rewards',           createReward) // สร้างรางวัล
router.put('/v1/rewards/:id',        updateReward) // แก้ไขรางวัล
router.delete('/v1/rewards/:id',     deleteReward) // ลบรางวัล

router.get('/v1/countdown/packages',      getPackages)    // แพ็กเกจเหมาเวลา (active เท่านั้น)
router.get('/v1/countdown/packages/all',  getAllPackages)  // ทั้งหมด (admin)
router.post('/v1/countdown/packages',     createPackage)  // สร้าง
router.put('/v1/countdown/packages/:id',  updatePackage)  // แก้ไข
router.delete('/v1/countdown/packages/:id', deletePackage) // ลบ

router.get('/v1/tts',         speak)          // TTS proxy

router.get('/v1/health', (req, res) => {
    const db = req.app.locals.dbStatus || { ok: false, error: 'UNKNOWN' }
    res.status(db.ok ? 200 : 503).json({
        success: db.ok,
        db:      db.ok ? 'ok' : 'error',
        dbError: db.error,
        time:    new Date(),
    })
})
router.get('/v1/testdeploy', (req, res) => res.json({ success: true, message: 'deploy ทำงาน', time: new Date() }))

module.exports = router
