import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/vehicle.dart';
import '../models/maintenance_record.dart';
import '../models/upcoming_maintenance_item.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../utils/date_time_utils.dart';
import '../widgets/record_details_sheet.dart';
import 'vehicle_detail_screen.dart';

class UpcomingScreen extends StatefulWidget {
  const UpcomingScreen({super.key});

  @override
  State<UpcomingScreen> createState() => _UpcomingScreenState();
}

class _UpcomingScreenState extends State<UpcomingScreen> {
  final SupabaseService _dbService = SupabaseService();

  bool _isLoading = true;
  String? _error;

  List<UpcomingMaintenanceItem> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final vehicles = await _dbService.getAllVehicles();
      final items = <UpcomingMaintenanceItem>[];

      const batchSize = 4;
      final withIds = vehicles.where((v) => v.id != null).toList(growable: false);

      for (var i = 0; i < withIds.length; i += batchSize) {
        final batch = withIds.skip(i).take(batchSize).toList(growable: false);
        final maintLists = await Future.wait(
          batch.map((v) => _dbService.getMaintenanceRecords(v.id!)),
        );
        for (var j = 0; j < batch.length; j++) {
          items.addAll(_buildUpcomingForVehicle(batch[j], maintLists[j]));
        }
      }

      items.sort((a, b) {
        final statusOrder = _statusRank(a.status).compareTo(_statusRank(b.status));
        if (statusOrder != 0) return statusOrder;
        return a.dueDate.compareTo(b.dueDate);
      });

