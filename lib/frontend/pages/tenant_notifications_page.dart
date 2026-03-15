import 'package:flutter/material.dart';

import 'package:arma2/backend/models/maintenance_request_status.dart';
import 'package:arma2/backend/services/tenants/tenant_portal_service.dart';

class TenantNotificationsPage extends StatelessWidget {
  const TenantNotificationsPage({super.key});

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
    final portalService = TenantPortalService.instance;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 244, 244, 244),
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<List<TenantMaintenanceRequestRecord>>(
        stream: portalService.watchTenantMaintenanceRequests(),
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

          final requests = snapshot.data ?? const <TenantMaintenanceRequestRecord>[];

          if (requests.isEmpty) {
            return const _EmptyState(
              message: 'No notifications yet.\nMaintenance updates will appear here.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            itemCount: requests.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final request = requests[index];
              final status = MaintenanceRequestStatus.normalize(request.status);
              final palette = _paletteForStatus(status);

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
                            _formatDate(request.updatedAt ?? request.createdAt),
                            style: const TextStyle(
                              color: Color.fromARGB(255, 130, 130, 130),
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: palette.background,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: palette.foreground,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      request.message.trim().isEmpty
                          ? '(No message)'
                          : request.message.trim(),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (request.ownerMessage.trim().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 244, 248, 255),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color.fromARGB(255, 224, 233, 247),
                          ),
                        ),
                        child: Text(
                          'Owner Message: ${request.ownerMessage.trim()}',
                          style: const TextStyle(
                            color: Color.fromARGB(255, 63, 82, 119),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
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
