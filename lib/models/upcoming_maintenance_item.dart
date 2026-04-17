import 'package:flutter/material.dart';

import 'maintenance_record.dart';

enum UpcomingStatus {
  overdue,
  dueSoon,
  upcoming,
}

class UpcomingMaintenanceItem {
  final int vehicleId;
  final String vehicleName;
  final String title;
  final DateTime dueDate;
  final UpcomingStatus status;
  final MaintenanceRecord? record;
  final IconData icon;

  const UpcomingMaintenanceItem({
    required this.vehicleId,
    required this.vehicleName,
    required this.title,
    required this.dueDate,
    required this.status,
    this.record,
    required this.icon,
  });
}
