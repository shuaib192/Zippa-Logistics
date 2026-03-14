const pool = require('../config/database');

/**
 * Fetch settings from the database
 */
const getSettings = async () => {
    try {
        const result = await pool.query('SELECT key, value FROM settings');
        const settings = {};
        result.rows.forEach(row => {
            settings[row.key] = parseFloat(row.value);
        });
        return settings;
    } catch (error) {
        console.error('❌ Error fetching settings:', error);
        return { base_fare: 1000, per_km_fare: 250 }; // Fallback
    }
};

const calculateFare = async (distanceKm, packageSize = 'small') => {
    const settings = await getSettings();
    const BASE_FARE = settings.base_fare || 500;
    const PER_KM = settings.per_km_fare || 150;

    const sizeMultipliers = {
        small: 1.0,
        medium: 1.2,
        large: 1.5,
        extra_large: 2.0,
    };

    const multiplier = sizeMultipliers[packageSize] || 1.0;
    const distanceFare = Math.max(0, distanceKm - 1) * PER_KM; // first km already in base
    const rawFare = (BASE_FARE + distanceFare) * multiplier;

    return {
        base_fare: BASE_FARE,
        distance_fare: Math.round(distanceFare),
        subtotal: Math.round(rawFare),
        platform_fee: Math.round(rawFare * 0.10), // 10% platform cut
        total_fare: Math.round(rawFare * 1.10),   // customer pays
        rider_earning: Math.round(rawFare * 0.85), // rider gets 85%
        distance_km: Math.round(distanceKm * 10) / 10,
    };
};

module.exports = {
    calculateFare
};
