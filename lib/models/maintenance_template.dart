class MaintenanceTemplate {
  final String id;
  final String label;
  final String type;
  final int? intervalMonths;
  final double? intervalKm;

  const MaintenanceTemplate({
    required this.id,
    required this.label,
    required this.type,
    this.intervalMonths,
    this.intervalKm,
  });
}
