import 'package:flutter/material.dart';
import 'package:arma2/backend/models/property_model.dart';
import 'package:arma2/backend/services/auth/session_service.dart';
import 'package:arma2/backend/services/properties/property_service.dart';
import 'package:arma2/backend/services/tenants/tenant_service.dart';
import 'package:arma2/frontend/pages/add_property_page.dart';
import 'package:arma2/frontend/pages/add_tenant_page.dart';
import 'package:arma2/frontend/pages/login_page.dart';
import 'package:arma2/frontend/pages/properties_page.dart';
import 'package:arma2/frontend/pages/tenants_page.dart';
import 'package:arma2/frontend/pages/analytics_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final SessionService _sessionService = SessionService.instance;

  int _selectedIndex = 0;
  bool _isLoggingOut = false;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  String get _userName {
    final displayName = _sessionService.currentUser?.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    final email = _sessionService.currentUser?.email?.trim();
    if (email != null && email.isNotEmpty) {
      final userPart = email.split('@').first.trim();
      if (userPart.isNotEmpty) {
        return userPart;
      }
    }

    return 'User';
  }

  String get _userEmail {
    final email = _sessionService.currentUser?.email?.trim();
    if (email != null && email.isNotEmpty) {
      return email;
    }
    return 'No email';
  }

  String get _userAvatarText {
    final compactName = _userName.replaceAll(RegExp(r'\s+'), '');
    if (compactName.isEmpty) {
      return 'US';
    }
    if (compactName.length == 1) {
      return compactName.toUpperCase();
    }
    return compactName.substring(0, 2).toUpperCase();
  }

  Future<void> _refreshProperties() async {
    try {
      await PropertyService.instance.refreshCurrentUserProperties();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Properties refreshed")));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Refresh failed: $error")));
    }
  }

  Future<void> _refreshTenants() async {
    try {
      await TenantService.instance.refreshCurrentUserTenants();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Tenants refreshed")));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Refresh failed: $error")));
    }
  }

  Future<void> _logout() async {
    if (_isLoggingOut) {
      return;
    }

    setState(() => _isLoggingOut = true);

    try {
      await _sessionService.signOut();

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _isLoggingOut = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Logout failed: $error")));
    }
  }

  Widget _buildAccountDrawer() {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.82,
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Account',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.black),
                    tooltip: 'Close',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'User Profile',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                margin: EdgeInsets.zero,
                color: Colors.white,
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(
                    color: Color.fromARGB(255, 230, 230, 230),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color.fromARGB(
                          255,
                          236,
                          240,
                          255,
                        ),
                        child: Text(
                          _userAvatarText,
                          style: const TextStyle(
                            color: Colors.deepPurple,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _userName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _userEmail,
                              style: const TextStyle(
                                color: Color.fromARGB(255, 96, 96, 96),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoggingOut ? null : _logout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoggingOut
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Logout',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openAddPropertyPage() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddPropertyPage()),
    );
  }

  Future<void> _openAddTenantPage() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddTenantPage()),
    );
  }

  Widget _buildCurrentPage() {
    switch (_selectedIndex) {
      case 0:
        return _OwnerHomeDashboard(
          onAddProperty: _openAddPropertyPage,
          onAddTenant: _openAddTenantPage,
        );
      case 1:
        return const PropertiesPage();
      case 2:
        return const TenantsPage();
      case 3:
        return const AnalyticsPage();
      default:
        return const AnalyticsPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      endDrawer: _buildAccountDrawer(),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text("Arma"),
        actions: [
          if (_selectedIndex == 0 || _selectedIndex == 1)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: _selectedIndex == 0
                  ? "Refresh home data"
                  : "Refresh properties",
              onPressed: _refreshProperties,
            ),
          if (_selectedIndex == 2)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: "Refresh tenants",
              onPressed: _refreshTenants,
            ),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
              child: CircleAvatar(
                backgroundColor: Colors.deepPurple,
                child: Text(
                  _userAvatarText,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _buildCurrentPage(),

      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.apartment_outlined),
            label: "Properties",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: "Tenants",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            label: "Analytics",
          ),
        ],
      ),
    );
  }
}

class _OwnerHomeDashboard extends StatelessWidget {
  const _OwnerHomeDashboard({
    required this.onAddProperty,
    required this.onAddTenant,
  });

  final Future<void> Function() onAddProperty;
  final Future<void> Function() onAddTenant;

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
                      onTap: () {
                        onAddProperty();
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.person_outline,
                      title: 'Add Tenant',
                      onTap: () {
                        onAddTenant();
                      },
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
