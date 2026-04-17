/// Maintenance record for tracking service and repairs
class MaintenanceRecord {
  final int? id;
  final int vehicleId;
  final String type; // 'Oil Change', 'Brake Service', 'Tire Rotation', etc.
  final String? productName; // Product/brand used (e.g., 'Castrol Edge 5W-30')
  final DateTime date;
  final double? mileage;
  final double cost;
  final String? notes;
  final DateTime? nextDueDate;
  final double? nextDueMileage;

  MaintenanceRecord({
    this.id,
    required this.vehicleId,
    required this.type,
    this.productName,
    required this.date,
    this.mileage,
    required this.cost,
    this.notes,
    this.nextDueDate,
    this.nextDueMileage,
  });

  /// Convert MaintenanceRecord to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicle_id': vehicleId,
      'type': type,
      'product_name': productName,
      'date': date.toIso8601String(),
      'mileage': mileage,
      'cost': cost,
      'notes': notes,
      'next_due_date': nextDueDate?.toIso8601String(),
      'next_due_mileage': nextDueMileage,
    };
  }

  /// Create MaintenanceRecord from Map (database retrieval)
  factory MaintenanceRecord.fromMap(Map<String, dynamic> map) {
    return MaintenanceRecord(
      id: map['id'] as int?,
      vehicleId: map['vehicle_id'] as int,
      type: map['type'] as String,
      productName: map['product_name'] as String?,
      date: DateTime.parse(map['date'] as String),
      mileage: map['mileage'] as double?,
      cost: map['cost'] as double,
      notes: map['notes'] as String?,
      nextDueDate: map['next_due_date'] != null
          ? DateTime.parse(map['next_due_date'] as String)
          : null,
      nextDueMileage: map['next_due_mileage'] as double?,
    );
  }

  /// Check if maintenance is due soon
  bool isDueSoon(double currentMileage, {int daysThreshold = 30, double mileageThreshold = 500}) {
    if (nextDueDate != null) {
      final daysUntilDue = nextDueDate!.difference(DateTime.now()).inDays;
      if (daysUntilDue <= daysThreshold && daysUntilDue >= 0) return true;
    }
    if (nextDueMileage != null) {
      final mileageUntilDue = nextDueMileage! - currentMileage;
      if (mileageUntilDue <= mileageThreshold && mileageUntilDue >= 0) return true;
    }
    return false;
  }

  /// Check if maintenance is overdue
  bool isOverdue(double currentMileage) {
    if (nextDueDate != null && DateTime.now().isAfter(nextDueDate!)) return true;
    if (nextDueMileage != null && currentMileage > nextDueMileage!) return true;
    return false;
  }
}
