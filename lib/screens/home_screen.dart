import 'package:flutter/material.dart';
import 'dart:async';
import '../models/vehicle.dart';
import '../services/supabase_service.dart';
import '../services/notification_service.dart';
import '../widgets/vehicle_card.dart';
import 'add_vehicle_screen.dart';
import 'vehicle_detail_screen.dart';
import 'upcoming_screen.dart';

/// Home screen displaying all vehicles
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SupabaseService _dbService = SupabaseService();
  List<Vehicle> _vehicles = [];
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }

    try {
      final vehicles = await _dbService.getAllVehicles();
      if (!mounted) return;
      setState(() {
        _vehicles = vehicles;
        _isLoading = false;
      });

      // Refresh scheduled reminders in the background.
      unawaited(_syncMaintenanceNotifications(vehicles));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _vehicles = [];
        _isLoading = false;
        _loadError = 'Could not load vehicles. Check your internet connection.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_loadError!)),
      );
    }
  }

  Future<void> _syncMaintenanceNotifications(List<Vehicle> vehicles) async {
    // Best-effort only.
    try {
      const batchSize = 3;
      final withIds = vehicles.where((v) => v.id != null).toList(growable: false);

      for (var i = 0; i < withIds.length; i += batchSize) {
        final batch = withIds.skip(i).take(batchSize);
        await Future.wait(
          batch.map((vehicle) async {
            final maintenance = await _dbService.getMaintenanceRecords(vehicle.id!);
            await NotificationService.syncVehicleMaintenanceReminders(
              vehicle: vehicle,
              maintenanceRecords: maintenance,
            );
          }),
        );
      }
    } catch (_) {
      // Ignore notification scheduling failures.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Garage'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _navigateToUpcoming,
            icon: const Icon(Icons.event_outlined),
            tooltip: 'Upcoming',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? _buildErrorState(_loadError!)
          : _vehicles.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadVehicles,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _vehicles.length,
                    itemBuilder: (context, index) {
                      final vehicle = _vehicles[index];
                      return VehicleCard(
                        vehicle: vehicle,
                        onTap: () => _navigateToVehicleDetail(vehicle),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddVehicle,
        icon: const Icon(Icons.add),
        label: const Text('Add Vehicle'),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 80,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadVehicles,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.garage_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No vehicles yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first vehicle to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _navigateToAddVehicle,
            icon: const Icon(Icons.add),
            label: const Text('Add Vehicle'),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToAddVehicle() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddVehicleScreen()),
    );
    if (result == true) {
      _loadVehicles();
    }
  }

  Future<void> _navigateToVehicleDetail(Vehicle vehicle) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VehicleDetailScreen(vehicle: vehicle),
      ),
    );
    if (result == true) {
      _loadVehicles();
    }
  }

  Future<void> _navigateToUpcoming() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UpcomingScreen()),
    );
  }
}
