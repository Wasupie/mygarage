import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/maintenance_record.dart';
import '../models/vehicle.dart';
import '../utils/date_time_utils.dart';

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _maintenanceChannelId = 'maintenance_reminders';

  static bool _initialized = false;

  static bool get _isSupportedPlatform {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS || Platform.isMacOS;
  }

  static Future<void> initialize() async {
    if (_initialized) return;
    if (!_isSupportedPlatform) {
      _initialized = true;
      return;
    }

    tzdata.initializeTimeZones();
    try {
      final Object tzInfo = await FlutterTimezone.getLocalTimezone();
      final String? tzName = _tryExtractTimezoneName(tzInfo);
      if (tzName != null && tzName.trim().isNotEmpty) {
        tz.setLocalLocation(tz.getLocation(tzName.trim()));
      }
    } catch (_) {
      // If timezone lookup fails we still can schedule using the default tz.local.
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
      macOS: darwinInit,
    );

    await _plugin.initialize(initSettings);
    await _requestPermissions();

    _initialized = true;
  }

  static Future<void> _requestPermissions() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();

    final ios =
        _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);

    final macos = _plugin
        .resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>();
    await macos?.requestPermissions(alert: true, badge: true, sound: true);
  }

  static NotificationDetails _maintenanceNotificationDetails() {
    const androidDetails = AndroidNotificationDetails(
      _maintenanceChannelId,
      'Maintenance reminders',
      channelDescription: 'Reminders for upcoming/overdue maintenance',
      importance: Importance.max,
      priority: Priority.high,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: true,
    );

    return const NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );
  }

  static bool _isOilChangeType(String type) {
    final t = type.trim().toLowerCase();
    if (t.isEmpty) return false;
    if (t == 'oil change') return true;
    return t.contains('oil');
  }

  static int _oilBaseIdForVehicle(int vehicleId) => 900000 + (vehicleId * 10);

  static int _nextDueBaseIdForRecord(int recordId) => 100000 + (recordId * 10);

  static int _mileageDueBaseIdForRecord(int recordId) => 500000 + (recordId * 10);

  static Future<void> syncVehicleMaintenanceReminders({
    required Vehicle vehicle,
    required List<MaintenanceRecord> maintenanceRecords,
  }) async {
    if (!_isSupportedPlatform) return;
    if (!_initialized) await initialize();

    // 1) Engine oil reminders derived from the latest oil-change record.
    final latestOil = maintenanceRecords
        .where((r) => _isOilChangeType(r.type))
        .fold<MaintenanceRecord?>(
          null,
          (prev, next) => prev == null || next.date.isAfter(prev.date) ? next : prev,
        );
    if (vehicle.id != null) {
      await scheduleOilChangeReminders(
        vehicleId: vehicle.id!,
        vehicleName: vehicle.name,
        latestOilChange: latestOil,
      );
    }

    // 2) Generic reminders for any record that has an explicit nextDueDate.
    for (final record in maintenanceRecords) {
      if (record.id == null) continue;
      await scheduleNextDueDateReminders(
        vehicleName: vehicle.name,
        record: record,
      );
    }
  }

  static Future<void> scheduleOilChangeReminders({
    required int vehicleId,
    required String vehicleName,
    required MaintenanceRecord? latestOilChange,
  }) async {
    if (!_isSupportedPlatform) return;
    if (!_initialized) await initialize();

    final baseId = _oilBaseIdForVehicle(vehicleId);

    // Always cancel old scheduled reminders for this vehicle first.
    await _plugin.cancel(baseId + 0);
    await _plugin.cancel(baseId + 1);
    await _plugin.cancel(baseId + 2);

    if (latestOilChange == null) return;

    final dueDate = latestOilChange.nextDueDate ?? addMonths(latestOilChange.date, 6);
    await _scheduleDueSeries(
      baseId: baseId,
      title: 'Oil change reminder',
      vehicleName: vehicleName,
      dueDate: dueDate,
      subtitle: 'Engine oil',
    );
  }

  static Future<void> scheduleNextDueDateReminders({
    required String vehicleName,
    required MaintenanceRecord record,
  }) async {
    if (!_isSupportedPlatform) return;
    if (!_initialized) await initialize();

    if (record.id == null) return;

    final baseId = _nextDueBaseIdForRecord(record.id!);

    // Clear any old schedule for this record (id-stable).
    await _plugin.cancel(baseId + 0);
    await _plugin.cancel(baseId + 1);
    await _plugin.cancel(baseId + 2);

    final dueDate = record.nextDueDate;
    if (dueDate == null) return;

    await _scheduleDueSeries(
      baseId: baseId,
      title: 'Maintenance reminder',
      vehicleName: vehicleName,
      dueDate: dueDate,
      subtitle: record.type,
    );
  }

  static Future<void> cancelNextDueDateRemindersForMaintenanceRecord(int recordId) async {
    if (!_isSupportedPlatform) return;
    if (!_initialized) await initialize();

    final baseId = _nextDueBaseIdForRecord(recordId);
    await _plugin.cancel(baseId + 0);
    await _plugin.cancel(baseId + 1);
    await _plugin.cancel(baseId + 2);
  }

  static Future<void> syncMileageBasedMaintenanceAlerts({
    required String vehicleName,
    required double currentMileage,
    required List<MaintenanceRecord> maintenanceRecords,
  }) async {
    if (!_isSupportedPlatform) return;
    if (!_initialized) await initialize();

    for (final record in maintenanceRecords) {
      if (record.id == null || record.nextDueMileage == null) continue;

      final baseId = _mileageDueBaseIdForRecord(record.id!);
      final dueMileage = record.nextDueMileage!;
      final kmDelta = dueMileage - currentMileage;

      // Keep at most one active mileage alert per maintenance record.
      await _plugin.cancel(baseId + 0);

      String? body;
      if (kmDelta < 0) {
        final overdueBy = kmDelta.abs().toStringAsFixed(0);
        body = '${record.type} for $vehicleName is overdue by $overdueBy km.';
      } else if (kmDelta <= 500) {
        final dueIn = kmDelta.toStringAsFixed(0);
        body = '${record.type} for $vehicleName is due in $dueIn km.';
      }

      if (body == null) continue;

      await _plugin.show(
        baseId + 0,
        'Maintenance mileage reminder',
        body,
        _maintenanceNotificationDetails(),
      );
    }
  }

  static Future<void> _scheduleDueSeries({
    required int baseId,
    required String title,
    required String vehicleName,
    required DateTime dueDate,
    required String subtitle,
  }) async {
    final now = DateTime.now();

    // Schedule at 09:00 local time.
    final dueAt = _atLocalTime(dueDate, hour: 9, minute: 0);
    final oneWeekBefore = dueAt.subtract(const Duration(days: 7));
    final twoWeeksBefore = dueAt.subtract(const Duration(days: 14));

    final details = _maintenanceNotificationDetails();

    // 2 weeks before
    if (twoWeeksBefore.isAfter(now)) {
      await _plugin.zonedSchedule(
        baseId + 2,
        title,
        '$subtitle for $vehicleName is due in 2 weeks.',
        _toTz(twoWeeksBefore),
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }

    // 1 week before
    if (oneWeekBefore.isAfter(now)) {
      await _plugin.zonedSchedule(
        baseId + 1,
        title,
        '$subtitle for $vehicleName is due in 1 week.',
        _toTz(oneWeekBefore),
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }

    // on due date
    if (dueAt.isAfter(now)) {
      await _plugin.zonedSchedule(
        baseId + 0,
        title,
        '$subtitle for $vehicleName is due today.',
        _toTz(dueAt),
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  static DateTime _atLocalTime(DateTime date, {required int hour, required int minute}) {
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  static tz.TZDateTime _toTz(DateTime dateTime) {
    return tz.TZDateTime.from(dateTime, tz.local);
  }

  static String? _tryExtractTimezoneName(Object tzInfo) {
    if (tzInfo is String) return tzInfo;
    // flutter_timezone >= 5 returns a TimezoneInfo; field names differ across versions.
    final dynamic d = tzInfo;
    try {
      final v = d.timezone;
      if (v is String) return v;
    } catch (_) {}
    try {
      final v = d.timeZone;
      if (v is String) return v;
    } catch (_) {}
    try {
      final v = d.timeZoneName;
      if (v is String) return v;
    } catch (_) {}
    try {
      final v = d.identifier;
      if (v is String) return v;
    } catch (_) {}
    try {
      final v = d.id;
      if (v is String) return v;
    } catch (_) {}
    return null;
  }
}
