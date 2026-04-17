import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/fuel_record.dart';
import '../services/supabase_service.dart';
import '../services/notification_service.dart';

/// Screen for editing fuel records
class EditFuelScreen extends StatefulWidget {
  final FuelRecord record;

  const EditFuelScreen({super.key, required this.record});

  @override
  State<EditFuelScreen> createState() => _EditFuelScreenState();
}

class _EditFuelScreenState extends State<EditFuelScreen> {
  final _formKey = GlobalKey<FormState>();
  final SupabaseService _dbService = SupabaseService();

  late final _litersController =
      TextEditingController(text: widget.record.liters.toString());
  late final _costController = TextEditingController(text: widget.record.cost.toString());
  late final _mileageController = TextEditingController(
      text: widget.record.mileage?.toString() ?? '');

  late DateTime _date = widget.record.date;
  late String? _petrolStation = widget.record.petrolStation;

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
    super.dispose();
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) return;

    final enteredMileage = _mileageController.text.isEmpty
      ? null
      : double.parse(_mileageController.text);

    final record = FuelRecord(
      id: widget.record.id,
      vehicleId: widget.record.vehicleId,
      liters: double.parse(_litersController.text),
      cost: double.parse(_costController.text),
      date: _date,
      mileage: enteredMileage,
      petrolStation: _petrolStation,
    );

    await _dbService.updateFuelRecord(record);

    // Best-effort: mileage-based alerts use the odometer from fuel records.
    try {
      final latestMileage = await _dbService.getLatestFuelMileage(record.vehicleId);
      if (latestMileage != null) {
        final vehicle = await _dbService.getVehicle(record.vehicleId);
        final maintenance = await _dbService.getMaintenanceRecords(record.vehicleId);
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
        const SnackBar(content: Text('Fuel record updated successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Fuel Record'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              value: _petrolStation,
              decoration: const InputDecoration(
                labelText: 'Petrol Station',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.local_gas_station),
              ),
              items: _petrolStations.map((station) {
                return DropdownMenuItem(
                  value: station,
                  child: Text(station),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _petrolStation = value);
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _litersController,
              decoration: const InputDecoration(
                labelText: 'Liters *',
                suffixText: 'L',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.local_drink_outlined),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter the liters';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _costController,
              decoration: const InputDecoration(
                labelText: 'Cost *',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
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

            InkWell(
              onTap: _selectDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(DateFormat('MMM dd, yyyy').format(_date)),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _mileageController,
              decoration: const InputDecoration(
                labelText: 'Mileage (km)',
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
            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: _saveRecord,
              icon: const Icon(Icons.save),
              label: const Text('Update Record'),
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
    if (picked != null) {
      setState(() => _date = picked);
    }
  }
}
