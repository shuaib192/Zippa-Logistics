// ============================================
// 🎓 USER CONTROLLER (user.controller.js)
//
// Handles user profile management:
// - getProfile: View your profile
// - updateProfile: Edit your details
// - changePassword: Update your password
// ============================================

const bcrypt = require('bcryptjs');
const db = require('../config/database');

// ============================================
// CONTROLLER: getProfile
// GET /api/users/profile
// Returns the logged-in user's full profile.
// ============================================
const getProfile = async (req, res) => {
    try {
        // req.user was set by the authenticate middleware
        // It contains the user's ID, so we can look up their full data
        const result = await db.query(
            `SELECT u.id, u.email, u.phone, u.full_name, u.role, u.secondary_role,
              u.kyc_status, u.avatar_url, u.is_online, u.created_at,
              p.date_of_birth, p.gender, p.address, p.city, p.state,
              p.vehicle_type, p.vehicle_plate, p.guarantor_name, p.guarantor_phone,
              p.business_name, p.business_address, p.business_reg_number,
              p.default_pickup_address,
              w.balance as wallet_balance
       FROM users u
       LEFT JOIN user_profiles p ON p.user_id = u.id
       LEFT JOIN wallets w ON w.user_id = u.id
       WHERE u.id = $1`,
            [req.user.id]
        );
        // LEFT JOIN = get data from related tables
        // Even if user doesn't have a profile yet, we still get user data
        // (unlike INNER JOIN which would return nothing)

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Profile not found.',
            });
        }

        const profile = result.rows[0];

        res.status(200).json({
            success: true,
            data: {
                id: profile.id,
                email: profile.email,
                phone: profile.phone,
                fullName: profile.full_name,
                role: profile.role,
                secondaryRole: profile.secondary_role,
                kycStatus: profile.kyc_status,
                avatarUrl: profile.avatar_url,
                isOnline: profile.is_online,
                walletBalance: profile.wallet_balance,
                profile: {
                    dateOfBirth: profile.date_of_birth,
                    gender: profile.gender,
                    address: profile.address,
                    city: profile.city,
                    state: profile.state,
                    // Rider-specific
                    vehicleType: profile.vehicle_type,
                    vehiclePlate: profile.vehicle_plate,
                    guarantorName: profile.guarantor_name,
                    guarantorPhone: profile.guarantor_phone,
                    // Vendor-specific
                    businessName: profile.business_name,
                    businessAddress: profile.business_address,
                    businessRegNumber: profile.business_reg_number,
                    defaultPickupAddress: profile.default_pickup_address,
                },
                memberSince: profile.created_at,
            },
        });

    } catch (err) {
        console.error('Get profile error:', err);
        res.status(500).json({
            success: false,
            message: 'Failed to retrieve profile.',
        });
    }
};

// ============================================
// CONTROLLER: updateProfile
// PUT /api/users/profile
// Updates the user's profile information.
// ============================================
const updateProfile = async (req, res) => {
    try {
        const {
            fullName, email, avatarUrl,
            dateOfBirth, gender, address, city, state,
            vehicleType, vehiclePlate, guarantorName, guarantorPhone,
            businessName, businessAddress, businessRegNumber, defaultPickupAddress,
        } = req.body;

        // Update user table fields
        if (fullName || email || avatarUrl) {
            const updates = [];
            const values = [];
            let paramCount = 1;

            // Dynamic query building — only update provided fields
            // This prevents overwriting fields the user didn't send
            if (fullName) {
                updates.push(`full_name = $${paramCount++}`);
                values.push(fullName);
            }
            if (email) {
                updates.push(`email = $${paramCount++}`);
                values.push(email);
            }
            if (avatarUrl) {
                updates.push(`avatar_url = $${paramCount++}`);
                values.push(avatarUrl);
            }

            updates.push('updated_at = CURRENT_TIMESTAMP');
            values.push(req.user.id);

            await db.query(
                `UPDATE users SET ${updates.join(', ')} WHERE id = $${paramCount}`,
                values
            );
        }

        // Update profile table fields
        const profileUpdates = [];
        const profileValues = [];
        let pCount = 1;

        const profileFields = {
            date_of_birth: dateOfBirth,
            gender, address, city, state,
            vehicle_type: vehicleType,
            vehicle_plate: vehiclePlate,
            guarantor_name: guarantorName,
            guarantor_phone: guarantorPhone,
            business_name: businessName,
            business_address: businessAddress,
            business_reg_number: businessRegNumber,
            default_pickup_address: defaultPickupAddress,
        };

        for (const [key, value] of Object.entries(profileFields)) {
            if (value !== undefined) {
                profileUpdates.push(`${key} = $${pCount++}`);
                profileValues.push(value);
            }
        }

        if (profileUpdates.length > 0) {
            profileUpdates.push('updated_at = CURRENT_TIMESTAMP');
            profileValues.push(req.user.id);

            await db.query(
                `UPDATE user_profiles SET ${profileUpdates.join(', ')} WHERE user_id = $${pCount}`,
                profileValues
            );
        }

        res.status(200).json({
            success: true,
            message: 'Profile updated successfully.',
        });

    } catch (err) {
        console.error('Update profile error:', err);
        res.status(500).json({
            success: false,
            message: 'Failed to update profile.',
        });
    }
};

// ============================================
// CONTROLLER: changePassword
// PUT /api/users/change-password
// ============================================
const changePassword = async (req, res) => {
    try {
        const { currentPassword, newPassword } = req.body;

        if (!currentPassword || !newPassword) {
            return res.status(400).json({
                success: false,
                message: 'Current password and new password are required.',
            });
        }

        if (newPassword.length < 8) {
            return res.status(400).json({
                success: false,
                message: 'New password must be at least 8 characters.',
            });
        }

        // Get current password hash
        const result = await db.query(
            'SELECT password_hash FROM users WHERE id = $1',
            [req.user.id]
        );

        // Verify current password
        const isValid = await bcrypt.compare(currentPassword, result.rows[0].password_hash);
        if (!isValid) {
            return res.status(401).json({
                success: false,
                message: 'Current password is incorrect.',
            });
        }

        // Hash and save new password
        const newHash = await bcrypt.hash(newPassword, 12);
        await db.query(
            'UPDATE users SET password_hash = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2',
            [newHash, req.user.id]
        );

        res.status(200).json({
            success: true,
            message: 'Password changed successfully.',
        });

    } catch (err) {
        console.error('Change password error:', err);
        res.status(500).json({
            success: false,
            message: 'Failed to change password.',
        });
    }
};

module.exports = { getProfile, updateProfile, changePassword };
