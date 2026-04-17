import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/vehicle.dart';
import '../services/supabase_service.dart';

/// Screen for editing vehicle information
class EditVehicleScreen extends StatefulWidget {
  final Vehicle vehicle;

  const EditVehicleScreen({super.key, required this.vehicle});

  @override
  State<EditVehicleScreen> createState() => _EditVehicleScreenState();
}

class _EditVehicleScreenState extends State<EditVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final SupabaseService _dbService = SupabaseService();

  late final _nameController = TextEditingController(text: widget.vehicle.name);
  late final _modelController = TextEditingController(text: widget.vehicle.model);
  late final _plateController = TextEditingController(text: widget.vehicle.plateNumber);
  late final _engineController = TextEditingController(text: widget.vehicle.engineType);
  late final _mileageController = TextEditingController(
      text: widget.vehicle.initialMileage?.toString() ?? '');
  late final _notesController = TextEditingController(text: widget.vehicle.notes ?? '');

  late String _vehicleType = widget.vehicle.vehicleType;
  late DateTime? _purchaseDate = widget.vehicle.purchaseDate;

  @override
  void dispose() {
    _nameController.dispose();
    _modelController.dispose();
    _plateController.dispose();
    _engineController.dispose();
    _mileageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    final vehicle = Vehicle(
      id: widget.vehicle.id,
      name: _nameController.text.trim(),
      model: _modelController.text.trim(),
      plateNumber: _plateController.text.trim().toUpperCase(),
      engineType: _engineController.text.trim(),
      vehicleType: _vehicleType,
      initialMileage: _mileageController.text.isEmpty
          ? null
          : double.parse(_mileageController.text),
      purchaseDate: _purchaseDate,
      notes: _notesController.text.isEmpty ? null : _notesController.text.trim(),
    );

    await _dbService.updateVehicle(vehicle);

    if (mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vehicle updated successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Vehicle'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Vehicle type selector
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vehicle Type',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'car',
                          label: Text('Car'),
                          icon: Icon(Icons.directions_car),
                        ),
                        ButtonSegment(
                          value: 'motorcycle',
                          label: Text('Motorcycle'),
                          icon: Icon(Icons.two_wheeler),
                        ),
                      ],
                      selected: {_vehicleType},
                      onSelectionChanged: (Set<String> newSelection) {
                        setState(() => _vehicleType = newSelection.first);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label_outline),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _modelController,
              decoration: const InputDecoration(
                labelText: 'Model *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.car_repair),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter the model';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _plateController,
              decoration: const InputDecoration(
                labelText: 'Plate Number *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.confirmation_number_outlined),
              ),
              textCapitalization: TextCapitalization.characters,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter the plate number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _engineController,
              decoration: const InputDecoration(
                labelText: 'Engine Type *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.settings_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter the engine type';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _mileageController,
              decoration: const InputDecoration(
                labelText: 'Current Mileage (km)',
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
              onTap: _selectPurchaseDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Purchase Date',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  _purchaseDate == null
                      ? 'Not set'
                      : DateFormat('MMM dd, yyyy').format(_purchaseDate!),
                ),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: _saveVehicle,
              icon: const Icon(Icons.save),
              label: const Text('Update Vehicle'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectPurchaseDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _purchaseDate = picked);
    }
  }
}
