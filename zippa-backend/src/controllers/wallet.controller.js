const db = require('../config/database');

/**
 * Get current user's wallet balance
 * GET /api/wallet/balance
 */
const getBalance = async (req, res) => {
    try {
        const result = await db.query(
            'SELECT balance FROM wallets WHERE user_id = $1',
            [req.user.id]
        );

        if (result.rows.length === 0) {
            // If wallet doesn't exist, create it (safety)
            const newWallet = await db.query(
                'INSERT INTO wallets (user_id, balance) VALUES ($1, 0) RETURNING balance',
                [req.user.id]
            );
            return res.status(200).json({ success: true, balance: newWallet.rows[0].balance });
        }

        res.status(200).json({ success: true, balance: result.rows[0].balance });
    } catch (err) {
        console.error('Get balance error:', err);
        res.status(500).json({ success: false, message: 'Failed to fetch wallet balance.' });
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

    const client = await db.pool.connect();
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
