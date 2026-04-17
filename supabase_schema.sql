-- MyGarage Supabase Database Schema
-- Run this in your Supabase SQL Editor to create all necessary tables

-- Enable UUID extension (if not already enabled)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- VEHICLES TABLE
-- ============================================
CREATE TABLE vehicles (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
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
CREATE INDEX idx_vehicles_user_id ON vehicles(user_id);
CREATE INDEX idx_maintenance_vehicle_id ON maintenance_records(vehicle_id);
CREATE INDEX idx_maintenance_date ON maintenance_records(date DESC);
CREATE INDEX idx_fuel_vehicle_id ON fuel_records(vehicle_id);
CREATE INDEX idx_fuel_date ON fuel_records(date DESC);
CREATE INDEX idx_modification_vehicle_id ON modification_records(vehicle_id);
CREATE INDEX idx_modification_date ON modification_records(date DESC);

-- ============================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================

-- Enable RLS on all tables
ALTER TABLE vehicles ENABLE ROW LEVEL SECURITY;
ALTER TABLE maintenance_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE fuel_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE modification_records ENABLE ROW LEVEL SECURITY;

-- Vehicles policies
CREATE POLICY "Users can view their own vehicles"
    ON vehicles FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own vehicles"
    ON vehicles FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own vehicles"
    ON vehicles FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own vehicles"
    ON vehicles FOR DELETE
    USING (auth.uid() = user_id);

-- Maintenance records policies
CREATE POLICY "Users can view maintenance records of their vehicles"
    ON maintenance_records FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM vehicles 
        WHERE vehicles.id = maintenance_records.vehicle_id 
        AND vehicles.user_id = auth.uid()
    ));

CREATE POLICY "Users can insert maintenance records for their vehicles"
    ON maintenance_records FOR INSERT
    WITH CHECK (EXISTS (
        SELECT 1 FROM vehicles 
        WHERE vehicles.id = maintenance_records.vehicle_id 
        AND vehicles.user_id = auth.uid()
    ));

CREATE POLICY "Users can update maintenance records of their vehicles"
    ON maintenance_records FOR UPDATE
    USING (EXISTS (
        SELECT 1 FROM vehicles 
        WHERE vehicles.id = maintenance_records.vehicle_id 
        AND vehicles.user_id = auth.uid()
    ));

CREATE POLICY "Users can delete maintenance records of their vehicles"
    ON maintenance_records FOR DELETE
    USING (EXISTS (
        SELECT 1 FROM vehicles 
        WHERE vehicles.id = maintenance_records.vehicle_id 
        AND vehicles.user_id = auth.uid()
    ));

-- Fuel records policies
CREATE POLICY "Users can view fuel records of their vehicles"
    ON fuel_records FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM vehicles 
        WHERE vehicles.id = fuel_records.vehicle_id 
        AND vehicles.user_id = auth.uid()
    ));

CREATE POLICY "Users can insert fuel records for their vehicles"
    ON fuel_records FOR INSERT
    WITH CHECK (EXISTS (
        SELECT 1 FROM vehicles 
        WHERE vehicles.id = fuel_records.vehicle_id 
        AND vehicles.user_id = auth.uid()
    ));

CREATE POLICY "Users can update fuel records of their vehicles"
    ON fuel_records FOR UPDATE
    USING (EXISTS (
        SELECT 1 FROM vehicles 
        WHERE vehicles.id = fuel_records.vehicle_id 
        AND vehicles.user_id = auth.uid()
    ));

CREATE POLICY "Users can delete fuel records of their vehicles"
    ON fuel_records FOR DELETE
    USING (EXISTS (
        SELECT 1 FROM vehicles 
        WHERE vehicles.id = fuel_records.vehicle_id 
        AND vehicles.user_id = auth.uid()
    ));

-- Modification records policies
CREATE POLICY "Users can view modification records of their vehicles"
    ON modification_records FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM vehicles 
        WHERE vehicles.id = modification_records.vehicle_id 
        AND vehicles.user_id = auth.uid()
    ));

CREATE POLICY "Users can insert modification records for their vehicles"
    ON modification_records FOR INSERT
    WITH CHECK (EXISTS (
        SELECT 1 FROM vehicles 
        WHERE vehicles.id = modification_records.vehicle_id 
        AND vehicles.user_id = auth.uid()
    ));

CREATE POLICY "Users can update modification records of their vehicles"
    ON modification_records FOR UPDATE
    USING (EXISTS (
        SELECT 1 FROM vehicles 
        WHERE vehicles.id = modification_records.vehicle_id 
        AND vehicles.user_id = auth.uid()
    ));

CREATE POLICY "Users can delete modification records of their vehicles"
    ON modification_records FOR DELETE
    USING (EXISTS (
        SELECT 1 FROM vehicles 
        WHERE vehicles.id = modification_records.vehicle_id 
        AND vehicles.user_id = auth.uid()
    ));

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

-- ============================================
-- SAMPLE DATA (OPTIONAL - FOR TESTING)
-- ============================================
/*
-- Insert sample vehicle (replace user_id with your actual user ID)
INSERT INTO vehicles (user_id, name, model, plate_number, engine_type, vehicle_type, initial_mileage)
VALUES 
    ('your-user-uuid-here', 'My Kancil', 'Perodua Kancil 850', 'ABC1234', '850cc EFI', 'car', 50000);

-- Get the vehicle ID and insert sample records
-- (You'll need to replace vehicle_id values with actual IDs)
*/
