import '../models/maintenance_template.dart';

/// Built-in templates (optional helper; does not store anything in the DB).
const builtInMaintenanceTemplates = <MaintenanceTemplate>[
  MaintenanceTemplate(
    id: 'oil_6mo',
    label: 'Engine oil (6 months)',
    type: 'Oil Change',
    intervalMonths: 6,
  ),
  MaintenanceTemplate(
    id: 'tire_rotation_6mo',
    label: 'Tire rotation (6 months)',
    type: 'Tire Rotation',
    intervalMonths: 6,
  ),
  MaintenanceTemplate(
    id: 'air_filter_12mo',
    label: 'Air filter (12 months)',
    type: 'Air Filter',
    intervalMonths: 12,
  ),
  MaintenanceTemplate(
    id: 'spark_plugs_36mo',
    label: 'Spark plugs (36 months)',
    type: 'Spark Plugs',
    intervalMonths: 36,
  ),
  MaintenanceTemplate(
    id: 'brake_service_12mo',
    label: 'Brake service (12 months)',
    type: 'Brake Service',
    intervalMonths: 12,
  ),
  MaintenanceTemplate(
    id: 'transmission_24mo',
    label: 'Transmission service (24 months)',
    type: 'Transmission Service',
    intervalMonths: 24,
  ),
];
