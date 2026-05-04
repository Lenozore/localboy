CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- USERS & AUTH
-- ============================================

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone VARCHAR(20) UNIQUE,
    email VARCHAR(255) UNIQUE,
    name VARCHAR(255),
    dob DATE,
    avatar_url TEXT,
    google_id VARCHAR(255) UNIQUE,
    role VARCHAR(20) NOT NULL DEFAULT 'tourist',  -- tourist, driver, guide, admin
    is_phone_verified BOOLEAN DEFAULT FALSE,
    is_email_verified BOOLEAN DEFAULT FALSE,
    is_profile_complete BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE otp_verifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    target VARCHAR(255) NOT NULL,           -- phone number or email
    target_type VARCHAR(10) NOT NULL,       -- 'phone' or 'email'
    otp_code VARCHAR(6) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    is_verified BOOLEAN DEFAULT FALSE,
    attempts INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- DRIVER / GUIDE PROFILES
-- ============================================

CREATE TABLE driver_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    vehicle_type VARCHAR(50),               -- sedan, suv, auto, etc.
    vehicle_number VARCHAR(20),
    vehicle_model VARCHAR(100),
    is_available BOOLEAN DEFAULT FALSE,
    is_verified BOOLEAN DEFAULT FALSE,
    rating DECIMAL(2, 1) DEFAULT 0.0,
    total_trips INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id)
);

CREATE TABLE guide_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    languages TEXT[],                        -- ['English', 'Hindi', 'Konkani']
    specializations TEXT[],                  -- ['historical', 'nature', 'food']
    experience_years INT DEFAULT 0,
    is_available BOOLEAN DEFAULT FALSE,
    is_verified BOOLEAN DEFAULT FALSE,
    rating DECIMAL(2, 1) DEFAULT 0.0,
    total_trips INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id)
);

CREATE TABLE documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    doc_type VARCHAR(50) NOT NULL,           -- aadhar, license, registration, insurance, guide_cert
    file_url TEXT NOT NULL,
    file_name VARCHAR(255),
    status VARCHAR(20) DEFAULT 'pending',    -- pending, approved, rejected
    reviewed_by UUID REFERENCES users(id),
    review_notes TEXT,
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    reviewed_at TIMESTAMP
);

-- ============================================
-- POINTS OF INTEREST
-- ============================================

