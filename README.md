# MyGarage - Vehicle Maintenance Tracker

A minimalist yet powerful Flutter app to track your vehicle maintenance, fuel consumption, and modifications.

## Features

### 🚗 Vehicle Profiles
- Add multiple vehicles (cars and motorcycles)
- Track model, engine type, plate number, and more
- Store purchase date and initial mileage

### 🔧 Service & Repair Logs
- Record maintenance activities (oil changes, brake service, tire rotation, etc.)
- Track date, mileage, cost, and notes for each service
- Set reminders for upcoming maintenance by date or mileage
- View maintenance history chronologically

### ⛽ Fuel Tracking
- Log fuel refills with liters, cost, and mileage
- Automatic fuel efficiency calculation (km/L)
- Full tank indicator for accurate calculations
- View fuel cost trends

### 🎨 Modifications Log
- Track vehicle upgrades and customizations
- Record performance and fuel efficiency impact
- Categorize modifications by type (Performance, Aesthetic, Audio, etc.)
- Monitor total investment in modifications

### 📊 Statistics & Reports
- View total costs per vehicle (maintenance, fuel, modifications)
- Calculate average fuel efficiency
- Track spending across all categories
- Visual statistics on vehicle detail screen

## Project Structure

```
lib/
├── main.dart                           # App entry point
├── models/
│   ├── vehicle.dart                    # Vehicle data model
│   ├── maintenance_record.dart         # Maintenance record model
│   ├── fuel_record.dart                # Fuel record model
│   └── modification_record.dart        # Modification record model
├── screens/
│   ├── home_screen.dart                # Main screen with vehicle list
│   ├── vehicle_detail_screen.dart      # Vehicle details with tabs
│   ├── add_vehicle_screen.dart         # Add new vehicle form
│   ├── add_maintenance_screen.dart     # Add maintenance record
│   ├── add_fuel_screen.dart            # Add fuel record
│   └── add_modification_screen.dart    # Add modification record
├── widgets/
│   ├── vehicle_card.dart               # Reusable vehicle card
│   └── stat_card.dart                  # Statistics and record cards
└── services/
    └── database_service.dart           # SQLite database service
```

## Dependencies

- **sqflite**: Local SQLite database for data persistence
- **path_provider**: Access device file system
- **intl**: Date formatting and internationalization
- **provider**: State management (future use)
- **fl_chart**: Charts and graphs for reports
- **flutter_local_notifications**: Maintenance reminders

## Getting Started

### Prerequisites
- Flutter SDK 3.10.1 or higher
- Dart SDK
- Android Studio / Xcode (for mobile development)

### Installation

1. Clone or download this repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app:
   ```bash
   flutter run
   ```

### Usage

1. **Add a Vehicle**: Tap the "Add Vehicle" button on the home screen
2. **View Details**: Tap any vehicle card to see full details
3. **Add Records**: Use the tabs (Maintenance, Fuel, Mods) and tap "Add" buttons
4. **Track Statistics**: View costs and efficiency at the top of vehicle details
5. **Delete Records**: Tap the delete icon on any record card

## Design Philosophy

The app follows a **minimalist but usable** design approach:

- Clean, modern Material Design 3 UI
- Intuitive navigation with clear visual hierarchy
- Essential features without clutter
- Dark mode support
- Consistent iconography and spacing
- Form validation for data integrity

## Code Quality

The codebase is structured for:
- **Readability**: Clear naming conventions and comments
- **Maintainability**: Modular architecture with separation of concerns
- **Scalability**: Easy to extend with new features
- **Type Safety**: Comprehensive Dart models with null safety

## Future Enhancements

- Push notifications for maintenance reminders
- Charts and graphs for fuel efficiency trends
- Export data to CSV/PDF
- Cloud backup and sync
- Multiple language support
- Photo attachments for records
- Cost comparison between vehicles

## License

This project is created for personal use and learning purposes.

## Support

For issues or questions, please refer to the code documentation or create an issue in the repository.
