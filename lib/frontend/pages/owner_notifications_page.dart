import 'package:flutter/material.dart';

import 'package:arma2/backend/models/maintenance_request_status.dart';
import 'package:arma2/backend/services/tenants/owner_maintenance_service.dart';

class OwnerNotificationsPage extends StatefulWidget {
  const OwnerNotificationsPage({super.key});

  @override
  State<OwnerNotificationsPage> createState() => _OwnerNotificationsPageState();
}

class _OwnerNotificationsPageState extends State<OwnerNotificationsPage> {
  final OwnerMaintenanceService _maintenanceService =
      OwnerMaintenanceService.instance;
  final Set<String> _updatingRequestIds = <String>{};

  String _formatDate(DateTime? value) {
    if (value == null) {
      return 'Just now';
    }

    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final month = months[value.month - 1];
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$month $day, ${value.year} - $hour:$minute';
  }

  Future<void> _onStatusChanged(
    OwnerMaintenanceNotificationRecord record,
    String? value,
  ) async {
    if (value == null || value == record.status) {
      return;
    }

    if (_updatingRequestIds.contains(record.id)) {
      return;
    }

    setState(() {
      _updatingRequestIds.add(record.id);
    });

    try {
      await _maintenanceService.updateMaintenanceRequestStatus(
        request: record,
        status: value,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _updatingRequestIds.remove(record.id);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 244, 244, 244),
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<List<OwnerMaintenanceNotificationRecord>>(
        stream: _maintenanceService.watchOwnerMaintenanceNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Failed to load notifications.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final notifications =
              snapshot.data ?? const <OwnerMaintenanceNotificationRecord>[];

          if (notifications.isEmpty) {
            return const _EmptyState(
              message:
                  'No maintenance notifications yet.\nNew tenant requests will show here.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            itemCount: notifications.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final record = notifications[index];
              final isUpdating = _updatingRequestIds.contains(record.id);
              return _OwnerNotificationCard(
                record: record,
                dateLabel: _formatDate(record.updatedAt ?? record.createdAt),
                isUpdating: isUpdating,
                onStatusChanged: (value) => _onStatusChanged(record, value),
              );
            },
          );
        },
      ),
    );
  }
}

class _OwnerNotificationCard extends StatelessWidget {
  const _OwnerNotificationCard({
    required this.record,
    required this.dateLabel,
    required this.isUpdating,
    required this.onStatusChanged,
  });

  final OwnerMaintenanceNotificationRecord record;
  final String dateLabel;
  final bool isUpdating;
  final ValueChanged<String?> onStatusChanged;

  _StatusPalette _paletteForStatus(String status) {
    switch (status) {
      case MaintenanceRequestStatus.inProgress:
        return const _StatusPalette(
          background: Color.fromARGB(255, 228, 239, 255),
          foreground: Color.fromARGB(255, 52, 96, 188),
        );
      case MaintenanceRequestStatus.onHold:
        return const _StatusPalette(
          background: Color.fromARGB(255, 244, 236, 255),
          foreground: Color.fromARGB(255, 126, 72, 189),
        );
      case MaintenanceRequestStatus.completed:
        return const _StatusPalette(
          background: Color.fromARGB(255, 225, 247, 233),
          foreground: Color.fromARGB(255, 40, 143, 83),
        );
      case MaintenanceRequestStatus.rejected:
        return const _StatusPalette(
          background: Color.fromARGB(255, 255, 232, 232),
          foreground: Color.fromARGB(255, 178, 54, 54),
        );
      case MaintenanceRequestStatus.pending:
      default:
        return const _StatusPalette(
          background: Color.fromARGB(255, 255, 242, 223),
          foreground: Color.fromARGB(255, 176, 117, 23),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final normalizedStatus = MaintenanceRequestStatus.normalize(record.status);
    final palette = _paletteForStatus(normalizedStatus);
    final selectedStatus = MaintenanceRequestStatus.ownerSelectableStatuses.contains(
      normalizedStatus,
    )
        ? normalizedStatus
        : MaintenanceRequestStatus.pending;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color.fromARGB(255, 228, 228, 228)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  record.tenantLabel,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: palette.background,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  selectedStatus,
                  style: TextStyle(
                    color: palette.foreground,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${record.propertyName} - Unit ${record.unitId}',
            style: const TextStyle(
              color: Color.fromARGB(255, 108, 108, 108),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            dateLabel,
            style: const TextStyle(
              color: Color.fromARGB(255, 130, 130, 130),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            record.message.isEmpty ? '(No message)' : record.message,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: selectedStatus,
            items: MaintenanceRequestStatus.ownerSelectableStatuses
                .map(
                  (status) =>
                      DropdownMenuItem<String>(value: status, child: Text(status)),
                )
                .toList(),
            onChanged: isUpdating ? null : onStatusChanged,
            decoration: InputDecoration(
              labelText: 'Update status',
              filled: true,
              fillColor: const Color.fromARGB(255, 246, 246, 246),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color.fromARGB(255, 225, 225, 225),
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color.fromARGB(255, 225, 225, 225),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.black),
              ),
            ),
          ),
          if (isUpdating)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Saving...',
                    style: TextStyle(
                      color: Color.fromARGB(255, 102, 102, 102),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusPalette {
  const _StatusPalette({required this.background, required this.foreground});

  final Color background;
  final Color foreground;
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color.fromARGB(255, 228, 228, 228)),
          ),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color.fromARGB(255, 110, 110, 110),
            ),
          ),
        ),
      ),
    );
  }
}
