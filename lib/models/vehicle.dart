/// Vehicle model representing a car or motorcycle
class Vehicle {
  final int? id;
  final String name;
  final String model;
  final String plateNumber;
  final String engineType;
  final String vehicleType; // 'car' or 'motorcycle'
  final double? initialMileage;
  final DateTime? purchaseDate;
  final String? notes;

  Vehicle({
    this.id,
    required this.name,
    required this.model,
    required this.plateNumber,
    required this.engineType,
    required this.vehicleType,
    this.initialMileage,
    this.purchaseDate,
    this.notes,
  });

  /// Convert Vehicle to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'model': model,
      'plate_number': plateNumber,
      'engine_type': engineType,
      'vehicle_type': vehicleType,
      'initial_mileage': initialMileage,
      'purchase_date': purchaseDate?.toIso8601String(),
      'notes': notes,
    };
  }

  /// Create Vehicle from Map (database retrieval)
  factory Vehicle.fromMap(Map<String, dynamic> map) {
    return Vehicle(
      id: map['id'] as int?,
      name: map['name'] as String,
      model: map['model'] as String,
      plateNumber: map['plate_number'] as String,
      engineType: map['engine_type'] as String,
      vehicleType: map['vehicle_type'] as String,
      initialMileage: map['initial_mileage'] as double?,
      purchaseDate: map['purchase_date'] != null
          ? DateTime.parse(map['purchase_date'] as String)
          : null,
      notes: map['notes'] as String?,
    );
  }

  /// Create a copy of Vehicle with updated fields
  Vehicle copyWith({
    int? id,
    String? name,
    String? model,
    String? plateNumber,
    String? engineType,
    String? vehicleType,
    double? initialMileage,
    DateTime? purchaseDate,
    String? notes,
  }) {
    return Vehicle(
      id: id ?? this.id,
      name: name ?? this.name,
      model: model ?? this.model,
      plateNumber: plateNumber ?? this.plateNumber,
      engineType: engineType ?? this.engineType,
      vehicleType: vehicleType ?? this.vehicleType,
      initialMileage: initialMileage ?? this.initialMileage,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      notes: notes ?? this.notes,
    );
  }
}
