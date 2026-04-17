import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/modification_record.dart';
import '../services/supabase_service.dart';

/// Screen for adding a modification record
class AddModificationScreen extends StatefulWidget {
  final int vehicleId;

  const AddModificationScreen({super.key, required this.vehicleId});

  @override
  State<AddModificationScreen> createState() => _AddModificationScreenState();
}

class _AddModificationScreenState extends State<AddModificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final SupabaseService _dbService = SupabaseService();

  final _descriptionController = TextEditingController();
  final _brandController = TextEditingController();
  final _partNumberController = TextEditingController();
  final _costController = TextEditingController();
  final _performanceImpactController = TextEditingController();
  final _fuelEfficiencyImpactController = TextEditingController();
  final _notesController = TextEditingController();

  String _type = 'Performance';
  DateTime _date = DateTime.now();

  final List<String> _modificationTypes = [
    'Performance',
    'Aesthetic',
    'Audio',
    'Suspension',
    'Exhaust',
    'Interior',
    'Lighting',
    'Wheels',
    'Other',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    _brandController.dispose();
    _partNumberController.dispose();
    _costController.dispose();
    _performanceImpactController.dispose();
    _fuelEfficiencyImpactController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) return;

    final record = ModificationRecord(
      vehicleId: widget.vehicleId,
      type: _type,
      description: _descriptionController.text.trim(),
      brand: _brandController.text.isEmpty ? null : _brandController.text.trim(),
      partNumber: _partNumberController.text.isEmpty ? null : _partNumberController.text.trim(),
      date: _date,
      cost: double.parse(_costController.text),
      impactOnPerformance: _performanceImpactController.text.isEmpty
          ? null
          : _performanceImpactController.text.trim(),
      impactOnFuelEfficiency: _fuelEfficiencyImpactController.text.isEmpty
          ? null
          : _fuelEfficiencyImpactController.text.trim(),
      notes: _notesController.text.isEmpty ? null : _notesController.text.trim(),
    );

    await _dbService.insertModificationRecord(record);

    if (mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Modification added')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Modification'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Type dropdown
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(
                labelText: 'Modification Type *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.tune),
              ),
              items: _modificationTypes.map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (value) => setState(() => _type = value!),
            ),
            const SizedBox(height: 16),

            // Description field
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description *',
                hintText: 'e.g., Turbo upgrade, Custom exhaust',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Brand field
            TextFormField(
              controller: _brandController,
              decoration: const InputDecoration(
                labelText: 'Brand/Manufacturer',
                hintText: 'e.g., HKS, Bride, Recaro',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            // Part number field
            TextFormField(
              controller: _partNumberController,
              decoration: const InputDecoration(
                labelText: 'Part Number/Model',
                hintText: 'e.g., TD05H-16G',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.tag),
              ),
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

            // Impact section
            Text(
              'Impact (Optional)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),

            // Performance impact field
            TextFormField(
              controller: _performanceImpactController,
              decoration: const InputDecoration(
                labelText: 'Performance Impact',
                hintText: 'e.g., +15 HP, Better acceleration',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.trending_up),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            // Fuel efficiency impact field
            TextFormField(
              controller: _fuelEfficiencyImpactController,
              decoration: const InputDecoration(
                labelText: 'Fuel Efficiency Impact',
                hintText: 'e.g., -1 km/L, No change',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.eco),
              ),
              textCapitalization: TextCapitalization.sentences,
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
              label: const Text('Save Modification'),
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
