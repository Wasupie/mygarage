import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/maintenance_record.dart';
import '../services/supabase_service.dart';
import '../services/notification_service.dart';
import '../data/maintenance_templates.dart';
import '../utils/date_time_utils.dart';

/// Screen for adding a maintenance record
class AddMaintenanceScreen extends StatefulWidget {
  final int vehicleId;
  final String vehicleName;

  const AddMaintenanceScreen({
    super.key,
    required this.vehicleId,
    required this.vehicleName,
  });

  @override
  State<AddMaintenanceScreen> createState() => _AddMaintenanceScreenState();
}

class _AddMaintenanceScreenState extends State<AddMaintenanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final SupabaseService _dbService = SupabaseService();

  final _costController = TextEditingController();
  final _mileageController = TextEditingController();
  final _productNameController = TextEditingController();
  final _notesController = TextEditingController();
  final _nextDueMileageController = TextEditingController();
  final _intervalMonthsController = TextEditingController();
  final _intervalKmController = TextEditingController();

  String _type = 'Oil Change';
  DateTime _date = DateTime.now();
  DateTime? _nextDueDate;
  String? _selectedTemplateId;

  final List<String> _maintenanceTypes = [
    'Oil Change',
    'Brake Service',
    'Tire Rotation',
    'Spark Plugs',
    'Air Filter',
    'Transmission Service',
    'Battery Replacement',
    'Chain Maintenance',
    'Other',
  ];

  @override
  void dispose() {
    _costController.dispose();
    _mileageController.dispose();
    _productNameController.dispose();
    _notesController.dispose();
    _nextDueMileageController.dispose();
    _intervalMonthsController.dispose();
    _intervalKmController.dispose();
    super.dispose();
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) return;

    final intervalMonths = int.tryParse(_intervalMonthsController.text.trim());
    final intervalKm = double.tryParse(_intervalKmController.text.trim());

    final nextDueDate = _nextDueDate ??
      (intervalMonths != null && intervalMonths > 0
        ? addMonths(_date, intervalMonths)
        : null);

    final double? nextDueMileage = _nextDueMileageController.text.isNotEmpty
      ? double.parse(_nextDueMileageController.text)
      : (intervalKm != null &&
          intervalKm > 0 &&
          _mileageController.text.isNotEmpty
        ? (double.parse(_mileageController.text) + intervalKm)
        : null);

    final record = MaintenanceRecord(
      vehicleId: widget.vehicleId,
      type: _type,
      productName: _productNameController.text.isEmpty ? null : _productNameController.text.trim(),
      date: _date,
      mileage: _mileageController.text.isEmpty
          ? null
          : double.parse(_mileageController.text),
      cost: double.parse(_costController.text),
      notes: _notesController.text.isEmpty ? null : _notesController.text.trim(),
      nextDueDate: nextDueDate,
      nextDueMileage: nextDueMileage,
    );

    final insertedId = await _dbService.insertMaintenanceRecord(record);

    final recordWithId = MaintenanceRecord(
      id: insertedId,
      vehicleId: record.vehicleId,
      type: record.type,
      productName: record.productName,
      date: record.date,
      mileage: record.mileage,
      cost: record.cost,
      notes: record.notes,
      nextDueDate: record.nextDueDate,
      nextDueMileage: record.nextDueMileage,
    );

    // Best-effort: schedule reminders.
    try {
      await NotificationService.scheduleNextDueDateReminders(
        vehicleName: widget.vehicleName,
        record: recordWithId,
      );

      // Oil-change cadence reminders are based on the latest oil record.
      if (recordWithId.type.trim().toLowerCase().contains('oil')) {
        final all = await _dbService.getMaintenanceRecords(widget.vehicleId);
        MaintenanceRecord? latestOil;
        for (final r in all) {
          final t = r.type.trim().toLowerCase();
          if (!(t == 'oil change' || t.contains('oil'))) continue;
          if (latestOil == null) {
            latestOil = r;
            continue;
          }
          if (r.date.isAfter(latestOil.date)) {
            latestOil = r;
          }
        }
        await NotificationService.scheduleOilChangeReminders(
          vehicleId: widget.vehicleId,
          vehicleName: widget.vehicleName,
          latestOilChange: latestOil,
        );
      }
    } catch (_) {
      // Ignore notification errors.
    }

    if (mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maintenance record added')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Maintenance'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String?>(
              initialValue: _selectedTemplateId,
              decoration: const InputDecoration(
                labelText: 'Template (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.auto_awesome_outlined),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('None'),
                ),
                ...builtInMaintenanceTemplates.map(
                  (t) => DropdownMenuItem<String?>(
                    value: t.id,
                    child: Text(t.label),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedTemplateId = value;
                  if (value == null) return;
                  for (final t in builtInMaintenanceTemplates) {
                    if (t.id != value) continue;
                    _type = t.type;
                    _intervalMonthsController.text = t.intervalMonths?.toString() ?? '';
                    _intervalKmController.text =
                        t.intervalKm == null ? '' : t.intervalKm!.toStringAsFixed(0);
                    break;
                  }
                });
              },
            ),
            const SizedBox(height: 16),

            // Type dropdown
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(
                labelText: 'Maintenance Type *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.build),
              ),
              items: _maintenanceTypes.map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (value) => setState(() => _type = value!),
            ),
            const SizedBox(height: 16),

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

            // Product name field
            TextFormField(
              controller: _productNameController,
              decoration: const InputDecoration(
                labelText: 'Product Name',
                hintText: 'e.g., Castrol Edge 5W-30',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.inventory_2_outlined),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            // Mileage field
            TextFormField(
              controller: _mileageController,
              decoration: const InputDecoration(
                labelText: 'Current Mileage (km)',
                hintText: 'Optional',
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
            const SizedBox(height: 24),

            Text(
              'Assistant (Optional)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _intervalMonthsController,
              decoration: const InputDecoration(
                labelText: 'Interval (months)',
                hintText: 'Optional',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_month_outlined),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final parsed = int.tryParse(value);
                  if (parsed == null || parsed <= 0) {
                    return 'Enter a valid number of months';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _intervalKmController,
              decoration: const InputDecoration(
                labelText: 'Interval (km)',
                hintText: 'Optional',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.speed),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final parsed = double.tryParse(value);
                  if (parsed == null || parsed <= 0) {
                    return 'Enter a valid km interval';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            Text(
              'If you leave “Next Due” empty, the app will auto-calculate it using the interval.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),

            // Next due section
            Text(
              'Next Service Due (Optional)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),

            // Next due date
            InkWell(
              onTap: _selectNextDueDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Next Due Date',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.event),
                ),
                child: Text(
                  _nextDueDate == null
                      ? 'Not set'
                      : DateFormat('MMM dd, yyyy').format(_nextDueDate!),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Next due mileage
            TextFormField(
              controller: _nextDueMileageController,
              decoration: const InputDecoration(
                labelText: 'Next Due Mileage (km)',
                hintText: 'Optional',
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

  Future<void> _selectNextDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _nextDueDate ?? DateTime.now().add(const Duration(days: 90)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() => _nextDueDate = picked);
    }
  }
}
