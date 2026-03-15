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
  final Set<String> _updatingStatusRequestIds = <String>{};
  final Set<String> _savingMessageRequestIds = <String>{};

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

  String _formatCurrency(double value) {
    final rounded = value.round().toString();
    final formatted = rounded.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
    return 'LKR $formatted';
  }

  Future<void> _onStatusChanged(
    OwnerMaintenanceNotificationRecord record,
    String? value,
  ) async {
    if (value == null || value == record.status) {
      return;
    }
    if (_updatingStatusRequestIds.contains(record.id)) {
      return;
    }

    setState(() {
      _updatingStatusRequestIds.add(record.id);
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
          _updatingStatusRequestIds.remove(record.id);
        });
      }
    }
  }

  Future<void> _onEditOwnerMessage(
    OwnerMaintenanceNotificationRecord record,
  ) async {
    if (_savingMessageRequestIds.contains(record.id)) {
      return;
    }

    final newMessage = await _showMessageDialog(initialValue: record.ownerMessage);
    if (newMessage == null) {
      return;
    }

    _savingMessageRequestIds.add(record.id);

    try {
      // Let the dialog route fully settle before writing and rebuilding streams.
      await Future<void>.delayed(const Duration(milliseconds: 80));
      await _maintenanceService.updateMaintenanceRequestMessage(
        request: record,
        ownerMessage: newMessage,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save message: $error')),
      );
    } finally {
      _savingMessageRequestIds.remove(record.id);
    }
  }

  Future<String?> _showMessageDialog({required String initialValue}) async {
    final controller = TextEditingController(text: initialValue);

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Message to Tenant'),
          content: TextField(
            controller: controller,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Write an update for the tenant...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                FocusManager.instance.primaryFocus?.unfocus();
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                FocusManager.instance.primaryFocus?.unfocus();
                Navigator.of(context).pop('');
              },
              child: const Text('Clear'),
            ),
            ElevatedButton(
              onPressed: () {
                FocusManager.instance.primaryFocus?.unfocus();
                Navigator.of(context).pop(controller.text.trim());
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    return result;
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        children: [
          const Text(
            'Maintenance Requests',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          StreamBuilder<List<OwnerMaintenanceNotificationRecord>>(
            stream: _maintenanceService.watchOwnerMaintenanceNotifications(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return _SectionMessageCard(
                  message:
                      'Failed to load maintenance notifications.\n${snapshot.error}',
                );
              }

              final notifications =
                  snapshot.data ?? const <OwnerMaintenanceNotificationRecord>[];

              if (notifications.isEmpty) {
                return const _SectionMessageCard(
                  message:
                      'No maintenance notifications yet.\nNew tenant requests will show here.',
                );
              }

              return Column(
                children: notifications.map((record) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _MaintenanceNotificationCard(
                      key: ValueKey<String>('maintenance-${record.id}'),
                      record: record,
                      dateLabel: _formatDate(record.updatedAt ?? record.createdAt),
                      isUpdatingStatus: _updatingStatusRequestIds.contains(record.id),
                      onStatusChanged: (value) => _onStatusChanged(record, value),
                      onEditMessage: () => _onEditOwnerMessage(record),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 8),
          const Text(
            'Rent Payments',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          StreamBuilder<List<OwnerRentPaymentNotificationRecord>>(
            stream: _maintenanceService.watchOwnerPaymentNotifications(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return _SectionMessageCard(
                  message: 'Failed to load payment notifications.\n${snapshot.error}',
                );
              }

              final notifications =
                  snapshot.data ?? const <OwnerRentPaymentNotificationRecord>[];

              if (notifications.isEmpty) {
                return const _SectionMessageCard(
                  message:
                      'No payment notifications yet.\nTenant rent payments will show here.',
                );
              }

              return Column(
                children: notifications.map((record) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _PaymentNotificationCard(
                      record: record,
                      dateLabel: _formatDate(record.paidAt ?? record.createdAt),
                      amountLabel: _formatCurrency(record.amount),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MaintenanceNotificationCard extends StatelessWidget {
  const _MaintenanceNotificationCard({
    super.key,
    required this.record,
    required this.dateLabel,
    required this.isUpdatingStatus,
    required this.onStatusChanged,
    required this.onEditMessage,
  });

  final OwnerMaintenanceNotificationRecord record;
  final String dateLabel;
  final bool isUpdatingStatus;
  final ValueChanged<String?> onStatusChanged;
  final VoidCallback onEditMessage;

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
                  normalizedStatus,
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
          if (record.ownerMessage.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 244, 248, 255),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color.fromARGB(255, 224, 233, 247)),
              ),
              child: Text(
                'Owner Message: ${record.ownerMessage.trim()}',
                style: const TextStyle(
                  color: Color.fromARGB(255, 63, 82, 119),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: MaintenanceRequestStatus.ownerSelectableStatuses.contains(
                    normalizedStatus,
                  )
                      ? normalizedStatus
                      : MaintenanceRequestStatus.pending,
                  items: MaintenanceRequestStatus.ownerSelectableStatuses
                      .map(
                        (status) => DropdownMenuItem<String>(
                          value: status,
                          child: Text(status),
                        ),
                      )
                      .toList(),
                  onChanged: isUpdatingStatus ? null : onStatusChanged,
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
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: onEditMessage,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Message'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black,
                  side: const BorderSide(color: Color.fromARGB(255, 210, 210, 210)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentNotificationCard extends StatelessWidget {
  const _PaymentNotificationCard({
    required this.record,
    required this.dateLabel,
    required this.amountLabel,
  });

  final OwnerRentPaymentNotificationRecord record;
  final String dateLabel;
  final String amountLabel;

  @override
  Widget build(BuildContext context) {
    final isPaid = record.status.toLowerCase() == 'paid';
    final badgeBackground = isPaid
        ? const Color.fromARGB(255, 225, 247, 233)
        : const Color.fromARGB(255, 255, 242, 223);
    final badgeTextColor = isPaid
        ? const Color.fromARGB(255, 40, 143, 83)
        : const Color.fromARGB(255, 176, 117, 23);

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
                  color: badgeBackground,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  isPaid ? 'Paid' : record.status,
                  style: TextStyle(
                    color: badgeTextColor,
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
            '$amountLabel received via ${record.method}',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w500,
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

class _SectionMessageCard extends StatelessWidget {
  const _SectionMessageCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
    );
  }
}
