const express = require('express');
const router = express.Router();
const { authenticate, authorize } = require('../middleware/auth.middleware');
const { 
    getMyProducts, 
    addProduct, 
    updateProduct, 
    deleteProduct 
} = require('../controllers/product.controller');

// All product routes require authentication and vendor role
router.use(authenticate);
router.use(authorize('vendor', 'admin'));

router.get('/my-products', getMyProducts);
router.post('/', addProduct);
router.put('/:id', updateProduct);
router.delete('/:id', deleteProduct);

module.exports = router;
