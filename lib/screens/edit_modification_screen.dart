import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/modification_record.dart';
import '../services/supabase_service.dart';

/// Screen for editing modification records
class EditModificationScreen extends StatefulWidget {
  final ModificationRecord record;

  const EditModificationScreen({super.key, required this.record});

  @override
  State<EditModificationScreen> createState() => _EditModificationScreenState();
}

class _EditModificationScreenState extends State<EditModificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final SupabaseService _dbService = SupabaseService();

  late final _typeController = TextEditingController(text: widget.record.type);
  late final _descriptionController =
      TextEditingController(text: widget.record.description);
  late final _costController = TextEditingController(text: widget.record.cost.toString());
  late final _brandController =
      TextEditingController(text: widget.record.brand ?? '');
  late final _partNumberController =
      TextEditingController(text: widget.record.partNumber ?? '');

  late DateTime _date = widget.record.date;

  @override
  void dispose() {
    _typeController.dispose();
    _descriptionController.dispose();
    _costController.dispose();
    _brandController.dispose();
    _partNumberController.dispose();
    super.dispose();
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) return;

    final record = ModificationRecord(
      id: widget.record.id,
      vehicleId: widget.record.vehicleId,
      type: _typeController.text.trim(),
      description: _descriptionController.text.trim(),
      cost: double.parse(_costController.text),
      date: _date,
      brand: _brandController.text.isEmpty ? null : _brandController.text.trim(),
      partNumber: _partNumberController.text.isEmpty
          ? null
          : _partNumberController.text.trim(),
    );

    await _dbService.updateModificationRecord(record);

    if (mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Modification record updated successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Modification'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _typeController,
              decoration: const InputDecoration(
                labelText: 'Modification Type *',
                hintText: 'e.g., Turbo Upgrade, Exhaust System, Suspension',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.build_outlined),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter the modification type';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _brandController,
              decoration: const InputDecoration(
                labelText: 'Brand/Manufacturer',
                hintText: 'e.g., HKS, Bride, Recaro',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.store_outlined),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _partNumberController,
              decoration: const InputDecoration(
                labelText: 'Part Number/Model',
                hintText: 'e.g., TD05H-16G',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.tag_outlined),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description_outlined),
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
                  labelText: 'Installation Date',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(DateFormat('MMM dd, yyyy').format(_date)),
              ),
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
