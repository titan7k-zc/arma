import 'package:flutter/material.dart';

import 'package:arma2/backend/models/property_model.dart';
import 'package:arma2/backend/services/properties/property_service.dart';
import 'package:arma2/backend/services/tenants/tenant_service.dart';

class AddTenantPage extends StatefulWidget {
  const AddTenantPage({super.key});

  @override
  State<AddTenantPage> createState() => _AddTenantPageState();
}

class _AddTenantPageState extends State<AddTenantPage> {
  final _formKey = GlobalKey<FormState>();
  final PropertyService _propertyService = PropertyService.instance;
  final TenantService _tenantService = TenantService.instance;

  final TextEditingController _unitIdController = TextEditingController();
  final TextEditingController _tenantEmailController = TextEditingController();

  String? _selectedPropertyId;
  bool _isLoading = false;

  Future<void> _addTenant() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final selectedPropertyId = _selectedPropertyId;
    if (selectedPropertyId == null || selectedPropertyId.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a property')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _tenantService.addTenantToProperty(
        propertyId: selectedPropertyId,
        unitId: _unitIdController.text,
        tenantEmail: _tenantEmailController.text,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tenant added successfully')),
      );
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $error')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 244, 244, 244),
      appBar: AppBar(
        title: const Text('Add Tenant'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: StreamBuilder<List<PropertyModel>>(
            stream: _propertyService.watchCurrentUserProperties(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'Failed to load properties.\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              final properties = snapshot.data ?? const <PropertyModel>[];
              if (properties.isEmpty) {
                return const Center(
                  child: Text('Add a property first before adding tenants.'),
                );
              }

              final hasSelectedProperty = properties.any(
                (property) => property.id == _selectedPropertyId,
              );

              return ListView(
                children: [
                  _buildPropertyField(
                    properties: properties,
                    selectedPropertyId: hasSelectedProperty
                        ? _selectedPropertyId
                        : null,
                  ),
                  _buildTextField(
                    label: 'Unit ID',
                    controller: _unitIdController,
                    keyboardType: TextInputType.text,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                  _buildTextField(
                    label: 'Tenant Email',
                    controller: _tenantEmailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) {
                        return 'Required';
                      }
                      final emailPattern = RegExp(
                        r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                      );
                      if (!emailPattern.hasMatch(text)) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _addTenant,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text('Add'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPropertyField({
    required List<PropertyModel> properties,
    required String? selectedPropertyId,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        initialValue: selectedPropertyId,
        items: properties
            .map(
              (property) => DropdownMenuItem<String>(
                value: property.id,
                child: Text(property.propertyName),
              ),
            )
            .toList(),
        onChanged: (value) {
          setState(() => _selectedPropertyId = value);
        },
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Required';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: 'Property',
          labelStyle: const TextStyle(color: Colors.black87),
          floatingLabelStyle: const TextStyle(color: Colors.black),
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
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required TextInputType keyboardType,
    required String? Function(String?) validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.black),
        cursorColor: Colors.black,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black87),
          floatingLabelStyle: const TextStyle(color: Colors.black),
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
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _unitIdController.dispose();
    _tenantEmailController.dispose();
    super.dispose();
  }
}
