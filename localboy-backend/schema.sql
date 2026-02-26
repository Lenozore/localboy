CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone VARCHAR(15) UNIQUE NOT NULL,
    name VARCHAR(255),
    email VARCHAR(255),
    role VARCHAR(20) DEFAULT 'tourist',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE pois (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    image_url TEXT,
    category VARCHAR(50),
    lat DECIMAL(10, 8) NOT NULL,
    lng DECIMAL(11, 8) NOT NULL,
    avg_visit_minutes INT DEFAULT 60,
    priority INT DEFAULT 5,
    city VARCHAR(100) DEFAULT 'Goa',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE bookings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id),
    booking_code VARCHAR(10) UNIQUE,
    trip_date DATE NOT NULL,
    start_time TIME NOT NULL,
    package_type VARCHAR(20) NOT NULL,
    hotel_address TEXT NOT NULL,
    hotel_lat DECIMAL(10, 8) NOT NULL,
    hotel_lng DECIMAL(11, 8) NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    total_amount DECIMAL(10, 2) DEFAULT 1499.00,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE itineraries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_id UUID REFERENCES bookings(id) ON DELETE CASCADE,
    poi_id UUID REFERENCES pois(id),
    stop_order INT,
    estimated_arrival TIME,
    status VARCHAR(50) DEFAULT 'pending',
    UNIQUE(booking_id, stop_order)
);

CREATE INDEX idx_bookings_user ON bookings(user_id);
CREATE INDEX idx_bookings_status ON bookings(status);
CREATE INDEX idx_pois_city ON pois(city);
CREATE INDEX idx_itineraries_booking ON itineraries(booking_id);

INSERT INTO pois (name, description, image_url, category, lat, lng, avg_visit_minutes, priority, city) VALUES
('Fort Aguada', 'Historic Portuguese fort with stunning sea views', 'https://images.unsplash.com/photo-1590079537579-63e0c2c9be3a?w=800', 'historical', 15.4909, 73.7732, 45, 9, 'Goa'),
('Baga Beach', 'Famous beach known for water sports and nightlife', 'https://images.unsplash.com/photo-1559827260-dc66d52bef19?w=800', 'beach', 15.5559, 73.7516, 60, 8, 'Goa'),
('Basilica of Bom Jesus', 'UNESCO World Heritage church', 'https://images.unsplash.com/photo-1587135941948-670b381f08ce?w=800', 'religious', 15.5008, 73.9114, 40, 9, 'Goa'),
('Dudhsagar Waterfalls', 'Majestic four-tiered waterfall', 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800', 'nature', 15.3144, 74.3144, 90, 7, 'Goa');
```
