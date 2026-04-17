/// Fuel record for tracking refills and calculating efficiency
class FuelRecord {
  final int? id;
  final int vehicleId;
  final DateTime date;
  final double liters;
  final double cost;
  final double? mileage;
  final bool isFullTank;
  final String? petrolStation; // Shell, Petronas, Petron, Caltex, Five, BHP
  final String? notes;

  FuelRecord({
    this.id,
    required this.vehicleId,
    required this.date,
    required this.liters,
    required this.cost,
    this.mileage,
    this.isFullTank = true,
    this.petrolStation,
    this.notes,
  });

  /// Calculate cost per liter
  double get costPerLiter => cost / liters;

  /// Convert FuelRecord to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicle_id': vehicleId,
      'date': date.toIso8601String(),
      'liters': liters,
      'cost': cost,
      'mileage': mileage,
      'is_full_tank': isFullTank ? 1 : 0,
      'petrol_station': petrolStation,
      'notes': notes,
    };
  }

  /// Create FuelRecord from Map (database retrieval)
  factory FuelRecord.fromMap(Map<String, dynamic> map) {
    return FuelRecord(
      id: map['id'] as int?,
      vehicleId: map['vehicle_id'] as int,
      date: DateTime.parse(map['date'] as String),
      liters: map['liters'] as double,
      cost: map['cost'] as double,
      mileage: map['mileage'] as double?,
      isFullTank: map['is_full_tank'] == 1 || map['is_full_tank'] == true,
      petrolStation: map['petrol_station'] as String?,
      notes: map['notes'] as String?,
    );
  }

  /// Calculate fuel efficiency (km/L or mpg)
  /// Requires previous fuel record with mileage
  static double? calculateEfficiency(
    FuelRecord current,
    FuelRecord? previous,
  ) {
    if (current.mileage == null || 
        previous?.mileage == null || 
        !current.isFullTank || 
        !previous!.isFullTank) {
      return null;
    }

    final distanceTraveled = current.mileage! - previous.mileage!;
    if (distanceTraveled <= 0 || current.liters <= 0) return null;

    return distanceTraveled / current.liters;
  }

  /// Build per-tank efficiencies from records ordered by newest first.
  static List<double> computeTankEfficiencies(List<FuelRecord> records) {
    if (records.length < 2) return const [];

    final efficiencies = <double>[];
    for (int i = 0; i < records.length - 1; i++) {
      final efficiency = calculateEfficiency(records[i], records[i + 1]);
      if (efficiency != null) {
        efficiencies.add(efficiency);
      }
    }
    return efficiencies;
  }

  /// Robust average that reduces distortion from missing fuel logs.
  ///
  /// A missed refill often creates an unrealistically high km/L outlier.
  /// We remove IQR outliers when we have enough samples, then average.
  static double? calculateRobustAverageEfficiency(List<FuelRecord> records) {
    final efficiencies = computeTankEfficiencies(records);
    if (efficiencies.isEmpty) return null;
    if (efficiencies.length < 4) {
      return efficiencies.reduce((a, b) => a + b) / efficiencies.length;
    }

    final sorted = [...efficiencies]..sort();
    final q1 = _percentile(sorted, 0.25);
    final q3 = _percentile(sorted, 0.75);
    final iqr = q3 - q1;

    // Guard against numerical edge cases where all values are nearly equal.
    if (iqr <= 0.0001) {
      return sorted.reduce((a, b) => a + b) / sorted.length;
    }

    final low = q1 - (1.5 * iqr);
    final high = q3 + (1.5 * iqr);

    final filtered = sorted.where((v) => v >= low && v <= high).toList();
    final source = filtered.isEmpty ? sorted : filtered;

    return source.reduce((a, b) => a + b) / source.length;
  }

  static double _percentile(List<double> sorted, double p) {
    if (sorted.length == 1) return sorted.first;
    final pos = (sorted.length - 1) * p;
    final lower = pos.floor();
    final upper = pos.ceil();
    if (lower == upper) return sorted[lower];
    final weight = pos - lower;
    return sorted[lower] + ((sorted[upper] - sorted[lower]) * weight);
  }
}
