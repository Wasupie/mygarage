# Edit Features Guide

## Overview
The MyGarage app now supports full CRUD (Create, Read, Update, Delete) operations for all entities:
- ✅ Vehicles
- ✅ Maintenance Records
- ✅ Fuel Records
- ✅ Modification Records

## New Features Added

### 1. Edit Vehicle Information
**Location:** Vehicle Detail Screen → Top right "Edit" button

**Editable Fields:**
- Name (e.g., "My Honda")
- Model (e.g., "Civic Type R 2023")
- Plate Number (auto-capitalized)
- Engine Type (e.g., "2.0L Turbo")
- Vehicle Type (Car/Motorcycle toggle)
- Current Mileage
- Purchase Date
- Notes

### 2. Edit Maintenance Records
**Location:** Vehicle Detail Screen → Maintenance Tab → Each record has an "Edit" icon button

**Editable Fields:**
- Service Type (e.g., "Oil Change", "Brake Service")
- **Product Name** (NEW - e.g., "Castrol Edge 5W-30", "Brembo Brake Pads")
- Notes
- Cost
- Service Date
- Mileage at service
- Next Due Date (can be cleared)

### 3. Edit Fuel Records
**Location:** Vehicle Detail Screen → Fuel Tab → Each record has an "Edit" icon button

**Editable Fields:**
- **Petrol Station** (NEW - Dropdown with Shell, Petronas, Petron, Caltex, Five, BHP, Other)
- Liters refilled
- Cost
- Refill Date
- Mileage at refill

### 4. Edit Modification Records
**Location:** Vehicle Detail Screen → Mods Tab → Each record has an "Edit" icon button

**Editable Fields:**
- Modification Type (e.g., "Turbo Upgrade", "Exhaust System")
- **Brand/Manufacturer** (NEW - e.g., "HKS", "Bride", "Recaro")
- **Part Number/Model** (NEW - e.g., "TD05H-16G")
- Description (required)
- Cost
- Installation Date

## UI Updates

### RecordCard Widget
Each record card now shows two action buttons:
1. **Edit Button** (pencil icon) - Opens edit screen with pre-filled data
2. **Delete Button** (trash icon) - Deletes the record after confirmation

Both buttons are color-coded:
- Edit: Primary color (blue)
- Delete: Error color (red)

### Vehicle Detail Screen
- New "Edit" button in the AppBar (next to Delete button)
- Editing vehicle info navigates back to home screen on save to refresh the vehicle list

## Database Schema Updates

The following fields have been added to the database schema:

### maintenance_records table:
```sql
product_name TEXT  -- Product/brand used
```

### fuel_records table:
```sql
petrol_station TEXT  -- Shell, Petronas, Petron, Caltex, Five, BHP, Other
```

### modification_records table:
```sql
brand TEXT         -- Brand/manufacturer
part_number TEXT   -- Part number or model
```

## Migration Steps

To use the new fields, you need to update your Supabase database:

1. Open Supabase Dashboard → Your Project
2. Go to "SQL Editor"
3. Run the migration from `supabase_schema_no_auth.sql`
4. Or manually add the columns:

```sql
-- Add product_name to maintenance_records
ALTER TABLE maintenance_records 
ADD COLUMN product_name TEXT;

-- Add petrol_station to fuel_records
ALTER TABLE fuel_records 
ADD COLUMN petrol_station TEXT;

-- Add brand and part_number to modification_records
ALTER TABLE modification_records 
ADD COLUMN brand TEXT,
ADD COLUMN part_number TEXT;
```

## Usage Tips

### Best Practices:
1. **Product Names**: Be consistent with naming (e.g., always use "Castrol Edge 5W-30" not variations)
2. **Petrol Stations**: Use the dropdown to maintain consistent data
3. **Modification Details**: Fill in brand and part number for better tracking and future reference
4. **Edit vs Delete**: Use edit to fix mistakes, only delete if the record was entered by accident

### Data Validation:
- All required fields must be filled before saving
- Numeric fields (cost, mileage, liters) are validated
- Dates are selected via date picker to avoid format errors
- Plate numbers are automatically converted to uppercase

## Technical Implementation

### New Screens Created:
- `edit_vehicle_screen.dart` - Edit vehicle information
- `edit_maintenance_screen.dart` - Edit maintenance records
- `edit_fuel_screen.dart` - Edit fuel records
- `edit_modification_screen.dart` - Edit modification records

### Updated Files:
- `vehicle_detail_screen.dart` - Added edit navigation methods
- `stat_card.dart` - RecordCard widget now supports onEdit callback
- All model classes updated with new fields
- SupabaseService already had update methods

## Future Enhancements

Potential improvements for next version:
- [ ] Bulk edit for multiple records
- [ ] Edit history/audit log
- [ ] Undo last edit
- [ ] Duplicate record function
- [ ] Export records to CSV/Excel
- [ ] Search and filter before editing
