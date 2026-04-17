/// Modification record for tracking vehicle upgrades and changes
class ModificationRecord {
  final int? id;
  final int vehicleId;
  final String type; // 'Performance', 'Aesthetic', 'Audio', etc.
  final String description;
  final String? brand; // Brand/manufacturer of the part
  final String? partNumber; // Part number or model
  final DateTime date;
  final double cost;
  final String? impactOnPerformance;
  final String? impactOnFuelEfficiency;
  final String? notes;

  ModificationRecord({
    this.id,
    required this.vehicleId,
    required this.type,
    required this.description,
    this.brand,
    this.partNumber,
    required this.date,
    required this.cost,
    this.impactOnPerformance,
    this.impactOnFuelEfficiency,
    this.notes,
  });

  /// Convert ModificationRecord to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicle_id': vehicleId,
      'type': type,
      'description': description,
      'brand': brand,
      'part_number': partNumber,
      'date': date.toIso8601String(),
      'cost': cost,
      'impact_on_performance': impactOnPerformance,
      'impact_on_fuel_efficiency': impactOnFuelEfficiency,
      'notes': notes,
    };
  }

  /// Create ModificationRecord from Map (database retrieval)
  factory ModificationRecord.fromMap(Map<String, dynamic> map) {
    return ModificationRecord(
      id: map['id'] as int?,
      vehicleId: map['vehicle_id'] as int,
      type: map['type'] as String,
      description: map['description'] as String,
      brand: map['brand'] as String?,
      partNumber: map['part_number'] as String?,
      date: DateTime.parse(map['date'] as String),
      cost: map['cost'] as double,
      impactOnPerformance: map['impact_on_performance'] as String?,
      impactOnFuelEfficiency: map['impact_on_fuel_efficiency'] as String?,
      notes: map['notes'] as String?,
    );
  }
}
