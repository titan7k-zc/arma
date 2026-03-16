import 'package:flutter/material.dart';

import 'package:arma2/backend/services/tenants/tenant_portal_service.dart';

class TenantHomePage extends StatefulWidget {
  const TenantHomePage({super.key});

  @override
  State<TenantHomePage> createState() => _TenantHomePageState();
}

class _TenantHomePageState extends State<TenantHomePage> {
  final TenantPortalService _portalService = TenantPortalService.instance;
  bool _isPaying = false;

  String _paymentErrorMessage(Object error) {
    final raw = error.toString().toLowerCase();
    if (raw.contains('chain validation failed') ||
        raw.contains('an internal error has occurred')) {
      return 'Payment failed. Check internet and phone time, then try again.';
    }
    return 'Payment failed: $error';
  }

  Future<void> _payNow(TenantLeaseInfo lease) async {
    if (_isPaying) {
      return;
    }

    final shouldPay = await _showPaymentConfirmationDialog(
      amountLabel: _formatCurrency(lease.rentAmount),
    );
    if (!shouldPay) {
      return;
    }

    setState(() => _isPaying = true);

    try {
      await _portalService.payRent(lease: lease);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment recorded successfully.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_paymentErrorMessage(error))));
    } finally {
      if (mounted) {
        setState(() => _isPaying = false);
      }
    }
  }

  String _formatCurrency(double value) {
    final rounded = value.round().toString();
    final formatted = rounded.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
    return 'LKR $formatted';
  }

  String _formatShortDate(DateTime value) {
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
    return '${months[value.month - 1]} ${value.day}';
  }

  Future<bool> _showPaymentConfirmationDialog({
    required String amountLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Payment'),
          content: Text('Do you want to pay $amountLabel now?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<TenantLeaseInfo?>(
      stream: _portalService.watchCurrentTenantLease(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Failed to load tenant home data.\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final lease = snapshot.data;
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
              _HomeSummaryRow(
                daysUntilDue: lease.daysUntilCurrentDue,
                monthlyRentLabel: _formatCurrency(lease.rentAmount),
              ),
              const SizedBox(height: 14),
              _ResidenceCard(
                propertyName: lease.propertyName,
                address: lease.address,
                unitId: lease.unitId,
              ),
              const SizedBox(height: 14),
              _NextPaymentCard(
                amountLabel: _formatCurrency(lease.rentAmount),
                dueDateLabel: _formatShortDate(lease.nextDueAt),
                isPaying: _isPaying,
                onPayNow: () => _payNow(lease),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HomeSummaryRow extends StatelessWidget {
  const _HomeSummaryRow({required this.daysUntilDue, required this.monthlyRentLabel});

  final int daysUntilDue;
  final String monthlyRentLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            icon: Icons.calendar_month_outlined,
            iconBackground: const Color.fromARGB(255, 232, 240, 255),
            iconColor: const Color.fromARGB(255, 68, 117, 230),
            value: daysUntilDue.toString(),
            label: 'Days until due',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MetricCard(
            icon: Icons.attach_money_outlined,
            iconBackground: const Color.fromARGB(255, 228, 248, 236),
            iconColor: const Color.fromARGB(255, 42, 167, 104),
            value: monthlyRentLabel,
            label: 'Monthly rent',
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color.fromARGB(255, 228, 228, 228)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 28,
              height: 1,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color.fromARGB(255, 115, 115, 115),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResidenceCard extends StatelessWidget {
  const _ResidenceCard({
    required this.propertyName,
    required this.address,
    required this.unitId,
  });

  final String propertyName;
  final String address;
  final String unitId;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 9, 197, 78),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  propertyName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    height: 1.05,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Text(
                  'Active',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: Colors.white70, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  address.trim().isEmpty ? 'Address not set' : address,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            height: 1,
            color: Colors.white.withOpacity(0.25),
          ),
          const SizedBox(height: 12),
          _ResidenceMetric(
            label: 'Unit Number',
            value: unitId,
          ),
        ],
      ),
    );
  }
}

class _ResidenceMetric extends StatelessWidget {
  const _ResidenceMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            height: 1,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _NextPaymentCard extends StatelessWidget {
  const _NextPaymentCard({
    required this.amountLabel,
    required this.dueDateLabel,
    required this.onPayNow,
    required this.isPaying,
  });

  final String amountLabel;
  final String dueDateLabel;
  final VoidCallback onPayNow;
  final bool isPaying;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color.fromARGB(255, 228, 228, 228)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Next Payment',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 247, 247, 247),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: const Color.fromARGB(255, 224, 224, 224),
                  ),
                ),
                child: const Text(
                  'Due Soon',
                  style: TextStyle(
                    color: Color.fromARGB(255, 95, 95, 95),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _PaymentDetail(label: 'Amount Due', value: amountLabel),
              _PaymentDetail(label: 'Due Date', value: dueDateLabel, alignEnd: true),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isPaying ? null : onPayNow,
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
              icon: isPaying
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.credit_card_outlined),
              label: Text(
                isPaying ? 'Processing...' : 'Pay Now',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentDetail extends StatelessWidget {
  const _PaymentDetail({
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color.fromARGB(255, 124, 124, 124),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 24,
            height: 1,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
