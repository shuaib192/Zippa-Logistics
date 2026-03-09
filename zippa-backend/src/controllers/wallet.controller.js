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
                         virtual_account_name = $3 
                         WHERE user_id = $4`,
                        [wallet.virtual_account_number, wallet.virtual_bank_name, wallet.virtual_account_name, req.user.id]
                    );
                }
            } catch (pErr) {
                console.error('Paystack Auto-Generation Error:', pErr.message);
                // Special handling for Test accounts or unverified businesses
                if (pErr.message.includes('not available')) {
                    wallet.virtual_account_error = 'Dedicated NUBAN not enabled for this Paystack account.';
                }
                // Continue without virtual account info, user can try later
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
 * Fund wallet (Simulated)
 * POST /api/wallet/fund
 */
const fundWallet = async (req, res) => {
    const { amount } = req.body;
    
    if (!amount || amount <= 0) {
        return res.status(400).json({ success: false, message: 'Invalid amount.' });
    }

    const client = await db.connect();
    try {
        await client.query('BEGIN');

        // 1. Get wallet
        let walletRes = await client.query('SELECT id, balance FROM wallets WHERE user_id = $1', [req.user.id]);
        
        let walletId;
        if (walletRes.rows.length === 0) {
            const newW = await client.query('INSERT INTO wallets (user_id, balance) VALUES ($1, 0) RETURNING id', [req.user.id]);
            walletId = newW.rows[0].id;
        } else {
            walletId = walletRes.rows[0].id;
        }

        // 2. Update balance
        await client.query(
            'UPDATE wallets SET balance = balance + $1, updated_at = NOW() WHERE id = $2',
            [amount, walletId]
        );

        // 3. Record transaction
        await client.query(
            `INSERT INTO wallet_transactions (wallet_id, type, amount, description, status) 
             VALUES ($1, 'credit', $2, 'Wallet funding', 'completed')`,
            [walletId, amount]
        );

        await client.query('COMMIT');
        
        const finalBalance = await client.query('SELECT balance FROM wallets WHERE id = $1', [walletId]);

        res.status(200).json({ 
            success: true, 
            message: `Successfully funded wallet with N${amount}`,
            balance: finalBalance.rows[0].balance
        });

    } catch (err) {
        await client.query('ROLLBACK');
        console.error('Fund wallet error:', err);
        res.status(500).json({ success: false, message: 'Funding failed. Please try again.' });
    } finally {
        client.release();
    }
};

module.exports = {
    getBalance,
    getTransactions,
    fundWallet
};
