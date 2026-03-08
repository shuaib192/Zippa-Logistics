-- =============================================
-- WHATSAPP AI AGENT MIGRATION
-- Adding tables for sessions and landmarks
-- =============================================

-- 1. WhatsApp Sessions
-- Stores the state of the conversation (e.g., if we are in the middle of a booking)
CREATE TABLE IF NOT EXISTS whatsapp_sessions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone_number    VARCHAR(20) UNIQUE NOT NULL,
    user_id         UUID REFERENCES users(id) ON DELETE SET NULL,
    
    current_flow    VARCHAR(50), -- 'idle', 'booking', 'tracking', 'negotiating'
    flow_step       VARCHAR(50), -- 'pickup', 'dropoff', 'package_type', 'confirm'
    
    -- flow_data stores temporary booking info before it's saved to the orders table
    -- e.g., {"pickup": "Bosso", "dropoff": "Chanchaga", "price": 1500}
    flow_data       JSONB DEFAULT '{}',
    
    last_interaction TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. User Landmarks
-- Stores custom descriptions of locations to help drivers (the "cheat code")
CREATE TABLE IF NOT EXISTS user_landmarks (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    name            VARCHAR(100) NOT NULL, -- e.g., 'Home', 'Shop'
    address         TEXT NOT NULL,
    description     TEXT NOT NULL, -- e.g., 'Behind the yellow kiosk, black gate'
    
    latitude        DECIMAL(10, 8),
    longitude       DECIMAL(11, 8),
    
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_wa_sessions_phone ON whatsapp_sessions(phone_number);
CREATE INDEX IF NOT EXISTS idx_user_landmarks_user ON user_landmarks(user_id);
