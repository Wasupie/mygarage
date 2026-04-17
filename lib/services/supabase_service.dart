import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/vehicle.dart';
import '../models/maintenance_record.dart';
import '../models/fuel_record.dart';
import '../models/modification_record.dart';

/// Supabase service for managing database operations
class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  /// Initialize Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
      debug: SupabaseConfig.debugMode,
    );
  }

  /// Check if user is authenticated
  static bool get isAuthenticated => client.auth.currentUser != null;

  /// Get current user ID
  static String? get userId => client.auth.currentUser?.id;

  // ==================== VEHICLE OPERATIONS ====================

  /// Insert a new vehicle
  Future<int> insertVehicle(Vehicle vehicle) async {
    final data = vehicle.toMap();
    data.remove('id'); // Let Supabase generate the ID

    final response = await client
        .from('vehicles')
        .insert(data)
        .select('id')
        .single();

    return response['id'] as int;
  }

  /// Get all vehicles for current user
  Future<List<Vehicle>> getAllVehicles() async {
    final response = await client
        .from('vehicles')
        .select()
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => Vehicle.fromMap(json as Map<String, dynamic>))
        .toList();
  }

  /// Get vehicle by ID
  Future<Vehicle?> getVehicle(int id) async {
    final response = await client
        .from('vehicles')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Vehicle.fromMap(response);
  }

  /// Update vehicle
  Future<void> updateVehicle(Vehicle vehicle) async {
    final data = vehicle.toMap();

    await client
        .from('vehicles')
        .update(data)
        .eq('id', vehicle.id!);
  }

  /// Delete vehicle (cascades to all related records)
  Future<void> deleteVehicle(int id) async {
    await client
        .from('vehicles')
        .delete()
        .eq('id', id);
  }

  // ==================== MAINTENANCE OPERATIONS ====================

  /// Insert maintenance record
  Future<int> insertMaintenanceRecord(MaintenanceRecord record) async {
    final data = record.toMap();
    data.remove('id');

    final response = await client
        .from('maintenance_records')
        .insert(data)
        .select('id')
        .single();

    return response['id'] as int;
  }

  /// Get all maintenance records for a vehicle
  Future<List<MaintenanceRecord>> getMaintenanceRecords(int vehicleId) async {
    final response = await client
        .from('maintenance_records')
        .select()
        .eq('vehicle_id', vehicleId)
        .order('date', ascending: false);

    return (response as List)
        .map((json) => MaintenanceRecord.fromMap(json as Map<String, dynamic>))
        .toList();
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
  Future<void> updateMaintenanceRecord(MaintenanceRecord record) async {
    final data = record.toMap();
    data.remove('vehicle_id'); // Don't allow changing vehicle_id

    await client
        .from('maintenance_records')
        .update(data)
        .eq('id', record.id!);
  }

  /// Delete maintenance record
  Future<void> deleteMaintenanceRecord(int id) async {
    await client
        .from('maintenance_records')
        .delete()
        .eq('id', id);
  }

  // ==================== FUEL OPERATIONS ====================

  /// Insert fuel record
  Future<int> insertFuelRecord(FuelRecord record) async {
    final data = record.toMap();
    data.remove('id');

    final response = await client
        .from('fuel_records')
        .insert(data)
        .select('id')
        .single();

    return response['id'] as int;
  }

  /// Get all fuel records for a vehicle
  Future<List<FuelRecord>> getFuelRecords(int vehicleId) async {
    final response = await client
        .from('fuel_records')
        .select()
        .eq('vehicle_id', vehicleId)
        .order('date', ascending: false);

    return (response as List)
        .map((json) => FuelRecord.fromMap(json as Map<String, dynamic>))
        .toList();
  }

  /// Get latest known mileage from fuel records for a vehicle
  Future<double?> getLatestFuelMileage(int vehicleId) async {
    final records = await getFuelRecords(vehicleId);
    for (final record in records) {
      if (record.mileage != null) {
        return record.mileage;
      }
    }
    return null;
  }

  /// Calculate average fuel efficiency for a vehicle
  Future<double?> getAverageFuelEfficiency(int vehicleId) async {
    final records = await getFuelRecords(vehicleId);
    return FuelRecord.calculateRobustAverageEfficiency(records);
  }

  /// Update fuel record
  Future<void> updateFuelRecord(FuelRecord record) async {
    final data = record.toMap();
    data.remove('vehicle_id');

    await client
        .from('fuel_records')
        .update(data)
        .eq('id', record.id!);
  }

  /// Delete fuel record
  Future<void> deleteFuelRecord(int id) async {
    await client
        .from('fuel_records')
        .delete()
        .eq('id', id);
  }

  // ==================== MODIFICATION OPERATIONS ====================

  /// Insert modification record
  Future<int> insertModificationRecord(ModificationRecord record) async {
    final data = record.toMap();
    data.remove('id');

    final response = await client
        .from('modification_records')
        .insert(data)
        .select('id')
        .single();

    return response['id'] as int;
  }

  /// Get all modification records for a vehicle
  Future<List<ModificationRecord>> getModificationRecords(int vehicleId) async {
    final response = await client
        .from('modification_records')
        .select()
        .eq('vehicle_id', vehicleId)
        .order('date', ascending: false);

    return (response as List)
        .map((json) => ModificationRecord.fromMap(json as Map<String, dynamic>))
        .toList();
  }

  /// Update modification record
  Future<void> updateModificationRecord(ModificationRecord record) async {
    final data = record.toMap();
    data.remove('vehicle_id');

    await client
        .from('modification_records')
        .update(data)
        .eq('id', record.id!);
  }

  /// Delete modification record
  Future<void> deleteModificationRecord(int id) async {
    await client
        .from('modification_records')
        .delete()
        .eq('id', id);
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

  // ==================== AUTHENTICATION ====================

  /// Sign in with email and password
  Future<void> signInWithEmail(String email, String password) async {
    await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign up with email and password
  Future<void> signUpWithEmail(String email, String password) async {
    await client.auth.signUp(
      email: email,
      password: password,
    );
  }

  /// Sign out
  Future<void> signOut() async {
    await client.auth.signOut();
  }

  /// Listen to auth state changes
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;
}
