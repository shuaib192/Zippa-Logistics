const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth.middleware');
const { 
    getAllCategories, 
    searchVendors, 
    getFeaturedVendors, 
    getVendorDetails,
    toggleFavorite,
    getFavorites,
    searchProducts
} = require('../controllers/vendor.controller');

// Public/Customer routes
router.get('/categories', getAllCategories);
router.get('/search', searchVendors);
router.get('/featured', getFeaturedVendors);
router.get('/search-products', searchProducts);
router.post('/favorites', authenticate, toggleFavorite);
router.get('/favorites/list', authenticate, getFavorites);
router.get('/:id', getVendorDetails);

module.exports = router;