      if (!mounted) return;
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _items = [];
        _isLoading = false;
        _error = 'Could not load upcoming maintenance.';
      });
    }
  }

  int _statusRank(UpcomingStatus s) {
    switch (s) {
      case UpcomingStatus.overdue:
        return 0;
      case UpcomingStatus.dueSoon:
        return 1;
      case UpcomingStatus.upcoming:
        return 2;
    }
  }

  List<UpcomingMaintenanceItem> _buildUpcomingForVehicle(
    Vehicle vehicle,
    List<MaintenanceRecord> records,
  ) {
    final now = DateTime.now();
    final items = <UpcomingMaintenanceItem>[];

    // A) Explicit next due date from records.
    for (final r in records) {
      if (r.nextDueDate == null) continue;
      final due = r.nextDueDate!;
      final status = _statusForDueDate(due, now);
      items.add(
        UpcomingMaintenanceItem(
          vehicleId: vehicle.id!,
          vehicleName: vehicle.name,
          title: r.type,
          dueDate: due,
          status: status,
          record: r,
          icon: Icons.build_outlined,
        ),
      );
    }

    // B) Engine oil helper: based on the latest oil-related record, even if nextDueDate isn't set.
    MaintenanceRecord? latestOil;
    for (final r in records) {
      final t = r.type.trim().toLowerCase();
      if (!(t == 'oil change' || t.contains('oil'))) continue;
      if (latestOil == null || r.date.isAfter(latestOil.date)) {
        latestOil = r;
      }
    }

    if (latestOil != null) {
      final due = latestOil.nextDueDate ?? addMonths(latestOil.date, 6);
      final status = _statusForDueDate(due, now);
      items.add(
        UpcomingMaintenanceItem(
          vehicleId: vehicle.id!,
          vehicleName: vehicle.name,
          title: 'Engine oil',
          dueDate: due,
          status: status,
          record: latestOil,
          icon: Icons.oil_barrel_outlined,
        ),
      );
    }

    // Deduplicate: if there is an explicit oil-change record with same due date, keep the explicit one.
    final seen = <String, UpcomingMaintenanceItem>{};
    for (final item in items) {
      final key = '${item.vehicleId}|${item.title.toLowerCase()}|${_dateKey(item.dueDate)}';
      final existing = seen[key];
      if (existing == null) {
        seen[key] = item;
        continue;
      }
      final existingIsGeneratedOil =
          existing.title.toLowerCase() == 'engine oil' && existing.record != null;
      final currentIsGeneratedOil =
          item.title.toLowerCase() == 'engine oil' && item.record != null;

      // Prefer the item that is tied to a record with an explicit nextDueDate.
      final existingHasExplicit = existing.record?.nextDueDate != null;
      final currentHasExplicit = item.record?.nextDueDate != null;
      if (!existingHasExplicit && currentHasExplicit) {
        seen[key] = item;
        continue;
      }

      // Otherwise keep the first; don't spam.
      if (existingIsGeneratedOil && !currentIsGeneratedOil) {
        seen[key] = item;
      }
    }

    return seen.values.toList();
  }

  String _dateKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  UpcomingStatus _statusForDueDate(DateTime due, DateTime now) {
    final dueDay = DateTime(due.year, due.month, due.day);
    final today = DateTime(now.year, now.month, now.day);

    if (dueDay.isBefore(today)) return UpcomingStatus.overdue;

    final days = dueDay.difference(today).inDays;
    if (days <= 14) return UpcomingStatus.dueSoon;

    return UpcomingStatus.upcoming;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upcoming'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError(_error!)
              : _items.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        children: [
                          ..._buildSection(
                            title: 'Overdue',
                            items: _items.where((i) => i.status == UpcomingStatus.overdue).toList(),
                          ),
                          ..._buildSection(
                            title: 'Due soon',
                            items: _items.where((i) => i.status == UpcomingStatus.dueSoon).toList(),
                          ),
                          ..._buildSection(
                            title: 'Later',
                            items: _items.where((i) => i.status == UpcomingStatus.upcoming).toList(),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 72,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Could not load',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Nothing due soon',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Upcoming items show here when you set a next due date, or log oil changes.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSection({required String title, required List<UpcomingMaintenanceItem> items}) {
    if (items.isEmpty) return const [];

    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      ...items.map(_buildItemCard),
    ];
  }

  Widget _buildItemCard(UpcomingMaintenanceItem item) {
    final df = DateFormat('MMM dd, yyyy');
    final dueText = df.format(item.dueDate);
    final badge = _badgeText(item);

    final badgeColor = switch (item.status) {
      UpcomingStatus.overdue => Theme.of(context).colorScheme.error,
      UpcomingStatus.dueSoon => Theme.of(context).colorScheme.onSurface,
      UpcomingStatus.upcoming => Theme.of(context).colorScheme.onSurfaceVariant,
    };

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: () => _showItemDetails(item),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.8),
                  ),
                ),
                child: Icon(item.icon, color: context.semanticColors.maintenance, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.vehicleName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Due $dueText',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.9),
                  ),
                ),
                child: Text(
                  badge,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: badgeColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _badgeText(UpcomingMaintenanceItem item) {
    final today = DateTime.now();
    final due = DateTime(item.dueDate.year, item.dueDate.month, item.dueDate.day);
    final nowDay = DateTime(today.year, today.month, today.day);
    final days = due.difference(nowDay).inDays;

    return switch (item.status) {
      UpcomingStatus.overdue => 'Overdue',
      UpcomingStatus.dueSoon => days <= 0 ? 'Today' : '${days}d',
      UpcomingStatus.upcoming => '${days}d',
    };
  }

  Future<void> _showItemDetails(UpcomingMaintenanceItem item) async {
    final df = DateFormat('MMM dd, yyyy');

    final items = <RecordDetailsItem>[
      RecordDetailsItem(label: 'Vehicle', value: item.vehicleName),
      RecordDetailsItem(label: 'Service', value: item.title),
      RecordDetailsItem(label: 'Due date', value: df.format(item.dueDate)),
    ];

    if (item.record != null) {
      final r = item.record!;
      items.addAll([
        RecordDetailsItem(label: 'Last service date', value: df.format(r.date)),
        RecordDetailsItem(
          label: 'Product',
          value: (r.productName == null || r.productName!.trim().isEmpty)
              ? '—'
              : r.productName!.trim(),
        ),
        RecordDetailsItem(
          label: 'Notes',
          value: (r.notes == null || r.notes!.trim().isEmpty) ? '—' : r.notes!.trim(),
        ),
      ]);
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return RecordDetailsSheet(
          title: 'Upcoming maintenance',
          sections: [RecordDetailsSection(items: items)],
          footer: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: FilledButton(
              onPressed: () async {
                final sheetContext = context;
                Navigator.pop(sheetContext);
                final vehicle = await _dbService.getVehicle(item.vehicleId);
                if (!mounted || vehicle == null) return;
                await Navigator.push(
                  this.context,
                  MaterialPageRoute(
                    builder: (context) => VehicleDetailScreen(vehicle: vehicle),
                  ),
                );
              },
              child: const Text('Open vehicle'),
            ),
          ),
        );
      },
    );
  }
}
