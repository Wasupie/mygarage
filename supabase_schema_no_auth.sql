-- MyGarage Supabase Database Schema (Without Authentication)
-- For personal use - no user authentication required
-- Run this in your Supabase SQL Editor

-- Enable UUID extension (if not already enabled)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Drop existing tables if they exist (be careful - this deletes all data!)
DROP TABLE IF EXISTS modification_records CASCADE;
DROP TABLE IF EXISTS fuel_records CASCADE;
DROP TABLE IF EXISTS maintenance_records CASCADE;
DROP TABLE IF EXISTS vehicles CASCADE;

-- ============================================
-- VEHICLES TABLE (No user_id required)
-- ============================================
CREATE TABLE vehicles (
    id BIGSERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    model TEXT NOT NULL,
    plate_number TEXT NOT NULL,
    engine_type TEXT NOT NULL,
    vehicle_type TEXT NOT NULL CHECK (vehicle_type IN ('car', 'motorcycle')),
    initial_mileage DECIMAL(10, 2),
    purchase_date TIMESTAMPTZ,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- MAINTENANCE RECORDS TABLE
-- ============================================
CREATE TABLE maintenance_records (
    id BIGSERIAL PRIMARY KEY,
    vehicle_id BIGINT NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
    type TEXT NOT NULL,
    product_name TEXT,
    date TIMESTAMPTZ NOT NULL,
    mileage DECIMAL(10, 2),
    cost DECIMAL(10, 2) NOT NULL,
    notes TEXT,
    next_due_date TIMESTAMPTZ,
    next_due_mileage DECIMAL(10, 2),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- FUEL RECORDS TABLE
-- ============================================
CREATE TABLE fuel_records (
    id BIGSERIAL PRIMARY KEY,
    vehicle_id BIGINT NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
    date TIMESTAMPTZ NOT NULL,
    liters DECIMAL(10, 2) NOT NULL,
    cost DECIMAL(10, 2) NOT NULL,
    mileage DECIMAL(10, 2),
    is_full_tank BOOLEAN NOT NULL DEFAULT true,
    petrol_station TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- MODIFICATION RECORDS TABLE
-- ============================================
CREATE TABLE modification_records (
    id BIGSERIAL PRIMARY KEY,
    vehicle_id BIGINT NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
    type TEXT NOT NULL,
    description TEXT NOT NULL,
    brand TEXT,
    part_number TEXT,
    date TIMESTAMPTZ NOT NULL,
    cost DECIMAL(10, 2) NOT NULL,
    impact_on_performance TEXT,
    impact_on_fuel_efficiency TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- INDEXES FOR PERFORMANCE
-- ============================================
CREATE INDEX idx_maintenance_vehicle_id ON maintenance_records(vehicle_id);
CREATE INDEX idx_maintenance_date ON maintenance_records(date DESC);
CREATE INDEX idx_fuel_vehicle_id ON fuel_records(vehicle_id);
CREATE INDEX idx_fuel_date ON fuel_records(date DESC);
CREATE INDEX idx_modification_vehicle_id ON modification_records(vehicle_id);
CREATE INDEX idx_modification_date ON modification_records(date DESC);

-- ============================================
-- DISABLE ROW LEVEL SECURITY (For personal use)
-- This allows anyone with the API key to access the data
-- ============================================
ALTER TABLE vehicles DISABLE ROW LEVEL SECURITY;
ALTER TABLE maintenance_records DISABLE ROW LEVEL SECURITY;
ALTER TABLE fuel_records DISABLE ROW LEVEL SECURITY;
ALTER TABLE modification_records DISABLE ROW LEVEL SECURITY;

-- ============================================
-- TRIGGERS FOR UPDATED_AT TIMESTAMPS
-- ============================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to all tables
CREATE TRIGGER update_vehicles_updated_at
    BEFORE UPDATE ON vehicles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_maintenance_records_updated_at
    BEFORE UPDATE ON maintenance_records
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_fuel_records_updated_at
    BEFORE UPDATE ON fuel_records
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_modification_records_updated_at
    BEFORE UPDATE ON modification_records
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- USEFUL VIEWS (OPTIONAL)
-- ============================================

-- View for vehicle statistics
CREATE OR REPLACE VIEW vehicle_statistics AS
SELECT 
    v.id,
    v.name,
    v.model,
    v.plate_number,
    COUNT(DISTINCT m.id) as maintenance_count,
    COALESCE(SUM(m.cost), 0) as total_maintenance_cost,
    COUNT(DISTINCT f.id) as fuel_count,
    COALESCE(SUM(f.cost), 0) as total_fuel_cost,
    COUNT(DISTINCT mod.id) as modification_count,
    COALESCE(SUM(mod.cost), 0) as total_modification_cost
FROM vehicles v
LEFT JOIN maintenance_records m ON v.id = m.vehicle_id
LEFT JOIN fuel_records f ON v.id = f.vehicle_id
LEFT JOIN modification_records mod ON v.id = mod.vehicle_id
GROUP BY v.id, v.name, v.model, v.plate_number;
