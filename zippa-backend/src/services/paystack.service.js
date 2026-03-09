const axios = require('axios');
require('dotenv').config();

const PAYSTACK_SECRET = process.env.PAYSTACK_SECRET_KEY;

/**
 * Paystack Service
 * Handles all logic for Dedicated Virtual Accounts, Transafers, and Verifications.
 */
const PaystackService = {
    /**
     * Create or Fetch a Paystack Customer
     */
    createCustomer: async (email, fullName, phone) => {
        try {
            const response = await axios.post('https://api.paystack.co/customer', {
                email,
                first_name: fullName.split(' ')[0],
                last_name: fullName.split(' ').slice(1).join(' '),
                phone: phone
            }, {
                headers: { Authorization: `Bearer ${PAYSTACK_SECRET}` }
            });
            return response.data;
        } catch (error) {
            console.error('Paystack Create Customer Error:', error.response?.data || error.message);
            throw new Error(error.response?.data?.message || 'Failed to create Paystack customer');
        }
    },

    /**
     * Create Dedicated Virtual Account
     * Requires the Paystack customer_id or code
     */
    createDedicatedAccount: async (customerCode) => {
        try {
            const response = await axios.post('https://api.paystack.co/dedicated_account', {
                customer: customerCode,
                preferred_bank: 'wema-bank' 
            }, {
                headers: { Authorization: `Bearer ${PAYSTACK_SECRET}` }
            });
            return { success: true, data: response.data.data };
        } catch (error) {
            console.error('Paystack Dedicated Account Error:', error.response?.data || error.message);
            return { success: false, message: error.response?.data?.message || 'Failed to create dedicated virtual account' };
        }
    },

    /**
     * Single-step DVA Assignment
     * Creates customer and assigns DVA in one go (requires more data for some businesses)
     */
    assignDedicatedAccount: async (data) => {
        try {
            const response = await axios.post('https://api.paystack.co/dedicated_account/assign', {
                email: data.email,
                first_name: data.firstName,
                last_name: data.lastName,
                phone: data.phone,
                preferred_bank: 'wema-bank',
                country: 'NG'
            }, {
                headers: { Authorization: `Bearer ${PAYSTACK_SECRET}` }
            });
            return { success: true, data: response.data.data };
        } catch (error) {
            console.error('Paystack Assign DVA Error:', error.response?.data || error.message);
            return { success: false, message: error.response?.data?.message || 'Failed to assign dedicated virtual account' };
        }
    },

    /**
     * Requery Dedicated Virtual Account
     * Triggers a manual sync for a specific account and date
     */
    requeryDedicatedAccount: async (accountNumber, providerSlug, date) => {
        try {
            const formattedDate = date || new Date().toISOString().split('T')[0];
            const response = await axios.get(`https://api.paystack.co/dedicated_account/requery?account_number=${accountNumber}&provider_slug=${providerSlug}&date=${formattedDate}`, {
                headers: { Authorization: `Bearer ${PAYSTACK_SECRET}` }
            });
            return { success: true, data: response.data };
        } catch (error) {
            console.error('Paystack Requery Error:', error.response?.data || error.message);
            return { success: false, message: error.response?.data?.message || 'Requery failed' };
        }
    },

    /**
     * Verify Transaction by Reference
     */
    verifyTransaction: async (reference) => {
        try {
            const response = await axios.get(`https://api.paystack.co/transaction/verify/${reference}`, {
                headers: { Authorization: `Bearer ${PAYSTACK_SECRET}` }
            });
            return response.data;
        } catch (error) {
            console.error('Paystack Verify Transaction Error:', error.response?.data || error.message);
            throw new Error(error.response?.data?.message || 'Failed to verify transaction');
        }
    },

    /**
     * Initiate Transfer (for Payouts)
     */
    initiateTransfer: async (amount, recipientCode, reason) => {
        try {
            const response = await axios.post('https://api.paystack.co/transfer', {
                source: 'balance',
                amount: amount * 100, // Paystack expects Kobo
                recipient: recipientCode,
                reason: reason
            }, {
                headers: { Authorization: `Bearer ${PAYSTACK_SECRET}` }
            });
            return response.data;
        } catch (error) {
            console.error('Paystack Transfer Error:', error.response?.data || error.message);
            throw new Error(error.response?.data?.message || 'Transfer initiation failed');
        }
    }
};

module.exports = PaystackService;
