import 'package:flutter/material.dart';

import 'package:arma2/backend/services/tenants/tenant_portal_service.dart';

class TenantPaymentsPage extends StatefulWidget {
  const TenantPaymentsPage({super.key});

  @override
  State<TenantPaymentsPage> createState() => _TenantPaymentsPageState();
}

class _TenantPaymentsPageState extends State<TenantPaymentsPage> {
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

  Future<void> _payRent(TenantLeaseInfo lease) async {
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

  String _formatDate(DateTime? value) {
    if (value == null) {
      return 'Unknown date';
    }

    const months = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${months[value.month - 1]} ${value.day}, ${value.year}';
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

  int _onTimePercentage(List<TenantPaymentRecord> payments) {
    final paid = payments
        .where((payment) => payment.status.toLowerCase() == 'paid')
        .toList();

    if (paid.isEmpty) {
      return 0;
    }

    final onTimeCount = paid.where((payment) {
      final paidAt = payment.paidAt;
      if (paidAt == null) {
        return false;
      }

      final dueAt = payment.dueAt;
      if (dueAt == null) {
        return true;
      }

      return !paidAt.isAfter(dueAt);
    }).length;

    return ((onTimeCount / paid.length) * 100).round();
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
                'Failed to load payment data.\n${leaseSnapshot.error}',
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

        return StreamBuilder<List<TenantPaymentRecord>>(
          stream: _portalService.watchTenantPayments(),
          builder: (context, paymentsSnapshot) {
            final payments = paymentsSnapshot.data ?? const <TenantPaymentRecord>[];
            final now = DateTime.now();
            final paidThisYear = payments
                .where(
                  (payment) =>
                      payment.status.toLowerCase() == 'paid' &&
                      payment.paidAt?.year == now.year,
                )
                .fold<double>(0, (sum, payment) => sum + payment.amount);

            final onTime = _onTimePercentage(payments);

            return Container(
              color: const Color.fromARGB(255, 244, 244, 244),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  _PaymentsTopRow(
                    isPaying: _isPaying,
                    onPayRent: () => _payRent(lease),
                  ),
                  const SizedBox(height: 12),
                  _PaymentsSummaryRow(
                    paidThisYearLabel: _formatCurrency(paidThisYear),
                    onTimePercentage: onTime,
                    nextDueLabel: _formatCurrency(lease.rentAmount),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Payment History',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (paymentsSnapshot.connectionState == ConnectionState.waiting)
                    const Center(child: CircularProgressIndicator()),
                  if (paymentsSnapshot.hasError)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        'Failed to load payment history.\n${paymentsSnapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  if (!paymentsSnapshot.hasError && payments.isEmpty)
                    const _EmptyHistoryCard(),
                  ...payments.map(
                    (payment) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _PaymentHistoryCard(
                        amountLabel: _formatCurrency(payment.amount),
                        dateLabel: _formatDate(payment.paidAt),
                        method: payment.method,
                        status: payment.status,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _PaymentsTopRow extends StatelessWidget {
  const _PaymentsTopRow({required this.isPaying, required this.onPayRent});

  final bool isPaying;
  final VoidCallback onPayRent;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Payments',
          style: TextStyle(
            color: Colors.black,
            fontSize: 30,
            height: 1,
            fontWeight: FontWeight.w700,
          ),
        ),
        ElevatedButton.icon(
          onPressed: isPaying ? null : onPayRent,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 4, 6, 31),
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color.fromARGB(255, 49, 49, 59),
            disabledForegroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: isPaying
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.credit_card_outlined, size: 16),
          label: Text(
            isPaying ? 'Processing...' : 'Pay Rent',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _PaymentsSummaryRow extends StatelessWidget {
  const _PaymentsSummaryRow({
    required this.paidThisYearLabel,
    required this.onTimePercentage,
    required this.nextDueLabel,
  });

  final String paidThisYearLabel;
  final int onTimePercentage;
  final String nextDueLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: 'Paid (${DateTime.now().year})',
            value: paidThisYearLabel,
            valueColor: const Color.fromARGB(255, 24, 163, 92),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            title: 'On-Time',
            value: '$onTimePercentage%',
            valueColor: const Color.fromARGB(255, 42, 107, 228),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            title: 'Next Due',
            value: nextDueLabel,
            valueColor: Colors.black,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.valueColor,
  });

  final String title;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color.fromARGB(255, 228, 228, 228)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color.fromARGB(255, 126, 126, 126),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 22,
              height: 1.05,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentHistoryCard extends StatelessWidget {
  const _PaymentHistoryCard({
    required this.amountLabel,
    required this.dateLabel,
    required this.method,
    required this.status,
  });

  final String amountLabel;
  final String dateLabel;
  final String method;
  final String status;

  @override
  Widget build(BuildContext context) {
    final isPaid = status.toLowerCase() == 'paid';
    final badgeColor = isPaid
        ? const Color.fromARGB(255, 221, 246, 231)
        : const Color.fromARGB(255, 255, 237, 212);
    final textColor = isPaid
        ? const Color.fromARGB(255, 46, 164, 99)
        : const Color.fromARGB(255, 176, 117, 23);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color.fromARGB(255, 228, 228, 228)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      amountLabel,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 26,
                        height: 1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateLabel,
                      style: const TextStyle(
                        color: Color.fromARGB(255, 111, 111, 111),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPaid ? Icons.check_circle_outline : Icons.schedule_outlined,
                      color: textColor,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isPaid ? 'Paid' : status,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                method,
                style: const TextStyle(
                  color: Color.fromARGB(255, 109, 109, 109),
                  fontSize: 14,
                ),
              ),
              TextButton.icon(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.download_outlined, size: 18),
                label: const Text(
                  'Receipt',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyHistoryCard extends StatelessWidget {
  const _EmptyHistoryCard();

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
        'No payment records yet. Use "Pay Rent" to create your first payment.',
        style: TextStyle(
          color: Color.fromARGB(255, 110, 110, 110),
        ),
      ),
    );
  }
}
