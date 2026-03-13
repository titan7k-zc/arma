import 'package:flutter/material.dart';

import 'package:arma2/backend/models/property_model.dart';
import 'package:arma2/backend/services/properties/property_service.dart';
import 'package:arma2/frontend/pages/add_property_page.dart';
import 'package:arma2/frontend/pages/add_tenant_page.dart';

class OwnerHomePage extends StatelessWidget {
  const OwnerHomePage({super.key});

  String _formatCurrency(double value) {
    final rounded = value.round().toString();
    final formatted = rounded.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
    return 'LKR $formatted';
  }

  Future<void> _openAddPropertyPage(BuildContext context) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddPropertyPage()),
    );
  }

  Future<void> _openAddTenantPage(BuildContext context) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddTenantPage()),
    );
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
                  'Failed to load home metrics.\n${snapshot.error}',
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
          final monthlyRevenue = properties.fold<double>(
            0,
            (sum, property) => sum + property.revenue,
          );
          final occupancyPercentage = totalUnits <= 0
              ? 0.0
              : (occupiedUnits / totalUnits) * 100;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _DashboardStatCard(
                      icon: Icons.home_work_outlined,
                      iconColor: const Color.fromARGB(255, 69, 114, 230),
                      iconBackground: const Color.fromARGB(255, 235, 242, 255),
                      value: totalProperties.toString(),
                      label: 'Properties',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DashboardStatCard(
                      icon: Icons.group_outlined,
                      iconColor: const Color.fromARGB(255, 40, 164, 103),
                      iconBackground: const Color.fromARGB(255, 231, 248, 238),
                      value: occupiedUnits.toString(),
                      label:
                          '${occupancyPercentage.toStringAsFixed(0)}% Occupancy',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _RevenueCard(totalRevenue: _formatCurrency(monthlyRevenue)),
              const SizedBox(height: 20),
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.add,
                      title: 'Add Property',
                      onTap: () => _openAddPropertyPage(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.person_outline,
                      title: 'Add Tenant',
                      onTap: () => _openAddTenantPage(context),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DashboardStatCard extends StatelessWidget {
  const _DashboardStatCard({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color.fromARGB(255, 225, 225, 225)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w800,
              fontSize: 32,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color.fromARGB(255, 102, 102, 102),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _RevenueCard extends StatelessWidget {
  const _RevenueCard({required this.totalRevenue});

  final String totalRevenue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color.fromARGB(255, 225, 225, 225)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 239, 233, 255),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: const Text(
              '\$',
              style: TextStyle(
                color: Color.fromARGB(255, 102, 70, 220),
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  totalRevenue,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Monthly Revenue',
                  style: TextStyle(
                    color: Color.fromARGB(255, 102, 102, 102),
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
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

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color.fromARGB(255, 225, 225, 225)),
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.black, size: 18),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
