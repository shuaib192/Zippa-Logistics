const db = require('../config/database');

/**
 * LANDMARK SERVICE (landmark.service.js)
 * Helps AI identify non-standard addresses (the "Cheat Code")
 */

const findLandmark = async (userId, searchTerm) => {
    try {
        if (!userId) return null;

        const result = await db.query(
            'SELECT * FROM user_landmarks WHERE user_id = $1 AND (name ILIKE $2 OR description ILIKE $2)',
            [userId, `%${searchTerm}%`]
        );

        return result.rows.length > 0 ? result.rows[0] : null;
    } catch (err) {
        console.error('Find Landmark Error:', err);
        return null;
    }
};

const saveLandmark = async (userId, name, address, description, lat, lng) => {
    try {
        const result = await db.query(
            `INSERT INTO user_landmarks (user_id, name, address, description, latitude, longitude)
             VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
            [userId, name, address, description, lat, lng]
        );
        return result.rows[0];
    } catch (err) {
        console.error('Save Landmark Error:', err);
    }
};

module.exports = {
    findLandmark,
    saveLandmark
};
