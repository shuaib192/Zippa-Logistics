-- Create settings table
CREATE TABLE IF NOT EXISTS settings (
    id SERIAL PRIMARY KEY,
    key VARCHAR(100) UNIQUE NOT NULL,
    value VARCHAR(255) NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Insert initial fare settings
INSERT INTO settings (key, value, description)
VALUES 
('base_fare', '500', 'The starting price for a delivery in Naira'),
('per_km_fare', '150', 'The price added per kilometer in Naira')
ON CONFLICT (key) DO NOTHING;