CREATE TABLE pois (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    photo_urls TEXT[],                        -- array of image URLs
    category VARCHAR(50),                    -- beach, historical, nature, religious, food
    lat DECIMAL(10, 8) NOT NULL,
    lng DECIMAL(11, 8) NOT NULL,
    avg_visit_minutes INT DEFAULT 60,
    popularity_score INT DEFAULT 5,          -- 1-10
    city VARCHAR(100) DEFAULT 'Goa',
    state VARCHAR(100) DEFAULT 'Goa',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- TRIPS & ITINERARY
-- ============================================

CREATE TABLE trips (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tourist_id UUID NOT NULL REFERENCES users(id),
    driver_id UUID REFERENCES users(id),
    guide_id UUID REFERENCES users(id),
    trip_type VARCHAR(20) NOT NULL,          -- half_day, full_day
    trip_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME,
    pickup_address TEXT NOT NULL,
    pickup_lat DECIMAL(10, 8) NOT NULL,
    pickup_lng DECIMAL(11, 8) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',    -- pending, confirmed, driver_assigned, active, completed, cancelled
    total_distance_km DECIMAL(8, 2) DEFAULT 0,
    tourist_charge DECIMAL(10, 2) NOT NULL,
    platform_fee DECIMAL(10, 2) DEFAULT 0,
    driver_payout DECIMAL(10, 2) DEFAULT 0,
    guide_payout DECIMAL(10, 2) DEFAULT 0,
    booking_code VARCHAR(10) UNIQUE,
    cancellation_reason TEXT,
    tourist_rating INT,                      -- 1-5 rating from tourist
    driver_rating INT,
    guide_rating INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE trip_stops (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trip_id UUID NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    poi_id UUID NOT NULL REFERENCES pois(id),
    stop_order INT NOT NULL,
    estimated_arrival TIME,
    actual_arrival TIME,
    status VARCHAR(20) DEFAULT 'pending',    -- pending, visiting, completed, skipped
    UNIQUE(trip_id, stop_order)
);

-- ============================================
-- PAYMENTS
-- ============================================

CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trip_id UUID NOT NULL REFERENCES trips(id),
    payer_id UUID REFERENCES users(id),       -- tourist for trip_payment, platform for payouts
    payee_id UUID REFERENCES users(id),       -- platform for trip_payment, driver/guide for payouts
    payment_type VARCHAR(30) NOT NULL,        -- trip_payment, driver_payout, guide_payout
    amount DECIMAL(10, 2) NOT NULL,
    razorpay_order_id VARCHAR(255),
    razorpay_payment_id VARCHAR(255),
    razorpay_payout_id VARCHAR(255),
    status VARCHAR(20) DEFAULT 'pending',     -- pending, completed, failed, refunded
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP
);

-- ============================================
-- MESSAGING
-- ============================================

CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trip_id UUID NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES users(id),
    receiver_id UUID NOT NULL REFERENCES users(id),
    content TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- COMPLAINTS
-- ============================================

CREATE TABLE complaints (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trip_id UUID REFERENCES trips(id),
    user_id UUID NOT NULL REFERENCES users(id),
    subject VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    status VARCHAR(20) DEFAULT 'open',       -- open, investigating, resolved, closed
    resolved_by UUID REFERENCES users(id),
    resolution_notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP
);

-- ============================================
-- INDEXES
-- ============================================

CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_google_id ON users(google_id);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_otp_target ON otp_verifications(target, target_type);
CREATE INDEX idx_documents_user ON documents(user_id);
CREATE INDEX idx_documents_status ON documents(status);
CREATE INDEX idx_pois_city ON pois(city);
CREATE INDEX idx_pois_location ON pois(lat, lng);
CREATE INDEX idx_trips_tourist ON trips(tourist_id);
CREATE INDEX idx_trips_driver ON trips(driver_id);
CREATE INDEX idx_trips_guide ON trips(guide_id);
CREATE INDEX idx_trips_status ON trips(status);
CREATE INDEX idx_trips_date ON trips(trip_date);
CREATE INDEX idx_trip_stops_trip ON trip_stops(trip_id);
CREATE INDEX idx_payments_trip ON payments(trip_id);
CREATE INDEX idx_payments_status ON payments(status);
CREATE INDEX idx_messages_trip ON messages(trip_id);
CREATE INDEX idx_complaints_status ON complaints(status);

-- ============================================
-- SEED DATA: Sample POIs in Goa
-- ============================================

INSERT INTO pois (name, description, photo_urls, category, lat, lng, avg_visit_minutes, popularity_score, city) VALUES
('Fort Aguada', 'Historic 17th-century Portuguese fort with lighthouse and stunning Arabian Sea views', ARRAY['https://upload.wikimedia.org/wikipedia/commons/thumb/5/5e/Fort_Aguada%2CGoa.jpg/1280px-Fort_Aguada%2CGoa.jpg'], 'historical', 15.4909, 73.7732, 45, 9, 'Goa'),
('Baga Beach', 'Famous beach known for water sports, nightlife, and vibrant shacks', ARRAY['https://upload.wikimedia.org/wikipedia/commons/thumb/4/47/Baga_Beach_Goa.jpg/1280px-Baga_Beach_Goa.jpg'], 'beach', 15.5559, 73.7516, 60, 8, 'Goa'),
('Basilica of Bom Jesus', 'UNESCO World Heritage Site housing the remains of St. Francis Xavier', ARRAY['https://upload.wikimedia.org/wikipedia/commons/thumb/4/45/Basilica_of_Bom_Jesus%2C_Goa.jpg/1280px-Basilica_of_Bom_Jesus%2C_Goa.jpg'], 'religious', 15.5008, 73.9114, 40, 9, 'Goa'),
('Dudhsagar Waterfalls', 'Majestic four-tiered waterfall on the Mandovi River, one of India''s tallest', ARRAY['https://upload.wikimedia.org/wikipedia/commons/thumb/e/e3/Dudhsagar_Falls.jpg/800px-Dudhsagar_Falls.jpg'], 'nature', 15.3144, 74.3144, 90, 7, 'Goa'),
('Anjuna Flea Market', 'Iconic Wednesday flea market with handicrafts, jewelry, and local food', ARRAY['https://upload.wikimedia.org/wikipedia/commons/thumb/f/f1/Anjuna_beach_North_Goa.jpg/1280px-Anjuna_beach_North_Goa.jpg'], 'shopping', 15.5737, 73.7413, 60, 7, 'Goa'),
('Calangute Beach', 'Queen of Goa beaches — longest stretch with water sports and restaurants', ARRAY['https://upload.wikimedia.org/wikipedia/commons/thumb/6/62/Calangute_Beach_Goa_India.jpg/1280px-Calangute_Beach_Goa_India.jpg'], 'beach', 15.5441, 73.7553, 50, 8, 'Goa'),
('Se Cathedral', 'One of the largest churches in Asia, stunning Portuguese-Gothic architecture', ARRAY['https://upload.wikimedia.org/wikipedia/commons/thumb/3/38/Se_Cathedral%2C_Goa.jpg/1280px-Se_Cathedral%2C_Goa.jpg'], 'religious', 15.5039, 73.9126, 35, 7, 'Goa'),
('Chapora Fort', 'Famous hilltop fort with panoramic views, made iconic by Dil Chahta Hai', ARRAY['https://upload.wikimedia.org/wikipedia/commons/thumb/1/1f/Chapora_fort2.JPG/1280px-Chapora_fort2.JPG'], 'historical', 15.6044, 73.7371, 30, 8, 'Goa'),
('Palolem Beach', 'Crescent-shaped beach in South Goa known for its calm waters and beauty', ARRAY['https://upload.wikimedia.org/wikipedia/commons/thumb/d/dd/Palolem_Beach.jpg/1280px-Palolem_Beach.jpg'], 'beach', 15.0100, 74.0232, 60, 7, 'Goa'),
('Spice Plantation Tour', 'Walk through aromatic spice gardens with guided tastings and lunch', ARRAY['https://upload.wikimedia.org/wikipedia/commons/thumb/0/08/Spice_plantation_Goa.jpg/1024px-Spice_plantation_Goa.jpg'], 'nature', 15.4300, 74.0100, 75, 6, 'Goa');
