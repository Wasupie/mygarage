import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/maintenance_record.dart';
import '../services/supabase_service.dart';
import '../services/notification_service.dart';

/// Screen for editing maintenance records
class EditMaintenanceScreen extends StatefulWidget {
  final MaintenanceRecord record;
  final String vehicleName;

  const EditMaintenanceScreen({
    super.key,
    required this.record,
    required this.vehicleName,
  });

  @override
  State<EditMaintenanceScreen> createState() => _EditMaintenanceScreenState();
}

class _EditMaintenanceScreenState extends State<EditMaintenanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final SupabaseService _dbService = SupabaseService();

  late final _typeController = TextEditingController(text: widget.record.type);
  late final _notesController =
      TextEditingController(text: widget.record.notes ?? '');
  late final _costController = TextEditingController(text: widget.record.cost.toString());
  late final _mileageController = TextEditingController(
      text: widget.record.mileage?.toString() ?? '');
  late final _productNameController =
      TextEditingController(text: widget.record.productName ?? '');
    late final _nextDueMileageController = TextEditingController(
      text: widget.record.nextDueMileage?.toString() ?? '');

  late DateTime _date = widget.record.date;
  late DateTime? _nextDueDate = widget.record.nextDueDate;

  @override
  void dispose() {
    _typeController.dispose();
    _notesController.dispose();
    _costController.dispose();
    _mileageController.dispose();
    _productNameController.dispose();
    _nextDueMileageController.dispose();
    super.dispose();
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) return;

    final record = MaintenanceRecord(
      id: widget.record.id,
      vehicleId: widget.record.vehicleId,
      type: _typeController.text.trim(),
      notes: _notesController.text.isEmpty
          ? null
          : _notesController.text.trim(),
      cost: double.parse(_costController.text),
      date: _date,
      mileage: _mileageController.text.isEmpty
          ? null
          : double.parse(_mileageController.text),
      nextDueDate: _nextDueDate,
      nextDueMileage: _nextDueMileageController.text.isEmpty
          ? null
          : double.parse(_nextDueMileageController.text),
      productName: _productNameController.text.isEmpty
          ? null
          : _productNameController.text.trim(),
    );

    await _dbService.updateMaintenanceRecord(record);

    // Best-effort: update scheduled reminders.
    try {
      await NotificationService.scheduleNextDueDateReminders(
        vehicleName: widget.vehicleName,
        record: record,
      );

      final t = record.type.trim().toLowerCase();
      if (t == 'oil change' || t.contains('oil')) {
        final all = await _dbService.getMaintenanceRecords(record.vehicleId);
        MaintenanceRecord? latestOil;
        for (final r in all) {
          final rt = r.type.trim().toLowerCase();
          if (!(rt == 'oil change' || rt.contains('oil'))) continue;
          if (latestOil == null) {
            latestOil = r;
            continue;
          }
          if (r.date.isAfter(latestOil.date)) {
            latestOil = r;
          }
        }
        await NotificationService.scheduleOilChangeReminders(
          vehicleId: record.vehicleId,
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
        const SnackBar(content: Text('Maintenance record updated successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Maintenance'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _typeController,
              decoration: const InputDecoration(
                labelText: 'Service Type *',
                hintText: 'e.g., Oil Change, Brake Pads, Tire Rotation',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.build_outlined),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter the service type';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _productNameController,
              decoration: const InputDecoration(
                labelText: 'Product Name',
                hintText: 'e.g., Castrol Edge 5W-30, Brembo Brake Pads',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.shopping_bag_outlined),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes_outlined),
              ),
              maxLines: 3,
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
                  labelText: 'Service Date',
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
            const SizedBox(height: 16),

            InkWell(
              onTap: _selectNextDueDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Next Due Date',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.event),
                  suffixIcon: Icon(Icons.clear),
                ),
                child: Text(
                  _nextDueDate == null
                      ? 'Not set'
                      : DateFormat('MMM dd, yyyy').format(_nextDueDate!),
                ),
              ),
            ),
            if (_nextDueDate != null) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => setState(() => _nextDueDate = null),
                icon: const Icon(Icons.clear),
                label: const Text('Clear next due date'),
              ),
            ],
            const SizedBox(height: 16),

            TextFormField(
              controller: _nextDueMileageController,
              decoration: const InputDecoration(
                labelText: 'Next Due Mileage (km)',
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
