import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../models/vehicle.dart';
import '../models/maintenance_record.dart';
import '../models/fuel_record.dart';
import '../models/modification_record.dart';
import '../services/supabase_service.dart';
import '../services/notification_service.dart';
import '../widgets/stat_card.dart';
import '../widgets/record_details_sheet.dart';
import '../theme/app_theme.dart';
import 'add_maintenance_screen.dart';
import 'add_fuel_screen.dart';
import 'add_modification_screen.dart';
import 'edit_vehicle_screen.dart';
import 'edit_maintenance_screen.dart';
import 'edit_fuel_screen.dart';
import 'edit_modification_screen.dart';

/// Vehicle detail screen showing all records and stats
class VehicleDetailScreen extends StatefulWidget {
  final Vehicle vehicle;

  const VehicleDetailScreen({super.key, required this.vehicle});

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen>
    with SingleTickerProviderStateMixin {
  final SupabaseService _dbService = SupabaseService();
  late TabController _tabController;
  int _selectedTabIndex = 0;

  List<MaintenanceRecord> _maintenanceRecords = [];
  List<FuelRecord> _fuelRecords = [];
  List<ModificationRecord> _modificationRecords = [];
  
  double _totalMaintenanceCost = 0;
  double _totalFuelCost = 0;
  double _totalModificationCost = 0;
  double? _avgFuelEfficiency;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectedTabIndex = _tabController.index;
    _tabController.addListener(() {
      if (!mounted) return;
      if (_tabController.indexIsChanging) return;
      final nextIndex = _tabController.index;
      if (nextIndex == _selectedTabIndex) return;
      setState(() => _selectedTabIndex = nextIndex);
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final results = await Future.wait([
        _dbService.getMaintenanceRecords(widget.vehicle.id!),
        _dbService.getFuelRecords(widget.vehicle.id!),
        _dbService.getModificationRecords(widget.vehicle.id!),
      ]);

      final maintenance = results[0] as List<MaintenanceRecord>;
      final fuel = results[1] as List<FuelRecord>;
      final modifications = results[2] as List<ModificationRecord>;

      final maintenanceCost =
          maintenance.fold<double>(0.0, (sum, record) => sum + record.cost);
      final fuelCost = fuel.fold<double>(0.0, (sum, record) => sum + record.cost);
      final modificationCost =
          modifications.fold<double>(0.0, (sum, record) => sum + record.cost);

      final avgEfficiency = FuelRecord.calculateRobustAverageEfficiency(fuel);

      if (!mounted) return;
      setState(() {
        _maintenanceRecords = maintenance;
        _fuelRecords = fuel;
        _modificationRecords = modifications;
        _totalMaintenanceCost = maintenanceCost;
        _totalFuelCost = fuelCost;
        _totalModificationCost = modificationCost;
        _avgFuelEfficiency = avgEfficiency;
        _isLoading = false;
      });

      // Best-effort: keep scheduled notifications in sync.
      unawaited(NotificationService.syncVehicleMaintenanceReminders(
        vehicle: widget.vehicle,
        maintenanceRecords: maintenance,
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load vehicle data.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.vehicle.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: _editVehicle,
            tooltip: 'Edit Vehicle',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _confirmDelete,
            tooltip: 'Delete Vehicle',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Vehicle header card
                _buildHeaderCard(),
                // Summary (depends on current tab)
                _buildTabSummary(),
                // Tabs
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Maintenance', icon: Icon(Icons.build)),
                    Tab(text: 'Fuel', icon: Icon(Icons.local_gas_station)),
                    Tab(text: 'Mods', icon: Icon(Icons.tune)),
                  ],
                ),
                // Tab views
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildMaintenanceTab(),
                      _buildFuelTab(),
                      _buildModificationsTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  widget.vehicle.vehicleType == 'car'
                      ? Icons.directions_car
                      : Icons.two_wheeler,
                  size: 40,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.vehicle.model,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        widget.vehicle.plateNumber,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        widget.vehicle.engineType,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabSummary() {
    final semantic = context.semanticColors;

    Widget single(StatCard card) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [Expanded(child: card)],
        ),
      );
    }

    Widget double(StatCard left, StatCard right) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(child: left),
            const SizedBox(width: 8),
            Expanded(child: right),
          ],
        ),
      );
    }

    if (_selectedTabIndex == 0) {
      return single(
        StatCard(
          title: 'Maintenance',
          value: 'RM ${_totalMaintenanceCost.toStringAsFixed(0)}',
          icon: Icons.build,
          color: semantic.maintenance,
        ),
      );
    }

    if (_selectedTabIndex == 1) {
      return double(
        StatCard(
          title: 'Fuel Cost',
          value: 'RM ${_totalFuelCost.toStringAsFixed(0)}',
          icon: Icons.local_gas_station,
          color: semantic.fuel,
        ),
        StatCard(
          title: 'Avg Efficiency',
          value: _avgFuelEfficiency != null
              ? '${_avgFuelEfficiency!.toStringAsFixed(1)} km/L'
              : 'N/A',
          icon: Icons.speed,
          hint: 'Outliers filtered',
        ),
      );
    }

    return single(
      StatCard(
        title: 'Modifications',
        value: 'RM ${_totalModificationCost.toStringAsFixed(0)}',
        icon: Icons.tune,
        color: semantic.modifications,
      ),
    );
  }

  Widget _buildMaintenanceTab() {
    if (_maintenanceRecords.isEmpty) {
      return _buildEmptyState(
        'No maintenance records',
        Icons.build_outlined,
        _addMaintenance,
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: _maintenanceRecords.length,
            itemBuilder: (context, index) {
              final record = _maintenanceRecords[index];
              final maintenanceDetails = <String>[];
              final productName = record.productName?.trim();
              if (productName != null && productName.isNotEmpty) {
                maintenanceDetails.add(productName);
              }
              if (record.mileage != null) {
                maintenanceDetails.add('${record.mileage!.toStringAsFixed(0)} km');
              }

              return RecordCard(
                title: record.type,
                subtitle: maintenanceDetails.isEmpty
                    ? 'No details'
                    : maintenanceDetails.join(' • '),
                date: record.date,
                cost: record.cost,
                icon: Icons.build,
                onTap: () => _viewMaintenanceRecord(record),
                onEdit: () => _editMaintenanceRecord(record),
                onDelete: () => _deleteMaintenanceRecord(record),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: _addMaintenance,
            icon: const Icon(Icons.add),
            label: const Text('Add Maintenance'),
          ),
        ),
      ],
    );
  }

  Widget _buildFuelTab() {
    if (_fuelRecords.isEmpty) {
      return _buildEmptyState(
        'No fuel records',
        Icons.local_gas_station_outlined,
        _addFuel,
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: _fuelRecords.length,
            itemBuilder: (context, index) {
              final record = _fuelRecords[index];
              return RecordCard(
                title: '${record.liters.toStringAsFixed(1)} L',
                subtitle: record.mileage != null
                    ? '${record.mileage!.toStringAsFixed(0)} km'
                    : 'No mileage',
                date: record.date,
                cost: record.cost,
                icon: Icons.local_gas_station,
                iconColor: context.semanticColors.fuel,
                onTap: () => _viewFuelRecord(record),
                onEdit: () => _editFuelRecord(record),
                onDelete: () => _deleteFuelRecord(record.id!),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: _addFuel,
            icon: const Icon(Icons.add),
            label: const Text('Add Fuel'),
          ),
        ),
      ],
    );
  }

  Widget _buildModificationsTab() {
    if (_modificationRecords.isEmpty) {
      return _buildEmptyState(
        'No modifications',
        Icons.tune_outlined,
        _addModification,
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: _modificationRecords.length,
            itemBuilder: (context, index) {
              final record = _modificationRecords[index];
              return RecordCard(
                title: record.description,
                subtitle: record.type,
                date: record.date,
                cost: record.cost,
                icon: Icons.tune,
                iconColor: context.semanticColors.modifications,
                onTap: () => _viewModificationRecord(record),
                onEdit: () => _editModificationRecord(record),
                onDelete: () => _deleteModificationRecord(record.id!),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: _addModification,
            icon: const Icon(Icons.add),
            label: const Text('Add Modification'),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message, IconData icon, VoidCallback onAdd) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add First Record'),
          ),
        ],
      ),
    );
  }

  Future<void> _addMaintenance() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddMaintenanceScreen(
          vehicleId: widget.vehicle.id!,
          vehicleName: widget.vehicle.name,
        ),
      ),
    );
    if (result == true) _loadData();
  }

  Future<void> _addFuel() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddFuelScreen(vehicleId: widget.vehicle.id!),
      ),
    );
    if (result == true) _loadData();
  }

  Future<void> _addModification() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddModificationScreen(vehicleId: widget.vehicle.id!),
      ),
    );
    if (result == true) _loadData();
  }

  Future<void> _editVehicle() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditVehicleScreen(vehicle: widget.vehicle),
      ),
    );
    if (result == true) {
      _loadData();
      if (mounted) {
        // Refresh the parent screen to update vehicle name in list
        Navigator.pop(context, true);
      }
    }
  }

  Future<void> _editMaintenanceRecord(MaintenanceRecord record) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditMaintenanceScreen(
          record: record,
          vehicleName: widget.vehicle.name,
        ),
      ),
    );
    if (result == true) _loadData();
  }

  Future<void> _editFuelRecord(FuelRecord record) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditFuelScreen(record: record),
      ),
    );
    if (result == true) _loadData();
  }

  Future<void> _editModificationRecord(ModificationRecord record) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditModificationScreen(record: record),
      ),
    );
    if (result == true) _loadData();
  }

  void _viewMaintenanceRecord(MaintenanceRecord record) {
    final df = DateFormat('MMM dd, yyyy');

    final items = <RecordDetailsItem>[
      RecordDetailsItem(label: 'Type', value: record.type),
      RecordDetailsItem(label: 'Date', value: df.format(record.date)),
      RecordDetailsItem(label: 'Cost', value: 'RM ${record.cost.toStringAsFixed(2)}'),
      RecordDetailsItem(
        label: 'Product',
        value: (record.productName == null || record.productName!.trim().isEmpty)
            ? '—'
            : record.productName!.trim(),
      ),
      RecordDetailsItem(
        label: 'Mileage',
        value: record.mileage == null ? '—' : '${record.mileage!.toStringAsFixed(0)} km',
      ),
      RecordDetailsItem(
        label: 'Next due date',
        value: record.nextDueDate == null ? '—' : df.format(record.nextDueDate!),
      ),
      RecordDetailsItem(
        label: 'Next due mileage',
        value: record.nextDueMileage == null
            ? '—'
            : '${record.nextDueMileage!.toStringAsFixed(0)} km',
      ),
      RecordDetailsItem(
        label: 'Notes',
        value: (record.notes == null || record.notes!.trim().isEmpty)
            ? '—'
            : record.notes!.trim(),
      ),
    ];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return RecordDetailsSheet(
          title: 'Maintenance details',
          sections: [
            RecordDetailsSection(items: items),
          ],
        );
      },
    );
  }

  void _viewFuelRecord(FuelRecord record) {
    final df = DateFormat('MMM dd, yyyy');
    final items = <RecordDetailsItem>[
      RecordDetailsItem(label: 'Date', value: df.format(record.date)),
      RecordDetailsItem(label: 'Liters', value: '${record.liters.toStringAsFixed(2)} L'),
      RecordDetailsItem(label: 'Cost', value: 'RM ${record.cost.toStringAsFixed(2)}'),
      RecordDetailsItem(
        label: 'Cost per liter',
        value: 'RM ${record.costPerLiter.toStringAsFixed(2)}',
      ),
      RecordDetailsItem(
        label: 'Mileage',
        value: record.mileage == null ? '—' : '${record.mileage!.toStringAsFixed(0)} km',
      ),
      RecordDetailsItem(label: 'Full tank', value: record.isFullTank ? 'Yes' : 'No'),
      RecordDetailsItem(
        label: 'Station',
        value: (record.petrolStation == null || record.petrolStation!.trim().isEmpty)
            ? '—'
            : record.petrolStation!.trim(),
      ),
      RecordDetailsItem(
        label: 'Notes',
        value: (record.notes == null || record.notes!.trim().isEmpty)
            ? '—'
            : record.notes!.trim(),
      ),
    ];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return RecordDetailsSheet(
          title: 'Fuel details',
          sections: [RecordDetailsSection(items: items)],
        );
      },
    );
  }

  void _viewModificationRecord(ModificationRecord record) {
    final df = DateFormat('MMM dd, yyyy');
    final items = <RecordDetailsItem>[
      RecordDetailsItem(label: 'Type', value: record.type),
      RecordDetailsItem(label: 'Description', value: record.description),
      RecordDetailsItem(label: 'Date', value: df.format(record.date)),
      RecordDetailsItem(label: 'Cost', value: 'RM ${record.cost.toStringAsFixed(2)}'),
      RecordDetailsItem(
        label: 'Brand',
        value: (record.brand == null || record.brand!.trim().isEmpty)
            ? '—'
            : record.brand!.trim(),
      ),
      RecordDetailsItem(
        label: 'Part number',
        value: (record.partNumber == null || record.partNumber!.trim().isEmpty)
            ? '—'
            : record.partNumber!.trim(),
      ),
      RecordDetailsItem(
        label: 'Performance impact',
        value: (record.impactOnPerformance == null || record.impactOnPerformance!.trim().isEmpty)
            ? '—'
            : record.impactOnPerformance!.trim(),
      ),
      RecordDetailsItem(
        label: 'Fuel efficiency impact',
        value: (record.impactOnFuelEfficiency == null || record.impactOnFuelEfficiency!.trim().isEmpty)
            ? '—'
            : record.impactOnFuelEfficiency!.trim(),
      ),
      RecordDetailsItem(
        label: 'Notes',
        value: (record.notes == null || record.notes!.trim().isEmpty)
            ? '—'
            : record.notes!.trim(),
      ),
    ];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return RecordDetailsSheet(
          title: 'Modification details',
          sections: [RecordDetailsSection(items: items)],
        );
      },
    );
  }

  Future<void> _deleteMaintenanceRecord(MaintenanceRecord record) async {
    final confirmed = await _confirmDeleteDialog('maintenance record');
    if (confirmed == true) {
      if (record.id != null) {
        try {
          await NotificationService.cancelNextDueDateRemindersForMaintenanceRecord(
            record.id!,
          );
        } catch (_) {
          // Ignore notification errors.
        }
      }

      await _dbService.deleteMaintenanceRecord(record.id!);
      _loadData();
    }
  }

  Future<void> _deleteFuelRecord(int id) async {
    final confirmed = await _confirmDeleteDialog('fuel record');
    if (confirmed == true) {
      await _dbService.deleteFuelRecord(id);
      _loadData();
    }
  }

  Future<void> _deleteModificationRecord(int id) async {
    final confirmed = await _confirmDeleteDialog('modification');
    if (confirmed == true) {
      await _dbService.deleteModificationRecord(id);
      _loadData();
    }
  }

  Future<bool?> _confirmDeleteDialog(String item) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete?'),
        content: Text('Are you sure you want to delete this $item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Vehicle?'),
        content: Text(
          'Are you sure you want to delete ${widget.vehicle.name}? This will also delete all associated records.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _dbService.deleteVehicle(widget.vehicle.id!);
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vehicle deleted')),
        );
      }
    }
  }
}
