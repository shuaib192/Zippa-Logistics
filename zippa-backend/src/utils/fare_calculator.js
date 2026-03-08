/**
 * FARE CALCULATOR (fare_calculator.js)
 * Shared logic for calculating delivery prices.
 */

const BASE_FARE = 500;   // Starting price
const PER_KM = 150;     // Price per kilometer

const sizeMultipliers = {
    small: 1.0,
    medium: 1.2,
    large: 1.5,
    extra_large: 2.0,
};

const calculateFare = (distanceKm, packageSize = 'small') => {
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
