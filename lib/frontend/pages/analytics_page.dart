import 'package:flutter/material.dart';

import 'package:arma2/backend/models/property_model.dart';
import 'package:arma2/backend/services/properties/property_service.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  String _formatCurrency(double value) {
    final rounded = value.round().toString();
    final formatted = rounded.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
    return 'LKR $formatted';
  }

  @override
  Widget build(BuildContext context) {
    final propertyService = PropertyService.instance;
    if (propertyService.currentUserId == null) {
      return const Center(child: Text('User not logged in'));
    }

    return Container(
      color: const Color.fromARGB(255, 244, 244, 244),
      child: StreamBuilder<List<PropertyModel>>(
        stream: propertyService.watchCurrentUserProperties(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Failed to load analytics.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final properties = snapshot.data ?? const <PropertyModel>[];

          final totalProperties = properties.length;
          final totalUnits = properties.fold<int>(
            0,
            (sum, property) => sum + property.units,
          );
          final occupiedUnits = properties.fold<int>(
            0,
            (sum, property) => sum + property.occupied,
          );
          final vacantUnits = (totalUnits - occupiedUnits).clamp(
            0,
            totalUnits,
          ) as int;
          final occupancyRate = totalUnits <= 0
              ? 0.0
              : (occupiedUnits / totalUnits) * 100;
          final monthlyRevenue = properties.fold<double>(
            0,
            (sum, property) => sum + property.revenue,
          );

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              const Text(
                'Analytics',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _KpiCard(
                      title: 'Properties',
                      value: totalProperties.toString(),
                      icon: Icons.apartment_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _KpiCard(
                      title: 'Occupancy',
                      value: '${occupancyRate.toStringAsFixed(0)}%',
                      subtitle: '$occupiedUnits / $totalUnits units',
                      icon: Icons.pie_chart_outline,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _KpiCard(
                      title: 'Occupied Units',
                      value: occupiedUnits.toString(),
                      icon: Icons.meeting_room_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _KpiCard(
                      title: 'Vacant Units',
                      value: vacantUnits.toString(),
                      icon: Icons.door_front_door_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _KpiCard(
                title: 'Estimated Monthly Revenue',
                value: _formatCurrency(monthlyRevenue),
                icon: Icons.payments_outlined,
              ),
              const SizedBox(height: 14),
              _Panel(
                title: 'Occupancy By Property',
                child: properties.isEmpty
                    ? const _EmptyText(text: 'No properties to analyze yet.')
                    : Column(
                        children: properties
                            .map((property) {
                              final safeUnits = property.units <= 0
                                  ? 1
                                  : property.units;
                              final ratio =
                                  (property.occupied / safeUnits)
                                      .clamp(0.0, 1.0)
                                      .toDouble();
                              return _PropertyProgressTile(
                                title: property.propertyName.trim().isEmpty
                                    ? 'Untitled property'
                                    : property.propertyName.trim(),
                                caption:
                                    '${property.occupied}/${property.units} units',
                                percentage: ratio * 100,
                                progress: ratio,
                              );
                            })
                            .toList()
                            .cast<Widget>(),
                      ),
              ),
              const SizedBox(height: 14),
              _Panel(
                title: 'Revenue By Property',
                child: properties.isEmpty
                    ? const _EmptyText(text: 'No revenue data yet.')
                    : _RevenueBars(
                        rows: properties
                            .map(
                              (property) => _RevenueRow(
                                name: property.propertyName.trim().isEmpty
                                    ? 'Untitled property'
                                    : property.propertyName.trim(),
                                revenue: property.revenue,
                              ),
                            )
                            .toList(),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color.fromARGB(255, 226, 226, 226)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    this.subtitle,
  });

  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color.fromARGB(255, 226, 226, 226)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.black87),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.black,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color.fromARGB(255, 95, 95, 95),
            ),
          ),
          if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 12,
                color: Color.fromARGB(255, 120, 120, 120),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PropertyProgressTile extends StatelessWidget {
  const _PropertyProgressTile({
    required this.title,
    required this.caption,
    required this.percentage,
    required this.progress,
  });

  final String title;
  final String caption;
  final double percentage;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            caption,
            style: const TextStyle(
              fontSize: 12,
              color: Color.fromARGB(255, 116, 116, 116),
            ),
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: progress,
              backgroundColor: const Color.fromARGB(255, 236, 236, 236),
              color: const Color.fromARGB(255, 77, 158, 109),
            ),
          ),
        ],
      ),
    );
  }
}

class _RevenueRow {
  const _RevenueRow({required this.name, required this.revenue});

  final String name;
  final double revenue;
}

class _RevenueBars extends StatelessWidget {
  const _RevenueBars({required this.rows});

  final List<_RevenueRow> rows;

  String _formatCurrency(double value) {
    final rounded = value.round().toString();
    final formatted = rounded.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
    return 'LKR $formatted';
  }

  @override
  Widget build(BuildContext context) {
    final maxRevenue = rows.fold<double>(0, (max, row) {
      return row.revenue > max ? row.revenue : max;
    });

    return Column(
      children: rows.map((row) {
        final ratio = maxRevenue <= 0
            ? 0.0
            : (row.revenue / maxRevenue).clamp(0.0, 1.0).toDouble();
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      row.name,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatCurrency(row.revenue),
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  minHeight: 8,
                  value: ratio,
                  backgroundColor: const Color.fromARGB(255, 236, 236, 236),
                  color: const Color.fromARGB(255, 97, 111, 228),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _EmptyText extends StatelessWidget {
  const _EmptyText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color.fromARGB(255, 108, 108, 108),
        fontSize: 13,
      ),
    );
  }
}
