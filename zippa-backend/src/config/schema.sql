-- ============================================
-- 🎓 WHAT IS THIS FILE?
-- This is our database SCHEMA — it defines all
-- the tables (like spreadsheets) that store our data.
-- 
-- Think of each table as an Excel sheet:
-- - "users" table = a sheet listing all users
-- - "orders" table = a sheet listing all deliveries
-- - Each column = a type of data (name, email, etc.)
-- - Each row = one record (one user, one order, etc.)
--
-- KEY CONCEPTS:
-- PRIMARY KEY = unique ID for each row (like a row number)
-- FOREIGN KEY = links one table to another
-- NOT NULL = this field is required
-- DEFAULT = automatic value if none is provided
-- ENUM/CHECK = restricts what values are allowed
-- ============================================

-- =============================================
-- TABLE 1: users
-- The main user table. Every person in the system
-- (customer, rider, vendor) is stored here.
-- =============================================
CREATE TABLE IF NOT EXISTS users (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    -- UUID = a unique random ID like "a1b2c3d4-e5f6-..."
    -- Much safer than counting 1, 2, 3 (harder to guess)
    
    email           VARCHAR(255) UNIQUE,
    -- VARCHAR(255) = text up to 255 characters
    -- UNIQUE = no two users can have the same email
    
    phone           VARCHAR(20) UNIQUE NOT NULL,
    -- Phone number is REQUIRED (NOT NULL) and must be unique
    
    password_hash   VARCHAR(255) NOT NULL,
    -- We NEVER store real passwords! We store a "hash"
    -- (scrambled version). Even if hackers steal the database,
    -- they can't see your actual password.
    
    full_name       VARCHAR(255) NOT NULL,
    
    avatar_url      TEXT,
    -- Profile picture URL (optional, so no NOT NULL)
    
    role            VARCHAR(20) NOT NULL DEFAULT 'customer',
    -- What type of user: 'customer', 'rider', or 'vendor'
    -- DEFAULT means new users are customers unless specified
    
    secondary_role  VARCHAR(20),
    -- Allows role switching (e.g., a vendor who also sends packages)
    
    kyc_status      VARCHAR(20) DEFAULT 'unverified',
    -- KYC = Know Your Customer (identity verification)
    -- Values: 'unverified', 'pending', 'verified', 'rejected'
    
    is_active       BOOLEAN DEFAULT true,
    -- Can disable a user without deleting their data

    fcm_token       TEXT,
    -- Firebase Cloud Messaging token for push notifications
    
    is_online       BOOLEAN DEFAULT false,
    -- For riders: shows if they're available for deliveries
    
    last_login_at   TIMESTAMP,
    -- When they last logged in
    
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Enforce valid roles
    CONSTRAINT valid_role CHECK (role IN ('customer', 'rider', 'vendor', 'admin')),
    CONSTRAINT valid_secondary_role CHECK (secondary_role IN ('customer', 'rider', 'vendor', NULL)),
    CONSTRAINT valid_kyc_status CHECK (kyc_status IN ('unverified', 'pending', 'verified', 'rejected'))
);

