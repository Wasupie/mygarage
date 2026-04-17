import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/fuel_record.dart';
import '../services/supabase_service.dart';
import '../services/notification_service.dart';

/// Screen for adding a fuel record
class AddFuelScreen extends StatefulWidget {
  final int vehicleId;

  const AddFuelScreen({super.key, required this.vehicleId});

  @override
  State<AddFuelScreen> createState() => _AddFuelScreenState();
}

class _AddFuelScreenState extends State<AddFuelScreen> {
  final _formKey = GlobalKey<FormState>();
  final SupabaseService _dbService = SupabaseService();

  final _litersController = TextEditingController();
  final _costController = TextEditingController();
  final _mileageController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _date = DateTime.now();
  bool _isFullTank = true;
  String? _petrolStation;

  final List<String> _petrolStations = [
    'Shell',
    'Petronas',
    'Petron',
    'Caltex',
    'Five',
    'BHP',
    'Other',
  ];

  @override
  void dispose() {
    _litersController.dispose();
    _costController.dispose();
    _mileageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) return;

    final enteredMileage = _mileageController.text.isEmpty
      ? null
      : double.parse(_mileageController.text);

    final record = FuelRecord(
      vehicleId: widget.vehicleId,
      date: _date,
      liters: double.parse(_litersController.text),
      cost: double.parse(_costController.text),
      mileage: enteredMileage,
      isFullTank: _isFullTank,
      petrolStation: _petrolStation,
      notes: _notesController.text.isEmpty ? null : _notesController.text.trim(),
    );

    await _dbService.insertFuelRecord(record);

    // Best-effort: mileage-based alerts use the odometer from fuel records.
    try {
      final latestMileage = await _dbService.getLatestFuelMileage(widget.vehicleId);
      if (latestMileage != null) {
        final vehicle = await _dbService.getVehicle(widget.vehicleId);
        final maintenance = await _dbService.getMaintenanceRecords(widget.vehicleId);
        await NotificationService.syncMileageBasedMaintenanceAlerts(
          vehicleName: vehicle?.name ?? 'Vehicle',
          currentMileage: latestMileage,
          maintenanceRecords: maintenance,
        );
      }
    } catch (_) {
      // Ignore notification errors.
    }

    if (mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fuel record added')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Fuel'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Date picker
            InkWell(
              onTap: _selectDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(DateFormat('MMM dd, yyyy').format(_date)),
              ),
            ),
            const SizedBox(height: 16),

            // Liters field
            TextFormField(
              controller: _litersController,
              decoration: const InputDecoration(
                labelText: 'Liters *',
                hintText: '0.0',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.local_gas_station),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter liters';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Cost field
            TextFormField(
              controller: _costController,
              decoration: const InputDecoration(
                labelText: 'Cost (RM) *',
                hintText: '0.00',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter the cost';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Mileage field
            TextFormField(
              controller: _mileageController,
              decoration: const InputDecoration(
                labelText: 'Current Mileage (km)',
                hintText: 'Optional (needed for efficiency calc)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.speed),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Petrol station dropdown
            DropdownButtonFormField<String>(
              value: _petrolStation,
              decoration: const InputDecoration(
                labelText: 'Petrol Station',
                hintText: 'Select station',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.local_gas_station),
              ),
              items: _petrolStations.map((station) {
                return DropdownMenuItem(value: station, child: Text(station));
              }).toList(),
              onChanged: (value) => setState(() => _petrolStation = value),
            ),
            const SizedBox(height: 16),

            // Full tank switch
            SwitchListTile(
              title: const Text('Full Tank'),
              subtitle: const Text('Required for accurate fuel efficiency'),
              value: _isFullTank,
              onChanged: (value) => setState(() => _isFullTank = value),
              secondary: const Icon(Icons.oil_barrel),
            ),
            const SizedBox(height: 8),

            // Notes field
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Optional notes',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Save button
            FilledButton.icon(
              onPressed: _saveRecord,
              icon: const Icon(Icons.save),
              label: const Text('Save Record'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _date) {
      setState(() => _date = picked);
    }
  }
}
