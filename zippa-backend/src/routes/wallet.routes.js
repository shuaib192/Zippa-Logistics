const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth.middleware');
const { getBalance, getTransactions, fundWallet, refreshBalance, withdraw } = require('../controllers/wallet.controller');

// All wallet routes require authentication
router.use(authenticate);

router.get('/balance', getBalance);
router.get('/transactions', getTransactions);
router.post('/fund', fundWallet);
router.post('/refresh', refreshBalance);
router.post('/withdraw', withdraw);

module.exports = router;
