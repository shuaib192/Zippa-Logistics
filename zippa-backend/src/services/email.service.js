// ============================================
// EMAIL SERVICE (email.service.js)
// Uses Nodemailer with Gmail API (OAuth2)
// V21 Fix: Bypasses Render's strict SMTP firewall
// ============================================

const nodemailer = require('nodemailer');
const { google } = require('googleapis');

// Lazy transporter — created on first use to ensure async OAuth token fetch doesn't block module load
let _transporter = null;

const getTransporter = async () => {
    if (_transporter) return _transporter;

    console.log('[EMAIL] Initializing Gmail OAuth2 Transporter...');
    
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

        // Get a fresh access token
        const accessTokenResponse = await oauth2Client.getAccessToken();
        const accessToken = accessTokenResponse?.token;

        if (!accessToken) {
            throw new Error('Failed to create OAuth access token');
        }

        _transporter = nodemailer.createTransport({
            service: 'gmail',
            auth: {
                type: 'OAuth2',
                user: process.env.SMTP_EMAIL,
                clientId: process.env.GMAIL_CLIENT_ID,
                clientSecret: process.env.GMAIL_CLIENT_SECRET,
                refreshToken: process.env.GMAIL_REFRESH_TOKEN,
                accessToken: accessToken,
            },
        });

        console.log('[EMAIL] Gmail OAuth2 Transporter Initialized Successfully.');
        return _transporter;
    } catch (error) {
        console.error('[EMAIL ERROR] Failed to initialize OAuth2:', error.message);
        throw error;
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

    const transporter = await getTransporter();
    await transporter.sendMail({
        from: `"Zippa Logistics" <${process.env.SMTP_EMAIL}>`,
        to: toEmail,
        subject: `${otp} — Verify Your Zippa Account`,
        html,
    });
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

    const transporter = await getTransporter();
    await transporter.sendMail({
        from: `"Zippa Logistics" <${process.env.SMTP_EMAIL}>`,
        to: toEmail,
        subject: `${otp} — Zippa Password Reset Code`,
        html,
    });
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

    const transporter = await getTransporter();
    await transporter.sendMail({
        from: `"Zippa Logistics" <${process.env.SMTP_EMAIL}>`,
        to: toEmail,
        subject,
        html,
    });
};

// Generate 6-digit OTP
const generateOTP = () => {
    return Math.floor(100000 + Math.random() * 900000).toString();
};

module.exports = { sendOTPEmail, sendPasswordResetEmail, sendNotificationEmail, generateOTP };
