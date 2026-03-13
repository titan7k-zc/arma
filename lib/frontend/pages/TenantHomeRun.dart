import 'package:flutter/material.dart';

import 'package:arma2/backend/services/auth/session_service.dart';
import 'package:arma2/frontend/pages/login_page.dart';
import 'package:arma2/frontend/pages/Tenant_home_page.dart';
import 'package:arma2/frontend/pages/tenant_maintenance_page.dart';
import 'package:arma2/frontend/pages/tenant_payments_page.dart';

class TenantHomeRun extends StatefulWidget {
  const TenantHomeRun({super.key});

  @override
  State<TenantHomeRun> createState() => _TenantHomeRunState();
}

class _TenantHomeRunState extends State<TenantHomeRun> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final SessionService _sessionService = SessionService.instance;
  final List<Widget> _tenantPages = const [
    TenantHomePage(),
    TenantPaymentsPage(),
    TenantMaintenancePage(),
  ];

  int _selectedIndex = 0;
  bool _isLoggingOut = false;

  void _onItemTapped(int index) {
    if (_selectedIndex == index) {
      return;
    }

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
      ).showSnackBar(SnackBar(content: Text('Logout failed: $error')));
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

  String get _appBarTitle {
    switch (_selectedIndex) {
      case 0:
        return 'Home';
      case 1:
        return 'Payments';
      case 2:
        return 'Maintanance';
      default:
        return 'Home';
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
        title: Text(_appBarTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
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
      body: IndexedStack(index: _selectedIndex, children: _tenantPages),
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
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payments_outlined),
            label: 'Payments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.build_outlined),
            label: 'Maintanance',
          ),
        ],
      ),
    );
  }
}
