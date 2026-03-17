// ============================================
// EMAIL SERVICE (email.service.js)
// Uses Nodemailer with Gmail SMTP
// V21 Fix: Lazy transporter to ensure env vars are loaded
// ============================================

const nodemailer = require('nodemailer');

// Lazy transporter — created on first use, not at module load
let _transporter = null;
const getTransporter = () => {
    if (!_transporter) {
        console.log('[EMAIL] Creating transporter with:', process.env.SMTP_EMAIL || '❌ MISSING');
        _transporter = nodemailer.createTransport({
            service: 'gmail',
            auth: {
                user: process.env.SMTP_EMAIL,
                pass: process.env.SMTP_APP_PASSWORD,
            },
        });
    }
    return _transporter;
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

    await getTransporter().sendMail({
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

    await getTransporter().sendMail({
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

    await getTransporter().sendMail({
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
