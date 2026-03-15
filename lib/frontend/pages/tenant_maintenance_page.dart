import 'package:flutter/material.dart';

import 'package:arma2/backend/models/maintenance_request_status.dart';
import 'package:arma2/backend/services/tenants/tenant_portal_service.dart';

class TenantMaintenancePage extends StatefulWidget {
  const TenantMaintenancePage({super.key});

  @override
  State<TenantMaintenancePage> createState() => _TenantMaintenancePageState();
}

class _TenantMaintenancePageState extends State<TenantMaintenancePage> {
  final TenantPortalService _portalService = TenantPortalService.instance;
  final TextEditingController _issueController = TextEditingController();

  bool _isSubmitting = false;

  Future<void> _submitRequest(TenantLeaseInfo lease) async {
    if (_isSubmitting) {
      return;
    }

    final message = _issueController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe the maintenance issue.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _portalService.submitMaintenanceRequest(
        lease: lease,
        message: message,
      );

      if (!mounted) {
        return;
      }

      _issueController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request submitted successfully.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit request: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showEmergencyInfo() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Call emergency support at +94 11 234 5678')),
    );
  }

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

    return '${months[value.month - 1]} ${value.day}, ${value.year}';
  }

  @override
  void dispose() {
    _issueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<TenantLeaseInfo?>(
      stream: _portalService.watchCurrentTenantLease(),
      builder: (context, leaseSnapshot) {
        if (leaseSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (leaseSnapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Failed to load maintenance data.\n${leaseSnapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final lease = leaseSnapshot.data;
        if (lease == null) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'No active tenant assignment found.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return Container(
          color: const Color.fromARGB(255, 244, 244, 244),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              const Text(
                'Maintenance',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 30,
                  height: 1,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              _EmergencyCard(onCallTap: _showEmergencyInfo),
              const SizedBox(height: 14),
              _SubmitRequestCard(
                controller: _issueController,
                isSubmitting: _isSubmitting,
                onSubmit: () => _submitRequest(lease),
              ),
              const SizedBox(height: 16),
              const Text(
                'Recent Requests',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              StreamBuilder<List<TenantMaintenanceRequestRecord>>(
                stream: _portalService.watchTenantMaintenanceRequests(),
                builder: (context, requestsSnapshot) {
                  if (requestsSnapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (requestsSnapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        'Failed to load requests.\n${requestsSnapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  final requests =
                      requestsSnapshot.data ?? const <TenantMaintenanceRequestRecord>[];

                  if (requests.isEmpty) {
                    return const _EmptyRequestsCard();
                  }

                  return Column(
                    children: requests.take(5).map((request) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _RequestCard(
                          message: request.message,
                          status: request.status,
                          ownerMessage: request.ownerMessage,
                          dateLabel: _formatDate(request.updatedAt ?? request.createdAt),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EmergencyCard extends StatelessWidget {
  const _EmergencyCard({required this.onCallTap});

  final VoidCallback onCallTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 255, 248, 248),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color.fromARGB(255, 245, 216, 216)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 255, 234, 234),
              borderRadius: BorderRadius.circular(21),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.error_outline,
              color: Color.fromARGB(255, 210, 61, 61),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '24/7 Emergency',
                  style: TextStyle(
                    color: Color.fromARGB(255, 122, 40, 40),
                    fontSize: 24,
                    height: 1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'For urgent issues only',
                  style: TextStyle(
                    color: Color.fromARGB(255, 138, 91, 91),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: onCallTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 227, 19, 36),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.call_outlined),
                  label: const Text(
                    'Call +94 11 234 5678',
                    style: TextStyle(fontWeight: FontWeight.w700),
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

class _SubmitRequestCard extends StatelessWidget {
  const _SubmitRequestCard({
    required this.controller,
    required this.isSubmitting,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color.fromARGB(255, 228, 228, 228)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Submit New Request',
            style: TextStyle(
              color: Colors.black,
              fontSize: 28,
              height: 1,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Describe the issue you are experiencing',
            style: TextStyle(
              color: Color.fromARGB(255, 125, 125, 125),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: controller,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Please describe the maintenance issue...',
              hintStyle: const TextStyle(color: Color.fromARGB(255, 151, 151, 151)),
              filled: true,
              fillColor: const Color.fromARGB(255, 245, 245, 247),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isSubmitting ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 4, 6, 31),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color.fromARGB(255, 49, 49, 59),
                disabledForegroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_outlined),
              label: Text(
                isSubmitting ? 'Submitting...' : 'Submit Request',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.message,
    required this.status,
    required this.ownerMessage,
    required this.dateLabel,
  });

  final String message;
  final String status;
  final String ownerMessage;
  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    final normalizedStatus = MaintenanceRequestStatus.normalize(status);
    final palette = _statusPalette(normalizedStatus);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color.fromARGB(255, 228, 228, 228)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateLabel,
                style: const TextStyle(
                  color: Color.fromARGB(255, 117, 117, 117),
                  fontSize: 12,
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
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message.trim().isEmpty ? '(No message)' : message.trim(),
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (ownerMessage.trim().isNotEmpty) ...[
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
                'Owner Message: ${ownerMessage.trim()}',
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
  }

  _StatusPalette _statusPalette(String normalizedStatus) {
    switch (normalizedStatus) {
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
          background: Color.fromARGB(255, 221, 246, 231),
          foreground: Color.fromARGB(255, 46, 164, 99),
        );
      case MaintenanceRequestStatus.rejected:
        return const _StatusPalette(
          background: Color.fromARGB(255, 255, 232, 232),
          foreground: Color.fromARGB(255, 178, 54, 54),
        );
      case MaintenanceRequestStatus.pending:
      default:
        return const _StatusPalette(
          background: Color.fromARGB(255, 255, 243, 221),
          foreground: Color.fromARGB(255, 176, 117, 23),
        );
    }
  }
}

class _EmptyRequestsCard extends StatelessWidget {
  const _EmptyRequestsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color.fromARGB(255, 228, 228, 228)),
      ),
      child: const Text(
        'No maintenance requests yet. Submit your first request above.',
        style: TextStyle(
          color: Color.fromARGB(255, 110, 110, 110),
        ),
      ),
    );
  }
}

class _StatusPalette {
  const _StatusPalette({required this.background, required this.foreground});

  final Color background;
  final Color foreground;
}
