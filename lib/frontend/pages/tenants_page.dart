import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:arma2/backend/models/tenant_model.dart';
import 'package:arma2/backend/services/tenants/tenant_service.dart';
import 'package:arma2/frontend/pages/add_tenant_page.dart';

class TenantsPage extends StatefulWidget {
  const TenantsPage({super.key});

  @override
  State<TenantsPage> createState() => _TenantsPageState();
}

class _TenantsPageState extends State<TenantsPage> {
  final TenantService _tenantService = TenantService.instance;

  @override
  void initState() {
    super.initState();
    _cleanupLegacyTenantUserCopies();
  }

  Future<void> _cleanupLegacyTenantUserCopies() async {
    try {
      await _tenantService.cleanupLegacyTenantUserCopies();
    } catch (_) {
      // Keep page usable even if cleanup fails.
    }
  }

  Future<void> _openAddTenantPage() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddTenantPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_tenantService.currentUserId == null) {
      return const Center(child: Text('User not logged in'));
    }

    return Container(
      color: const Color.fromARGB(255, 244, 244, 244),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tenants',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _openAddTenantPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 5, 7, 24),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text(
                    'Add',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<TenantModel>>(
              stream: _tenantService.watchCurrentUserTenants(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Failed to load tenants.\n${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final tenants = snapshot.data ?? const <TenantModel>[];
                if (tenants.isEmpty) {
                  return const Center(child: Text('No tenants added yet'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: tenants.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    return _TenantCard(data: tenants[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TenantCard extends StatelessWidget {
  const _TenantCard({required this.data});

  final TenantModel data;

  String _displayName(String name, String email) {
    final cleanedName = name.trim();
    if (cleanedName.isNotEmpty) {
      return cleanedName;
    }

    final cleanedEmail = email.trim();
    if (cleanedEmail.contains('@')) {
      final local = cleanedEmail.split('@').first.trim();
      if (local.isNotEmpty) {
        return local;
      }
    }

    if (data.id.length >= 6) {
      return 'Tenant ${data.id.substring(0, 6)}';
    }
    return 'Tenant';
  }

  String _initials(String displayName) {
    final parts = displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    final first = parts.isNotEmpty ? parts.first[0] : '';
    final second = parts.length > 1 ? parts[1][0] : '';
    final initials = '$first$second'.trim();

    if (initials.isEmpty) {
      return 'TN';
    }

    return initials.toUpperCase();
  }

  String _formatRentLabel(double value) {
    final rounded = value.round().toString();
    final formatted = rounded.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
    return 'LKR $formatted/mo';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(data.id).snapshots(),
      builder: (context, snapshot) {
        final userData = snapshot.data?.data();
        final tenantName = userData?['name'] is String
            ? (userData?['name'] as String).trim()
            : '';
        final tenantEmail = userData?['email'] is String
            ? (userData?['email'] as String).trim()
            : '';

        final displayName = _displayName(tenantName, tenantEmail);
        final initials = _initials(displayName);

        final propertyName = data.propertyName.trim().isEmpty
            ? 'Unknown property'
            : data.propertyName.trim();
        final unitLabel = data.unitId.trim().isEmpty ? '-' : data.unitId.trim();
        final unitText = unitLabel.toLowerCase().startsWith('unit')
            ? unitLabel
            : 'Unit $unitLabel';
        final rentLabel = _formatRentLabel(data.rentAmount);

        return Card(
          margin: EdgeInsets.zero,
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color.fromARGB(255, 227, 227, 227)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color.fromARGB(255, 239, 240, 242),
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: Color.fromARGB(255, 122, 126, 134),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            propertyName,
                            style: const TextStyle(
                              color: Color.fromARGB(255, 108, 108, 108),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: Color.fromARGB(255, 155, 155, 155),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(
                  height: 1,
                  color: Color.fromARGB(255, 226, 226, 226),
                ),
                const SizedBox(height: 10),
                Text(
                  unitText,
                  style: const TextStyle(
                    color: Color.fromARGB(255, 112, 112, 112),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  rentLabel,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
