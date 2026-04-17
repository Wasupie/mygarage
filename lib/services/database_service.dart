import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/vehicle.dart';
import '../models/maintenance_record.dart';
import '../models/fuel_record.dart';
import '../models/modification_record.dart';

/// Database service for managing SQLite operations
class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'mygarage.db';
  static const int _databaseVersion = 1;

  /// Get database instance (singleton pattern)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    // Vehicles table
    await db.execute('''
      CREATE TABLE vehicles(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        model TEXT NOT NULL,
        plateNumber TEXT NOT NULL,
        engineType TEXT NOT NULL,
        vehicleType TEXT NOT NULL,
        initialMileage REAL,
        purchaseDate TEXT,
        notes TEXT
      )
    ''');

    // Maintenance records table
    await db.execute('''
      CREATE TABLE maintenance_records(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicleId INTEGER NOT NULL,
        type TEXT NOT NULL,
        date TEXT NOT NULL,
        mileage REAL,
        cost REAL NOT NULL,
        notes TEXT,
        nextDueDate TEXT,
        nextDueMileage REAL,
        FOREIGN KEY(vehicleId) REFERENCES vehicles(id) ON DELETE CASCADE
      )
    ''');

    // Fuel records table
    await db.execute('''
      CREATE TABLE fuel_records(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicleId INTEGER NOT NULL,
        date TEXT NOT NULL,
        liters REAL NOT NULL,
        cost REAL NOT NULL,
        mileage REAL,
        isFullTank INTEGER NOT NULL,
        notes TEXT,
        FOREIGN KEY(vehicleId) REFERENCES vehicles(id) ON DELETE CASCADE
      )
    ''');

    // Modification records table
    await db.execute('''
      CREATE TABLE modification_records(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicleId INTEGER NOT NULL,
        type TEXT NOT NULL,
        description TEXT NOT NULL,
        date TEXT NOT NULL,
        cost REAL NOT NULL,
        impactOnPerformance TEXT,
        impactOnFuelEfficiency TEXT,
        notes TEXT,
        FOREIGN KEY(vehicleId) REFERENCES vehicles(id) ON DELETE CASCADE
      )
    ''');
  }

  // ==================== VEHICLE OPERATIONS ====================

  /// Insert a new vehicle
  Future<int> insertVehicle(Vehicle vehicle) async {
    final db = await database;
    return await db.insert('vehicles', vehicle.toMap());
  }

  /// Get all vehicles
  Future<List<Vehicle>> getAllVehicles() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('vehicles');
    return List.generate(maps.length, (i) => Vehicle.fromMap(maps[i]));
  }

  /// Get vehicle by ID
  Future<Vehicle?> getVehicle(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'vehicles',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Vehicle.fromMap(maps.first);
  }

  /// Update vehicle
  Future<int> updateVehicle(Vehicle vehicle) async {
    final db = await database;
    return await db.update(
      'vehicles',
      vehicle.toMap(),
      where: 'id = ?',
      whereArgs: [vehicle.id],
    );
  }

  /// Delete vehicle (and all associated records)
  Future<int> deleteVehicle(int id) async {
    final db = await database;
    return await db.delete('vehicles', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== MAINTENANCE OPERATIONS ====================

  /// Insert maintenance record
  Future<int> insertMaintenanceRecord(MaintenanceRecord record) async {
    final db = await database;
    return await db.insert('maintenance_records', record.toMap());
  }

  /// Get all maintenance records for a vehicle
  Future<List<MaintenanceRecord>> getMaintenanceRecords(int vehicleId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'maintenance_records',
      where: 'vehicleId = ?',
      whereArgs: [vehicleId],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => MaintenanceRecord.fromMap(maps[i]));
  }

  /// Get upcoming/overdue maintenance for a vehicle
  Future<List<MaintenanceRecord>> getUpcomingMaintenance(
    int vehicleId,
    double currentMileage,
  ) async {
    final records = await getMaintenanceRecords(vehicleId);
    return records.where((record) {
      return record.isDueSoon(currentMileage) || record.isOverdue(currentMileage);
    }).toList();
  }

  /// Update maintenance record
  Future<int> updateMaintenanceRecord(MaintenanceRecord record) async {
    final db = await database;
    return await db.update(
      'maintenance_records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  /// Delete maintenance record
  Future<int> deleteMaintenanceRecord(int id) async {
    final db = await database;
    return await db.delete('maintenance_records', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== FUEL OPERATIONS ====================

  /// Insert fuel record
  Future<int> insertFuelRecord(FuelRecord record) async {
    final db = await database;
    return await db.insert('fuel_records', record.toMap());
  }

  /// Get all fuel records for a vehicle
  Future<List<FuelRecord>> getFuelRecords(int vehicleId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'fuel_records',
      where: 'vehicleId = ?',
      whereArgs: [vehicleId],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => FuelRecord.fromMap(maps[i]));
  }

  /// Calculate average fuel efficiency for a vehicle
  Future<double?> getAverageFuelEfficiency(int vehicleId) async {
    final records = await getFuelRecords(vehicleId);
    return FuelRecord.calculateRobustAverageEfficiency(records);
  }

  /// Update fuel record
  Future<int> updateFuelRecord(FuelRecord record) async {
    final db = await database;
    return await db.update(
      'fuel_records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  /// Delete fuel record
  Future<int> deleteFuelRecord(int id) async {
    final db = await database;
    return await db.delete('fuel_records', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== MODIFICATION OPERATIONS ====================

  /// Insert modification record
  Future<int> insertModificationRecord(ModificationRecord record) async {
    final db = await database;
    return await db.insert('modification_records', record.toMap());
  }

  /// Get all modification records for a vehicle
  Future<List<ModificationRecord>> getModificationRecords(int vehicleId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'modification_records',
      where: 'vehicleId = ?',
      whereArgs: [vehicleId],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => ModificationRecord.fromMap(maps[i]));
  }

  /// Update modification record
  Future<int> updateModificationRecord(ModificationRecord record) async {
    final db = await database;
    return await db.update(
      'modification_records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  /// Delete modification record
  Future<int> deleteModificationRecord(int id) async {
    final db = await database;
    return await db.delete('modification_records', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== STATISTICS ====================

  /// Get total maintenance cost for a vehicle
  Future<double> getTotalMaintenanceCost(int vehicleId) async {
    final records = await getMaintenanceRecords(vehicleId);
    return records.fold<double>(0.0, (sum, record) => sum + record.cost);
  }

  /// Get total fuel cost for a vehicle
  Future<double> getTotalFuelCost(int vehicleId) async {
    final records = await getFuelRecords(vehicleId);
    return records.fold<double>(0.0, (sum, record) => sum + record.cost);
  }

  /// Get total modification cost for a vehicle
  Future<double> getTotalModificationCost(int vehicleId) async {
    final records = await getModificationRecords(vehicleId);
    return records.fold<double>(0.0, (sum, record) => sum + record.cost);
  }

  /// Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
