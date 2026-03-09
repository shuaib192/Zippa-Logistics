const db = require('../config/database');
const PaystackService = require('../services/paystack.service');

/**
 * Get current user's wallet balance
 * GET /api/wallet/balance
 */
const getBalance = async (req, res) => {
    try {
        const { id: userId, role } = req.user;
        
        const result = await db.query(
            `SELECT w.*, u.email, u.full_name, u.phone 
             FROM wallets w 
             JOIN users u ON u.id = w.user_id 
             WHERE w.user_id = $1`,
            [req.user.id]
        );

        let wallet;
        if (result.rows.length === 0) {
            // Create wallet if it doesn't exist
            const newW = await db.query(
                'INSERT INTO wallets (user_id, balance) VALUES ($1, 0) RETURNING *',
                [req.user.id]
            );
            wallet = newW.rows[0];
            // Fetch user info for Paystack
            const userRes = await db.query('SELECT email, full_name, phone FROM users WHERE id = $1', [req.user.id]);
            wallet = { ...wallet, ...userRes.rows[0] };
        } else {
            wallet = result.rows[0];
        }

        // Check if we need to generate Paystack details (ONLY for customers)
        if (!wallet.virtual_account_number && role === 'customer' && wallet.email) {
            try {
                // 1. Create/Fetch Paystack Customer
                if (!wallet.paystack_customer_code) {
                    const fullName = wallet.full_name || 'Zippa User';
                    const customer = await PaystackService.createCustomer(wallet.email, fullName, wallet.phone || '');
                    wallet.paystack_customer_code = customer.data.customer_code;
                    await db.query('UPDATE wallets SET paystack_customer_code = $1 WHERE user_id = $2', [wallet.paystack_customer_code, req.user.id]);
                }

                // 2. Create Dedicated Virtual Account
                const account = await PaystackService.createDedicatedAccount(wallet.paystack_customer_code);
                if (account.success && account.data) {
                    const accData = account.data;
                    wallet.virtual_account_number = accData.account_number;
                    wallet.virtual_bank_name = accData.bank.name;
                    wallet.virtual_account_name = accData.account_name;

                    await db.query(
                        `UPDATE wallets SET 
                         virtual_account_number = $1, 
                         virtual_bank_name = $2, 
                         virtual_account_name = $3,
                         virtual_account_error = NULL
                         WHERE user_id = $4`,
                        [wallet.virtual_account_number, wallet.virtual_bank_name, wallet.virtual_account_name, req.user.id]
                    );
                } else {
                    wallet.virtual_account_error = account.message || 'Failed to generate virtual account details.';
                    await db.query('UPDATE wallets SET virtual_account_error = $1 WHERE user_id = $2', [wallet.virtual_account_error, req.user.id]);
                }
            } catch (pErr) {
                const errorDetail = pErr.response?.data?.message || pErr.message;
                console.error('Paystack Auto-Generation Fatal Error:', errorDetail);
                wallet.virtual_account_error = `System error: ${errorDetail}`;
                await db.query('UPDATE wallets SET virtual_account_error = $1 WHERE user_id = $2', [wallet.virtual_account_error, req.user.id]);
            }
        }
        
        // 3. For Riders, calculate Today's Summary
        let summary = {
            today_earnings: 0,
            today_deliveries: 0,
            rating: 5.0 // Placeholder for now
        };

        if (role === 'rider') {
            const riderSummary = await db.query(
                `SELECT 
                    COALESCE(SUM(rider_earning), 0) as earnings,
                    COUNT(*) as deliveries
                 FROM orders 
                 WHERE rider_id = $1 
                 AND status = 'delivered'
                 AND created_at >= CURRENT_DATE`,
                [userId]
            );
            summary.today_earnings = parseFloat(riderSummary.rows[0].earnings);
            summary.today_deliveries = parseInt(riderSummary.rows[0].deliveries);
        }

        res.status(200).json({ 
            success: true, 
            balance: wallet.balance,
            virtual_account: wallet.virtual_account_number ? {
                account_number: wallet.virtual_account_number,
                bank_name: wallet.virtual_bank_name,
                account_name: wallet.virtual_account_name
            } : null,
            virtual_account_message: wallet.virtual_account_error || null,
            summary: summary
        });
    } catch (err) {
        console.error('Get balance error:', err);
        res.status(500).json({ success: false, message: 'Failed to fetch wallet information.' });
    }
};

/**
 * Get wallet transaction history
 * GET /api/wallet/transactions
 */
const getTransactions = async (req, res) => {
    try {
        const result = await db.query(
            `SELECT wt.* FROM wallet_transactions wt
             JOIN wallets w ON wt.wallet_id = w.id
             WHERE w.user_id = $1
             ORDER BY wt.created_at DESC`,
            [req.user.id]
        );

        res.status(200).json({ success: true, transactions: result.rows });
    } catch (err) {
        console.error('Get transactions error:', err);
        res.status(500).json({ success: false, message: 'Failed to fetch transaction history.' });
    }
};

/**
 * Fund wallet (Paystack Initialization)
 * POST /api/wallet/fund
 */
const fundWallet = async (req, res) => {
    try {
        const { amount } = req.body;
        const { id: userId, email } = req.user;
        
        if (!amount || amount < 100) {
            return res.status(400).json({ success: false, message: 'Minimum funding amount is N100.' });
        }

        // 1. Initialize Transaction on Paystack
        const metadata = {
            user_id: userId,
            type: 'wallet_funding',
            custom_fields: [
                { display_name: "Action", variable_name: "action", value: "fund_wallet" },
                { display_name: "User ID", variable_name: "user_id", value: userId }
            ]
        };

        const result = await PaystackService.initializeTransaction(email, amount, metadata);

        // 2. Return Access Code and Auth URL to Frontend
        res.status(200).json({ 
            success: true, 
            message: 'Transaction initialized.',
            data: {
                authorization_url: result.data.authorization_url,
                access_code: result.data.access_code,
                reference: result.data.reference
            }
        });

    } catch (err) {
        console.error('Fund wallet initialization error:', err);
        res.status(500).json({ success: false, message: err.message || 'Failed to initialize payment.' });
    }
};

/**
 * Refresh wallet balance (Manual Requery)
 * POST /api/wallet/refresh
 */
const refreshBalance = async (req, res) => {
    try {
        const { id: userId } = req.user;
        
        // 1. Get wallet info
        const result = await db.query(
            'SELECT virtual_account_number, virtual_bank_name FROM wallets WHERE user_id = $1',
            [userId]
        );

        if (result.rows.length === 0 || !result.rows[0].virtual_account_number) {
            return res.status(400).json({ success: false, message: 'No virtual account found to refresh.' });
        }

        const wallet = result.rows[0];
        // We need the provider slug. Wema is usually 'wema-bank'.
        const providerSlug = 'wema-bank'; 

        // 2. Trigger Paystack Requery
        // This triggers the charge.success webhook if any new payments are found
        const requery = await PaystackService.requeryDedicatedAccount(
            wallet.virtual_account_number,
            providerSlug
        );

        res.status(200).json({ 
            success: true, 
            message: 'Refresh requested. If new payments are found, your balance will update in a few moments.',
            requery: requery
        });
    } catch (err) {
        console.error('Refresh balance error:', err);
        res.status(500).json({ success: false, message: 'Failed to refresh balance.' });
    }
};

module.exports = {
    getBalance,
    getTransactions,
    fundWallet,
    refreshBalance
};
