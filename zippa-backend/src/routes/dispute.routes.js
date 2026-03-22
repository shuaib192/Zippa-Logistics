const express = require('express');
const router = express.Router();
const disputeController = require('../controllers/dispute.controller');
const { authenticate } = require('../middleware/auth.middleware');

router.use(authenticate);

router.post('/', disputeController.createDispute);
router.get('/', disputeController.getMyDisputes);
router.get('/:id', disputeController.getDisputeById);

module.exports = router;
