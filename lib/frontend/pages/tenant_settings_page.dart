import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:arma2/backend/models/property_model.dart';
import 'package:arma2/backend/models/tenant_model.dart';
import 'package:arma2/backend/services/properties/property_service.dart';
import 'package:arma2/backend/services/tenants/tenant_service.dart';

class TenantSettingsPage extends StatefulWidget {
  const TenantSettingsPage({super.key, required this.tenant});

  final TenantModel tenant;

  @override
  State<TenantSettingsPage> createState() => _TenantSettingsPageState();
}

class _TenantSettingsPageState extends State<TenantSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final PropertyService _propertyService = PropertyService.instance;
  final TenantService _tenantService = TenantService.instance;
  final TextEditingController _unitIdController = TextEditingController();

  String? _selectedPropertyId;
  bool _isSaving = false;
  bool _isRemoving = false;

  @override
  void initState() {
    super.initState();
    _selectedPropertyId = widget.tenant.propertyId;
    _unitIdController.text = widget.tenant.unitId;
  }

  Future<void> _saveAssignment(List<PropertyModel> properties) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final selectedPropertyId = _selectedPropertyId?.trim() ?? '';
    if (selectedPropertyId.isEmpty) {
      _showMessage('Please select a property.');
      return;
    }

    final selectedPropertyExists = properties.any(
      (property) => property.id == selectedPropertyId,
    );
    if (!selectedPropertyExists) {
      _showMessage('Selected property was not found.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _tenantService.moveTenantAssignment(
        tenantUid: widget.tenant.tenantUid,
        currentPropertyId: widget.tenant.propertyId,
        currentUnitId: widget.tenant.unitId,
        currentAssignmentDocId: widget.tenant.id,
        targetPropertyId: selectedPropertyId,
        targetUnitId: _unitIdController.text,
      );

      if (!mounted) {
        return;
      }

      _showMessage('Tenant assignment updated.');
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage('Error: $error');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _removeTenant() async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remove Tenant'),
          content: const Text(
            'Remove this tenant from the selected property and unit?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (shouldRemove != true) {
      return;
    }

    setState(() => _isRemoving = true);
    try {
      await _tenantService.removeTenantFromProperty(
        tenantUid: widget.tenant.tenantUid,
        propertyId: widget.tenant.propertyId,
        unitId: widget.tenant.unitId,
        assignmentDocId: widget.tenant.id,
      );

      if (!mounted) {
        return;
      }

      _showMessage('Tenant removed from property.');
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage('Error: $error');
    } finally {
      if (mounted) {
        setState(() => _isRemoving = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatValue(dynamic value) {
    if (value == null) {
      return '-';
    }
    if (value is Timestamp) {
      return value.toDate().toLocal().toString();
    }
    if (value is DateTime) {
      return value.toLocal().toString();
    }
    if (value is List) {
      if (value.isEmpty) {
        return '[]';
      }
      return value.join(', ');
    }
    if (value is Map) {
      if (value.isEmpty) {
        return '{}';
      }
      return value.toString();
    }
    return value.toString();
  }

  String _formatKey(String key) {
    if (key.trim().isEmpty) {
      return key;
    }

    final withSpaces = key.replaceAll('_', ' ').replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (match) {
        return '${match.group(1)} ${match.group(2)}';
      },
    ).trim();
    return withSpaces.isEmpty
        ? key
        : '${withSpaces[0].toUpperCase()}${withSpaces.substring(1)}';
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(
                color: Color.fromARGB(255, 88, 88, 88),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 5,
            child: Text(
              value,
              style: const TextStyle(color: Colors.black, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tenantUid = widget.tenant.tenantUid.trim();
    final userDocStream = tenantUid.isEmpty
        ? null
        : FirebaseFirestore.instance
              .collection('users')
              .doc(tenantUid)
              .snapshots();

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 244, 244, 244),
      appBar: AppBar(
        title: const Text('Tenant Settings'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: userDocStream,
        builder: (context, userSnapshot) {
          final userData = userSnapshot.data?.data();

          return StreamBuilder<List<PropertyModel>>(
            stream: _propertyService.watchCurrentUserProperties(),
            builder: (context, propertySnapshot) {
              if (propertySnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (propertySnapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Failed to load properties.\n${propertySnapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              final properties =
                  propertySnapshot.data ?? const <PropertyModel>[];
              final hasSelectedProperty = properties.any(
                (property) => property.id == _selectedPropertyId,
              );

              final userEntries =
                  userData?.entries
                      .where(
                        (entry) => !entry.key.toLowerCase().contains('uid'),
                      )
                      .toList() ??
                  const <MapEntry<String, dynamic>>[];
              final sortedEntries = userEntries.toList()
                ..sort((a, b) => a.key.compareTo(b.key));

              return Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildSection(
                      title: 'Tenant User Data',
                      children:
                          userSnapshot.connectionState ==
                              ConnectionState.waiting
                          ? const [Center(child: CircularProgressIndicator())]
                          : sortedEntries.isEmpty
                          ? const [
                              Text(
                                'No user data found for this tenant.',
                                style: TextStyle(color: Colors.black87),
                              ),
                            ]
                          : sortedEntries
                                .map(
                                  (entry) => _buildDetailRow(
                                    _formatKey(entry.key),
                                    _formatValue(entry.value),
                                  ),
                                )
                                .toList(),
                    ),
                    _buildSection(
                      title: 'Change Property / Unit',
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: hasSelectedProperty
                              ? _selectedPropertyId
                              : null,
                          items: properties
                              .map(
                                (property) => DropdownMenuItem<String>(
                                  value: property.id,
                                  child: Text(property.propertyName),
                                ),
                              )
                              .toList(),
                          onChanged: properties.isEmpty
                              ? null
                              : (value) =>
                                    setState(() => _selectedPropertyId = value),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Required';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            labelText: 'Property',
                            labelStyle: const TextStyle(color: Colors.black87),
                            floatingLabelStyle: const TextStyle(
                              color: Colors.black,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color.fromARGB(255, 210, 210, 210),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.black),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _unitIdController,
                          style: const TextStyle(color: Colors.black),
                          cursorColor: Colors.black,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Required';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            labelText: 'Unit ID',
                            labelStyle: const TextStyle(color: Colors.black87),
                            floatingLabelStyle: const TextStyle(
                              color: Colors.black,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color.fromARGB(255, 210, 210, 210),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.black),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed:
                                _isSaving || _isRemoving || properties.isEmpty
                                ? null
                                : () => _saveAssignment(properties),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Save Changes'),
                          ),
                        ),
                      ],
                    ),
                    _buildSection(
                      title: 'Remove Tenant',
                      children: [
                        const Text(
                          'This removes the tenant assignment from the current property and unit.',
                          style: TextStyle(
                            color: Color.fromARGB(255, 90, 90, 90),
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSaving || _isRemoving
                                ? null
                                : _removeTenant,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(
                                255,
                                173,
                                27,
                                27,
                              ),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isRemoving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Remove Tenant From Property'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _unitIdController.dispose();
    super.dispose();
  }
}
