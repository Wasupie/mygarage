import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/vehicle.dart';
import '../services/supabase_service.dart';

/// Screen for adding a new vehicle
class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final SupabaseService _dbService = SupabaseService();

  // Form controllers
  final _nameController = TextEditingController();
  final _modelController = TextEditingController();
  final _plateController = TextEditingController();
  final _engineController = TextEditingController();
  final _mileageController = TextEditingController();
  final _notesController = TextEditingController();

  String _vehicleType = 'car';
  DateTime? _purchaseDate;

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

    await _dbService.insertVehicle(vehicle);

    if (mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vehicle added successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Vehicle'),
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

            // Name field
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name *',
                hintText: 'e.g., My Kancil',
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

            // Model field
            TextFormField(
              controller: _modelController,
              decoration: const InputDecoration(
                labelText: 'Model *',
                hintText: 'e.g., Perodua Kancil 850',
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

            // Plate number field
            TextFormField(
              controller: _plateController,
              decoration: const InputDecoration(
                labelText: 'Plate Number *',
                hintText: 'e.g., ABC1234',
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

            // Engine type field
            TextFormField(
              controller: _engineController,
              decoration: const InputDecoration(
                labelText: 'Engine Type *',
                hintText: 'e.g., 850cc EFI',
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

            // Current mileage field
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

            // Purchase date field
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
                      ? 'Optional'
                      : DateFormat('MMM dd, yyyy').format(_purchaseDate!),
                ),
              ),
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
              onPressed: _saveVehicle,
              icon: const Icon(Icons.save),
              label: const Text('Save Vehicle'),
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
    if (picked != null && picked != _purchaseDate) {
      setState(() => _purchaseDate = picked);
    }
  }
}
