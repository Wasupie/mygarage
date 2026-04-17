# Quick Setup - No Authentication Required

## ⚠️ IMPORTANT: Update Database Schema

You have the old schema with authentication. You need to run the new one!

### Step 1: Drop Old Tables (in Supabase SQL Editor)

```sql
DROP TABLE IF EXISTS modification_records CASCADE;
DROP TABLE IF EXISTS fuel_records CASCADE;
DROP TABLE IF EXISTS maintenance_records CASCADE;
DROP TABLE IF EXISTS vehicles CASCADE;
```

### Step 2: Run New Schema

Open `supabase_schema_no_auth.sql` and run it in Supabase SQL Editor.

This new schema:
- ✅ **No user_id required** in vehicles table
- ✅ **No authentication needed** - RLS is disabled
- ✅ **Works for personal use** immediately

## Step 3: Restart App

```bash
flutter run
```

## What Changed?

### Before (with auth):
```sql
CREATE TABLE vehicles (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id), -- ❌ Required auth
    ...
);
ALTER TABLE vehicles ENABLE ROW LEVEL SECURITY; -- ❌ Blocked access
```

### After (no auth):
```sql
CREATE TABLE vehicles (
    id BIGSERIAL PRIMARY KEY,
    -- ✅ No user_id field
    name TEXT NOT NULL,
    ...
);
ALTER TABLE vehicles DISABLE ROW LEVEL SECURITY; -- ✅ Open access
```

## All screens now use Supabase:
- ✅ HomeScreen
- ✅ AddVehicleScreen  
- ✅ VehicleDetailScreen
- ✅ AddMaintenanceScreen
- ✅ AddFuelScreen
- ✅ AddModificationScreen

Data will now be stored in Supabase automatically! 🎉
