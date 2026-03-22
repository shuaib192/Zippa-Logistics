// ============================================
// EMAIL SERVICE (email.service.js)
// Uses strict HTTPS Gmail REST API (Bypasses Render SMTP Block)
// ============================================

const { google } = require('googleapis');

let _gmailClient = null;

const getGmailClient = async () => {
    if (_gmailClient) return _gmailClient;

    console.log('[EMAIL] Initializing Gmail REST API Client...');
    
    try {
        const OAuth2 = google.auth.OAuth2;
        const oauth2Client = new OAuth2(
            process.env.GMAIL_CLIENT_ID,
            process.env.GMAIL_CLIENT_SECRET,
            'https://developers.google.com/oauthplayground' // Redirect URL
        );

        oauth2Client.setCredentials({
            refresh_token: process.env.GMAIL_REFRESH_TOKEN,
        });

        _gmailClient = google.gmail({ version: 'v1', auth: oauth2Client });
        console.log('[EMAIL] Gmail REST Client Initialized Successfully.');
        return _gmailClient;
    } catch (error) {
        console.error('[EMAIL ERROR] Failed to initialize Gmail API:', error.message);
        throw error;
    }
};

// Helper: encode string to base64url format required by Gmail API
const makeBody = (to, from, subject, html) => {
    const utf8Subject = `=?utf-8?B?${Buffer.from(subject).toString('base64')}?=`;
    const messageParts = [
        `From: ${from}`,
        `To: ${to}`,
        'Content-Type: text/html; charset=utf-8',
        'MIME-Version: 1.0',
        `Subject: ${utf8Subject}`,
        '',
        html,
    ];
    const message = messageParts.join('\r\n');
    
    // The Gmail API requires base64url encoding
    return Buffer.from(message).toString('base64')
        .replace(/\+/g, '-')
        .replace(/\//g, '_')
        .replace(/=+$/, '');
};

// Generic sender function
const sendViaGmailApi = async (toEmail, subject, html) => {
    const gmail = await getGmailClient();
    const raw = makeBody(
        toEmail,
        `"Zippa Logistics" <${process.env.SMTP_EMAIL}>`,
        subject,
        html
    );
    
    try {
        const res = await gmail.users.messages.send({
            userId: 'me',
            requestBody: { raw },
        });
        console.log(`[EMAIL] Sent over HTTPS (Message ID: ${res.data.id})`);
        return res.data;
    } catch (err) {
        console.error('[EMAIL ERROR] Gmail API failed:', err.message);
        throw err;
    }
};

// Send OTP email for verification
const sendOTPEmail = async (toEmail, fullName, otp) => {
    const html = `
    <div style="font-family:'Segoe UI',Arial,sans-serif;max-width:480px;margin:0 auto;background:#0B0F19;border-radius:12px;overflow:hidden;">
        <div style="background:linear-gradient(135deg,#3B82F6,#2563EB);padding:32px;text-align:center;">
            <h1 style="color:#fff;margin:0;font-size:24px;font-weight:800;">⚡ Zippa Logistics</h1>
            <p style="color:rgba(255,255,255,0.8);margin:8px 0 0;font-size:13px;">Verify Your Email Address</p>
        </div>
        <div style="padding:32px;color:#E5E7EB;">
            <p style="margin:0 0 16px;font-size:15px;">Hi <strong style="color:#fff;">${fullName}</strong>,</p>
            <p style="margin:0 0 24px;font-size:14px;color:#9CA3AF;">Use the code below to verify your email and complete your registration:</p>
            <div style="text-align:center;margin:24px 0;">
                <div style="display:inline-block;background:#1F2937;border:2px solid #374151;border-radius:12px;padding:16px 32px;letter-spacing:8px;font-size:32px;font-weight:800;color:#3B82F6;">${otp}</div>
            </div>
            <p style="margin:0 0 8px;font-size:13px;color:#6B7280;text-align:center;">This code expires in <strong>10 minutes</strong></p>
            <hr style="border:none;border-top:1px solid #1F2937;margin:24px 0;">
            <p style="margin:0;font-size:12px;color:#4B5563;text-align:center;">If you didn't create a Zippa account, please ignore this email.</p>
        </div>
    </div>`;

    await sendViaGmailApi(toEmail, `${otp} — Verify Your Zippa Account`, html);
};

// Send Password Reset OTP email
const sendPasswordResetEmail = async (toEmail, fullName, otp) => {
    const html = `
    <div style="font-family:'Segoe UI',Arial,sans-serif;max-width:480px;margin:0 auto;background:#0B0F19;border-radius:12px;overflow:hidden;">
        <div style="background:linear-gradient(135deg,#EF4444,#B91C1C);padding:32px;text-align:center;">
            <h1 style="color:#fff;margin:0;font-size:24px;font-weight:800;">⚡ Zippa Logistics</h1>
            <p style="color:rgba(255,255,255,0.8);margin:8px 0 0;font-size:13px;">Reset Your Password</p>
        </div>
        <div style="padding:32px;color:#E5E7EB;">
            <p style="margin:0 0 16px;font-size:15px;">Hi <strong style="color:#fff;">${fullName}</strong>,</p>
            <p style="margin:0 0 24px;font-size:14px;color:#9CA3AF;">You requested to reset your password. Use the verification code below to proceed:</p>
            <div style="text-align:center;margin:24px 0;">
                <div style="display:inline-block;background:#1F2937;border:2px solid #374151;border-radius:12px;padding:16px 32px;letter-spacing:8px;font-size:32px;font-weight:800;color:#EF4444;">${otp}</div>
            </div>
            <p style="margin:0 0 8px;font-size:13px;color:#6B7280;text-align:center;">This code expires in <strong>10 minutes</strong></p>
            <p style="margin:24px 0 0;font-size:13px;color:#9CA3AF;text-align:center;">If you didn't request a password reset, please change your password immediately or contact support.</p>
            <hr style="border:none;border-top:1px solid #1F2937;margin:24px 0;">
            <p style="margin:0;font-size:12px;color:#4B5563;text-align:center;">— Zippa Logistics Security Team</p>
        </div>
    </div>`;

    await sendViaGmailApi(toEmail, `${otp} — Zippa Password Reset Code`, html);
};

// Send generic notification email
const sendNotificationEmail = async (toEmail, fullName, subject, body) => {
    const html = `
    <div style="font-family:'Segoe UI',Arial,sans-serif;max-width:480px;margin:0 auto;background:#0B0F19;border-radius:12px;overflow:hidden;">
        <div style="background:linear-gradient(135deg,#3B82F6,#2563EB);padding:24px;text-align:center;">
            <h1 style="color:#fff;margin:0;font-size:20px;font-weight:800;">⚡ Zippa Logistics</h1>
        </div>
        <div style="padding:32px;color:#E5E7EB;">
            <p style="margin:0 0 16px;font-size:15px;">Hi <strong style="color:#fff;">${fullName}</strong>,</p>
            <h2 style="margin:0 0 16px;font-size:18px;color:#fff;">${subject}</h2>
            <div style="background:#1F2937;border-radius:8px;padding:16px;margin:16px 0;font-size:14px;color:#D1D5DB;line-height:1.6;">${body}</div>
            <hr style="border:none;border-top:1px solid #1F2937;margin:24px 0;">
            <p style="margin:0;font-size:12px;color:#4B5563;text-align:center;">— Zippa Logistics Team</p>
        </div>
    </div>`;

    await sendViaGmailApi(toEmail, subject, html);
};


// Send Order Placed confirmation email
const sendOrderPlacedEmail = async (toEmail, fullName, order) => {
    const html = `
    <div style="font-family:'Segoe UI',Arial,sans-serif;max-width:480px;margin:0 auto;background:#0B0F19;border-radius:12px;overflow:hidden;">
        <div style="background:linear-gradient(135deg,#10B981,#059669);padding:32px;text-align:center;">
            <h1 style="color:#fff;margin:0;font-size:24px;font-weight:800;">⚡ Zippa Logistics</h1>
            <p style="color:rgba(255,255,255,0.8);margin:8px 0 0;font-size:13px;">Order Confirmed</p>
        </div>
        <div style="padding:32px;color:#E5E7EB;">
            <p style="margin:0 0 16px;font-size:15px;">Hi <strong style="color:#fff;">${fullName}</strong>,</p>
            <p style="margin:0 0 24px;font-size:14px;color:#9CA3AF;">Your delivery order has been placed successfully. A rider will accept it shortly.</p>
            <div style="background:#1F2937;border-radius:12px;padding:20px;margin:16px 0;">
                <div style="display:flex;justify-content:space-between;margin-bottom:12px;">
                    <span style="color:#6B7280;font-size:12px;">Order Number</span>
                    <span style="color:#10B981;font-weight:bold;font-size:14px;">${order.order_number}</span>
                </div>
                <hr style="border:none;border-top:1px solid #374151;margin:12px 0;">
                <div style="margin-bottom:8px;">
                    <span style="color:#6B7280;font-size:11px;">PICKUP</span>
                    <p style="color:#fff;margin:4px 0 0;font-size:13px;">${order.pickup_address}</p>
                </div>
                <div style="margin-bottom:12px;">
                    <span style="color:#6B7280;font-size:11px;">DROPOFF</span>
                    <p style="color:#fff;margin:4px 0 0;font-size:13px;">${order.dropoff_address}</p>
                </div>
                <hr style="border:none;border-top:1px solid #374151;margin:12px 0;">
                <div style="display:flex;justify-content:space-between;margin-bottom:6px;">
                    <span style="color:#6B7280;font-size:12px;">Base Fare</span>
                    <span style="color:#D1D5DB;font-size:12px;">₦${parseFloat(order.base_fare || 0).toLocaleString()}</span>
                </div>
                <div style="display:flex;justify-content:space-between;margin-bottom:6px;">
                    <span style="color:#6B7280;font-size:12px;">Distance Fare</span>
                    <span style="color:#D1D5DB;font-size:12px;">₦${parseFloat(order.distance_fare || 0).toLocaleString()}</span>
                </div>
                <div style="display:flex;justify-content:space-between;margin-bottom:6px;">
                    <span style="color:#6B7280;font-size:12px;">Platform Fee</span>
                    <span style="color:#D1D5DB;font-size:12px;">₦${parseFloat(order.platform_fee || 0).toLocaleString()}</span>
                </div>
                ${parseFloat(order.item_price || 0) > 0 ? `<div style="display:flex;justify-content:space-between;margin-bottom:6px;">
                    <span style="color:#6B7280;font-size:12px;">Item Cost</span>
                    <span style="color:#D1D5DB;font-size:12px;">₦${parseFloat(order.item_price).toLocaleString()}</span>
                </div>` : ''}
                <hr style="border:none;border-top:1px solid #374151;margin:12px 0;">
                <div style="display:flex;justify-content:space-between;">
                    <span style="color:#fff;font-weight:bold;font-size:14px;">Total</span>
                    <span style="color:#10B981;font-weight:bold;font-size:16px;">₦${parseFloat(order.total_fare || 0).toLocaleString()}</span>
                </div>
            </div>
            <p style="margin:16px 0 0;font-size:12px;color:#6B7280;text-align:center;">You can track your order status in the Zippa app.</p>
            <hr style="border:none;border-top:1px solid #1F2937;margin:24px 0;">
            <p style="margin:0;font-size:12px;color:#4B5563;text-align:center;">— Zippa Logistics Team</p>
        </div>
    </div>`;

    await sendViaGmailApi(toEmail, `Order #${order.order_number} — Confirmed`, html);
};

// Send Delivery Receipt email
const sendOrderDeliveredEmail = async (toEmail, fullName, order) => {
    const html = `
    <div style="font-family:'Segoe UI',Arial,sans-serif;max-width:480px;margin:0 auto;background:#0B0F19;border-radius:12px;overflow:hidden;">
        <div style="background:linear-gradient(135deg,#8B5CF6,#7C3AED);padding:32px;text-align:center;">
            <h1 style="color:#fff;margin:0;font-size:24px;font-weight:800;">⚡ Zippa Logistics</h1>
            <p style="color:rgba(255,255,255,0.8);margin:8px 0 0;font-size:13px;">Delivery Receipt</p>
        </div>
        <div style="padding:32px;color:#E5E7EB;">
            <p style="margin:0 0 16px;font-size:15px;">Hi <strong style="color:#fff;">${fullName}</strong>,</p>
            <p style="margin:0 0 24px;font-size:14px;color:#9CA3AF;">Your delivery has been completed and confirmed. Here is your receipt:</p>
            <div style="background:#1F2937;border-radius:12px;padding:20px;margin:16px 0;">
                <div style="text-align:center;margin-bottom:16px;">
                    <div style="display:inline-block;background:#10B981;border-radius:50%;width:48px;height:48px;line-height:48px;text-align:center;font-size:24px;">✓</div>
                    <p style="color:#10B981;font-weight:bold;font-size:14px;margin:8px 0 0;">Delivered Successfully</p>
                </div>
                <hr style="border:none;border-top:1px solid #374151;margin:12px 0;">
                <div style="display:flex;justify-content:space-between;margin-bottom:8px;">
                    <span style="color:#6B7280;font-size:12px;">Order</span>
                    <span style="color:#8B5CF6;font-weight:bold;font-size:13px;">${order.order_number}</span>
                </div>
                <div style="margin-bottom:8px;">
                    <span style="color:#6B7280;font-size:11px;">FROM</span>
                    <p style="color:#D1D5DB;margin:4px 0 0;font-size:12px;">${order.pickup_address}</p>
                </div>
                <div style="margin-bottom:12px;">
                    <span style="color:#6B7280;font-size:11px;">TO</span>
                    <p style="color:#D1D5DB;margin:4px 0 0;font-size:12px;">${order.dropoff_address}</p>
                </div>
                <hr style="border:none;border-top:1px solid #374151;margin:12px 0;">
                <div style="display:flex;justify-content:space-between;margin-bottom:6px;">
                    <span style="color:#6B7280;font-size:12px;">Delivery Fee</span>
                    <span style="color:#D1D5DB;font-size:12px;">₦${parseFloat(order.total_fare || 0).toLocaleString()}</span>
                </div>
                ${parseFloat(order.item_price || 0) > 0 ? `<div style="display:flex;justify-content:space-between;margin-bottom:6px;">
                    <span style="color:#6B7280;font-size:12px;">Item Cost</span>
                    <span style="color:#D1D5DB;font-size:12px;">₦${parseFloat(order.item_price).toLocaleString()}</span>
                </div>` : ''}
                <div style="display:flex;justify-content:space-between;margin-bottom:6px;">
                    <span style="color:#6B7280;font-size:12px;">Payment</span>
                    <span style="color:#D1D5DB;font-size:12px;">${(order.payment_method || 'wallet').toUpperCase()}</span>
                </div>
                <hr style="border:none;border-top:1px solid #374151;margin:12px 0;">
                <div style="display:flex;justify-content:space-between;">
                    <span style="color:#fff;font-weight:bold;font-size:14px;">Total Paid</span>
                    <span style="color:#8B5CF6;font-weight:bold;font-size:16px;">₦${(parseFloat(order.total_fare || 0) + parseFloat(order.item_price || 0)).toLocaleString()}</span>
                </div>
            </div>
            <p style="margin:16px 0 0;font-size:12px;color:#6B7280;text-align:center;">Thank you for choosing Zippa Logistics!</p>
            <hr style="border:none;border-top:1px solid #1F2937;margin:24px 0;">
            <p style="margin:0;font-size:12px;color:#4B5563;text-align:center;">— Zippa Logistics Team</p>
        </div>
    </div>`;

    await sendViaGmailApi(toEmail, `Receipt — Order #${order.order_number} Delivered`, html);
};

// Generate 6-digit OTP
const generateOTP = () => {
    return Math.floor(100000 + Math.random() * 900000).toString();
};

module.exports = { sendOTPEmail, sendPasswordResetEmail, sendNotificationEmail, sendOrderPlacedEmail, sendOrderDeliveredEmail, generateOTP };