-- =============================================
-- TABLE 2: vendor_categories
-- Groups vendors into categories like 'Groceries', 'Pharmacy'.
-- =============================================
CREATE TABLE IF NOT EXISTS vendor_categories (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name        VARCHAR(100) UNIQUE NOT NULL,
    icon_name   VARCHAR(50), -- Flutter icon name
    image_url   TEXT,
    is_active   BOOLEAN DEFAULT true,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- TABLE 3: user_profiles
-- Extra details for each user type.
-- Separated from users table to keep things clean.
-- =============================================
CREATE TABLE IF NOT EXISTS user_profiles (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    -- REFERENCES = links this to the users table
    -- ON DELETE CASCADE = if user is deleted, their profile goes too
    
    -- Personal details
    date_of_birth   DATE,
    gender          VARCHAR(10),
    address         TEXT,
    city            VARCHAR(100),
    state           VARCHAR(100),
    
    -- Rider-specific fields
    vehicle_type    VARCHAR(50),      -- 'motorcycle', 'bicycle', 'car'
    vehicle_plate   VARCHAR(20),      -- License plate number
    guarantor_name  VARCHAR(255),     -- Guarantor's full name
    guarantor_phone VARCHAR(20),      -- Guarantor's phone
    
    -- Payout/Bank Details (For receiving earnings)
    payout_bank_name      VARCHAR(100),
    payout_account_number VARCHAR(20),
    payout_account_name   VARCHAR(255),
    payout_bank_code      VARCHAR(10),
    
    -- Vendor-specific fields
    business_name       VARCHAR(255),
    business_address    TEXT,
    business_reg_number VARCHAR(100),  -- CAC registration number
    business_category_id UUID REFERENCES vendor_categories(id) ON DELETE SET NULL,
    default_pickup_address TEXT,       -- Default address for pickups
    
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- TABLE 4: orders
-- Every delivery request is stored here.
-- This is the HEART of the logistics system.
-- =============================================
CREATE TABLE IF NOT EXISTS orders (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_number    VARCHAR(20) UNIQUE NOT NULL,
    -- Human-readable order number like "ZLP-20260305-001"
    
    customer_id     UUID NOT NULL REFERENCES users(id),
    rider_id        UUID REFERENCES users(id),
    -- rider_id is nullable because a rider hasn't been assigned yet
    -- when the order is first created
    
    vendor_id       UUID REFERENCES users(id),
    -- If a vendor created this order on behalf of their customer
    
    -- Pickup details
    pickup_address      TEXT NOT NULL,
    pickup_latitude     DECIMAL(10, 8),
    pickup_longitude    DECIMAL(11, 8),
    -- DECIMAL(10,8) = up to 10 digits, 8 after decimal point
    -- Perfect for GPS coordinates like 6.52437891
    
    pickup_contact_name  VARCHAR(255),
    pickup_contact_phone VARCHAR(20),
    
    -- Dropoff details
    dropoff_address      TEXT NOT NULL,
    dropoff_latitude     DECIMAL(10, 8),
    dropoff_longitude    DECIMAL(11, 8),
    dropoff_contact_name  VARCHAR(255),
    dropoff_contact_phone VARCHAR(20),
    
    -- Package details
    package_type     VARCHAR(50),    -- 'document', 'parcel', 'food', 'fragile'
    package_size     VARCHAR(20),    -- 'small', 'medium', 'large'
    package_weight   DECIMAL(10, 2), -- Weight in kg
    package_value    DECIMAL(12, 2), -- Declared value in Naira
    
    -- Escrow & Payment Details
    item_price          DECIMAL(12, 2) DEFAULT 0,
    payment_status      VARCHAR(20) DEFAULT 'held', -- 'pending', 'held', 'released', 'refunded'
    customer_confirmed  BOOLEAN DEFAULT FALSE,
    package_description TEXT,
    customer_notes      TEXT,
    is_marketplace      BOOLEAN DEFAULT FALSE,
    
    -- Pricing
    distance_km      DECIMAL(10, 2),  -- Distance in kilometers
    base_fare        DECIMAL(12, 2),  -- Base delivery fee
    distance_fare    DECIMAL(12, 2),  -- Fare based on distance
    platform_fee     DECIMAL(12, 2),  -- Zippa platform cut
    subtotal         DECIMAL(12, 2),  -- Fare before platform fee
    surge_multiplier DECIMAL(4, 2) DEFAULT 1.00,
    -- Surge pricing: 1.00 = normal, 1.50 = 50% extra during high demand
    total_fare       DECIMAL(12, 2),  -- Final amount customer pays
    
    -- Commission split (from PRD: 60/40)
    rider_earning    DECIMAL(12, 2),  -- 60% goes to rider
    zippa_commission DECIMAL(12, 2),  -- 40% goes to Zippa
    
    -- Status tracking
    status           VARCHAR(30) DEFAULT 'pending',
    -- Order lifecycle:
    -- pending → accepted → picked_up → in_transit → delivered → completed
    -- OR: pending → cancelled
    
    payment_method   VARCHAR(20),    -- 'cash', 'card', 'wallet', 'bank_transfer'
    
    -- Scheduling
    is_scheduled     BOOLEAN DEFAULT false,
    scheduled_at     TIMESTAMP,      -- When to pick up (if scheduled)
    
    -- Timestamps for each status change
    accepted_at      TIMESTAMP,
    picked_up_at     TIMESTAMP,
    delivered_at     TIMESTAMP,
    cancelled_at     TIMESTAMP,
    cancellation_reason TEXT,
    
    created_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT valid_status CHECK (status IN (
        'pending', 'accepted', 'arrived_pickup', 'picked_up', 
        'in_transit', 'arrived_dropoff', 'delivered', 'completed', 'cancelled'
    )),
    CONSTRAINT valid_payment_method CHECK (payment_method IN (
        'cash', 'card', 'wallet', 'bank_transfer'
    )),
    CONSTRAINT valid_payment_status CHECK (payment_status IN (
        'pending', 'paid', 'failed', 'refunded', 'held', 'released'
    ))
);

-- =============================================
-- TABLE 5: wallets
-- Every user has a wallet for storing money.
-- Used for: rider earnings, customer payments, vendor payouts.
-- =============================================
CREATE TABLE IF NOT EXISTS wallets (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    balance     DECIMAL(15, 2) DEFAULT 0.00,
    -- Balance in Nigerian Naira
    pending_balance DECIMAL(15, 2) DEFAULT 0.00,
    -- Funds held in escrow (upcoming earnings)
    currency    VARCHAR(3) DEFAULT 'NGN',
    is_locked   BOOLEAN DEFAULT false,
    
    -- Paystack Integration
    paystack_customer_code   VARCHAR(50),
    virtual_account_number   VARCHAR(20),
    virtual_bank_name        VARCHAR(100),
    virtual_account_name     VARCHAR(255),
    virtual_account_error    TEXT,
    
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- TABLE 6: wallet_transactions
-- Every money movement is recorded here.
-- This is like a bank statement — crucial for auditing.
-- We use "double-entry" principles: every debit has a credit.
-- =============================================
CREATE TABLE IF NOT EXISTS wallet_transactions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    wallet_id       UUID NOT NULL REFERENCES wallets(id),
    order_id        UUID REFERENCES orders(id),
    -- Links to the order this transaction is about (if applicable)
    
    type            VARCHAR(20) NOT NULL,
    -- 'credit' = money coming IN, 'debit' = money going OUT
    
    amount          DECIMAL(15, 2) NOT NULL,
    balance_before  DECIMAL(15, 2) NOT NULL,
    balance_after   DECIMAL(15, 2) NOT NULL,
    -- We store before/after so we can audit the math
    
    reference       VARCHAR(100) UNIQUE NOT NULL,
    -- Unique transaction reference like "TXN-20260305-abc123"
    
    description     TEXT,
    -- Human-readable description like "Earning from order ZLP-001"
    
    status          VARCHAR(20) DEFAULT 'completed',
    
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT valid_txn_type CHECK (type IN ('credit', 'debit')),
    CONSTRAINT valid_txn_status CHECK (status IN ('pending', 'completed', 'failed', 'reversed'))
);

-- =============================================
-- TABLE 7: kyc_documents
-- Stores identity documents uploaded by users.
-- Critical for trust and regulatory compliance.
-- =============================================
CREATE TABLE IF NOT EXISTS kyc_documents (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    document_type   VARCHAR(50) NOT NULL,
    -- 'nin' (National ID), 'drivers_license', 'voters_card', 
    -- 'passport', 'business_reg', 'utility_bill', 'guarantor_form'
    
    document_url    TEXT NOT NULL,
    selfie_url      TEXT,
    -- URL to the uploaded images (stored in cloud storage)
    
    document_number VARCHAR(100),
    -- The ID number on the document (for verification)
    
    status          VARCHAR(20) DEFAULT 'pending',
    -- 'pending', 'approved', 'rejected'
    
    admin_notes     TEXT,
    -- Notes from admin when reviewing (e.g., "Image too blurry")
    
    reviewed_by     UUID REFERENCES users(id),
    -- Which admin reviewed this document
    
    reviewed_at     TIMESTAMP,
    
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT valid_doc_status CHECK (status IN ('pending', 'approved', 'rejected'))
);

-- =============================================
-- TABLE 8: ratings
-- After delivery, customers rate riders (1-5 stars).
-- Riders can also rate customers.
-- =============================================
CREATE TABLE IF NOT EXISTS ratings (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id    UUID NOT NULL REFERENCES orders(id),
    from_user   UUID NOT NULL REFERENCES users(id),
    to_user     UUID NOT NULL REFERENCES users(id),
    stars       INTEGER NOT NULL,
    comment     TEXT,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT valid_stars CHECK (stars >= 1 AND stars <= 5),
    -- Stars must be between 1 and 5
    CONSTRAINT unique_rating UNIQUE (order_id, from_user)
    -- One rating per order per user (can't rate same order twice)
);

-- =============================================
-- TABLE 9: notifications
-- In-app notifications for all users.
-- Push notifications are sent via Firebase, but
-- we also store them here so users can see history.
-- =============================================
CREATE TABLE IF NOT EXISTS notifications (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title       VARCHAR(255) NOT NULL,
    body        TEXT NOT NULL,
    type        VARCHAR(50),
    -- 'order_update', 'payment', 'kyc', 'promotion', 'system'
    data        JSONB,
    -- JSONB = structured data (like a mini-database within a column)
    -- e.g., {"order_id": "abc123", "status": "delivered"}
    is_read     BOOLEAN DEFAULT false,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- TABLE 10: refresh_tokens
-- Stores refresh tokens for secure re-authentication.
-- When an access token expires, the app uses the refresh
-- token to get a new one without asking for password again.
-- =============================================
CREATE TABLE IF NOT EXISTS refresh_tokens (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token       TEXT NOT NULL,
    expires_at  TIMESTAMP NOT NULL,
    is_revoked  BOOLEAN DEFAULT false,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- TABLE 11: audit_logs
-- Records important actions for security & compliance.
-- Who did what and when — essential for a financial platform.
-- =============================================
CREATE TABLE IF NOT EXISTS audit_logs (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID REFERENCES users(id),
    action      VARCHAR(100) NOT NULL,
    -- e.g., 'kyc_approved', 'wallet_withdrawal', 'order_cancelled'
    resource    VARCHAR(50),
    -- Which table/resource was affected
    resource_id UUID,
    -- ID of the affected record
    details     JSONB,
    -- Extra details about the action
    ip_address  VARCHAR(45),
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- TABLE 12: chat_messages
-- AI chatbot conversation history.
-- We store conversations so the AI has context.
-- =============================================
CREATE TABLE IF NOT EXISTS chat_messages (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    session_id      VARCHAR(100) NOT NULL,
    -- Groups messages into conversations
    role            VARCHAR(20) NOT NULL,
    -- 'user' or 'assistant'
    content         TEXT NOT NULL,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT valid_chat_role CHECK (role IN ('user', 'assistant'))
);

-- =============================================
-- TABLE 13: whatsapp_sessions
-- Tracks the multi-step conversation state for the WhatsApp Bot.
-- This allows the AI to "remember" the previous step in a flow.
-- =============================================
CREATE TABLE IF NOT EXISTS whatsapp_sessions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone_number    VARCHAR(20) UNIQUE NOT NULL,
    user_id         UUID REFERENCES users(id) ON DELETE SET NULL,
    
    current_flow    VARCHAR(50) DEFAULT 'idle',
    -- 'idle', 'booking', 'tracking', 'support'
    
    flow_step       VARCHAR(50) DEFAULT 'none',
    -- e.g., 'awaiting_pickup', 'awaiting_dropoff', 'awaiting_confirmation'
    
    flow_data       JSONB DEFAULT '{}',
    -- Temporary data like pickup location or package type
    
    last_interaction TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_whatsapp_phone ON whatsapp_sessions(phone_number);

-- =============================================
-- INDEXES
-- Indexes make database queries MUCH faster.
-- Think of them like the index at the back of a book —
-- instead of reading every page, you jump to what you need.
-- =============================================
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_orders_customer ON orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_rider ON orders(rider_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_created ON orders(created_at);
CREATE INDEX IF NOT EXISTS idx_wallet_txn_wallet ON wallet_transactions(wallet_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_kyc_user ON kyc_documents(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_user ON audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_chat_user_session ON chat_messages(user_id, session_id);

-- (Table 14: products follows)

-- =============================================
-- TABLE 14: products
-- Items listed by vendors for the marketplace.
-- =============================================
CREATE TABLE IF NOT EXISTS products (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vendor_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    category_id     UUID REFERENCES vendor_categories(id) ON DELETE SET NULL,
    
    name            VARCHAR(255) NOT NULL,
    description     TEXT,
    price           DECIMAL(12, 2) NOT NULL,
    image_url       TEXT,
    
    is_available    BOOLEAN DEFAULT true,
    stock_quantity  INTEGER DEFAULT 0,
    
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_products_vendor ON products(vendor_id);
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category_id);

-- =============================================
-- TABLE 15: order_chat_messages
-- Real-time chat between Rider and Customer for a specific order.
-- =============================================
CREATE TABLE IF NOT EXISTS order_chat_messages (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id        UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    sender_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    message         TEXT NOT NULL,
    is_read         BOOLEAN DEFAULT false,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_order_chat_order ON order_chat_messages(order_id);

-- =============================================
-- TABLE 16: withdrawals
-- Tracks payout requests from vendors and riders.
-- =============================================
CREATE TABLE IF NOT EXISTS withdrawals (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    amount          DECIMAL(12, 2) NOT NULL,
    status          VARCHAR(20) DEFAULT 'pending', -- 'pending', 'processing', 'completed', 'failed'
    transfer_code   VARCHAR(100), -- From Paystack
    recipient_code  VARCHAR(100), -- From Paystack
    reference       VARCHAR(100) UNIQUE,
    bank_name       VARCHAR(100),
    account_number  VARCHAR(20),
    failure_reason  TEXT,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- TABLE 17: disputes
-- Allows customers to report issues with orders.
-- =============================================
CREATE TABLE IF NOT EXISTS disputes (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id        UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    reason          VARCHAR(100) NOT NULL, -- 'item_not_received', 'damaged_item', 'rider_behavior', 'other'
    description     TEXT NOT NULL,
    status          VARCHAR(20) DEFAULT 'open', -- 'open', 'under_review', 'resolved', 'closed'
    admin_notes     TEXT,
    resolved_at     TIMESTAMP,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_dispute_order ON disputes(order_id);
CREATE INDEX IF NOT EXISTS idx_dispute_user ON disputes(user_id);

CREATE INDEX IF NOT EXISTS idx_withdrawals_user ON withdrawals(user_id);
