const crypto = require('crypto');
const db = require('../config/database');

/**
 * Paystack Webhook Controller
 * Handles real-time notifications from Paystack
 */
const handleWebhook = async (req, res) => {
    try {
        // 1. Verify Signature
        const secret = process.env.PAYSTACK_SECRET_KEY;
        const hash = crypto.createHmac('sha512', secret).update(JSON.stringify(req.body)).digest('hex');
        
        if (hash !== req.headers['x-paystack-signature']) {
          console.error('INVALID WEBHOOK SIGNATURE');
          return res.sendStatus(400);
        }

        const event = req.body;
        console.log('Paystack Webhook Event Received:', event.event);

        // 2. Handle Events
        if (event.event === 'charge.success') {
            const data = event.data;
            
            // Dedicated Virtual Account (NUBAN) payments
            if (data.channel === 'dedicated_nuban' || data.authorization.channel === 'dedicated_nuban') {
                const amountKobo = data.amount;
                const amountNaira = amountKobo / 100;
                const customerCode = data.customer.customer_code;
                const reference = data.reference;

                console.log(`Processing DVA funding for ${customerCode}: N${amountNaira}`);

                // Find the wallet tied to this customer
                const walletRes = await db.query(
                    'SELECT id, user_id FROM wallets WHERE paystack_customer_code = $1',
                    [customerCode]
                );

                if (walletRes.rows.length > 0) {
                    const wallet = walletRes.rows[0];
                    const client = await db.pool.connect();
                    try {
                        await client.query('BEGIN');

                        // Check if transaction already processed (idempotency)
                        const checkTxn = await client.query(
                            'SELECT id FROM wallet_transactions WHERE reference = $1',
                            [reference]
                        );

                        if (checkTxn.rows.length === 0) {
                            // Update balance
                            await client.query(
                                'UPDATE wallets SET balance = balance + $1, updated_at = NOW() WHERE id = $2',
                                [amountNaira, wallet.id]
                            );

                            // Record transaction
                            await client.query(
                                `INSERT INTO wallet_transactions (wallet_id, type, amount, reference, description, status) 
                                 VALUES ($1, 'credit', $2, $3, $4, 'completed')`,
                                [wallet.id, amountNaira, reference, `Bank Transfer Funding via ${data.authorization.bank || 'NUBAN'}`, 'completed']
                            );

                            await client.query('COMMIT');
                            console.log(`✅ Wallet ${wallet.id} successfully funded with N${amountNaira}`);
                        } else {
                            console.log(`ℹ️ Transaction ${reference} already processed.`);
                        }
                    } catch (err) {
                        await client.query('ROLLBACK');
                        throw err;
                    } finally {
                        client.release();
                    }
                }
            }
        }

        // Always return 200 OK to Paystack
        res.sendStatus(200);
    } catch (err) {
        console.error('Webhook processing error:', err);
        res.sendStatus(500);
    }
};

module.exports = {
    handleWebhook
};
