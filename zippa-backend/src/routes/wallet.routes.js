const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth.middleware');
const { getBalance, getTransactions, fundWallet } = require('../controllers/wallet.controller');

// All wallet routes require authentication
router.use(authenticate);

router.get('/balance', getBalance);
router.get('/transactions', getTransactions);
router.post('/fund', fundWallet);

module.exports = router;
