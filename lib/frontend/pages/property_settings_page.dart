import 'package:flutter/material.dart';

import 'package:arma2/backend/models/property_model.dart';
import 'package:arma2/backend/services/properties/property_service.dart';

class PropertySettingsPage extends StatefulWidget {
  const PropertySettingsPage({super.key, required this.property});

  final PropertyModel property;

  @override
  State<PropertySettingsPage> createState() => _PropertySettingsPageState();
}

class _PropertySettingsPageState extends State<PropertySettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final PropertyService _propertyService = PropertyService.instance;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _rentController = TextEditingController();
  final TextEditingController _unitsController = TextEditingController();
  final TextEditingController _occupiedController = TextEditingController();

  bool _isSaving = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.property.propertyName;
    _addressController.text = widget.property.address;
    _rentController.text = widget.property.rentAmount.toString();
    _unitsController.text = widget.property.units.toString();
    _occupiedController.text = widget.property.occupied.toString();

    _rentController.addListener(_onInputsChanged);
    _occupiedController.addListener(_onInputsChanged);
  }

  double get _currentRevenue {
    final rent = double.tryParse(_rentController.text.trim());
    final occupied = int.tryParse(_occupiedController.text.trim());
    if (rent == null || occupied == null || rent < 0 || occupied < 0) {
      return 0;
    }
    return rent * occupied;
  }

  String get _createdAtText {
    final createdAt = widget.property.createdAt;
    if (createdAt == null) {
      return 'Not available';
    }
    final date = createdAt.toDate();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.year}-$month-$day $hour:$minute';
  }

  void _onInputsChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final rentAmount = double.tryParse(_rentController.text.trim());
    final units = int.tryParse(_unitsController.text.trim());
    final occupied = int.tryParse(_occupiedController.text.trim());

    if (rentAmount == null || rentAmount < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid rent amount')),
      );
      return;
    }

    if (units == null || units <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Total units must be greater than 0')),
      );
      return;
    }

    if (occupied == null || occupied < 0 || occupied > units) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Occupied units must be between 0 and total units'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _propertyService.updateProperty(
        propertyId: widget.property.id,
        propertyName: _nameController.text,
        address: _addressController.text,
        rentAmount: rentAmount,
        units: units,
        occupied: occupied,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Property updated successfully')),
      );
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $error')));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteProperty() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Property'),
          content: const Text(
            'Are you sure you want to delete this property? This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    setState(() => _isDeleting = true);

    try {
      await _propertyService.deleteProperty(propertyId: widget.property.id);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Property deleted successfully')),
      );
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $error')));
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Property Settings'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Container(
        color: const Color.fromARGB(255, 244, 244, 244),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                _buildReadOnlyDetail('Property ID', widget.property.id),
                _buildReadOnlyDetail('Owner ID', widget.property.ownerId),
                _buildReadOnlyDetail('Created At', _createdAtText),
                _buildReadOnlyDetail(
                  'Estimated Revenue',
                  'LKR ${_currentRevenue.toStringAsFixed(0)}',
                ),
                const SizedBox(height: 20),
                _buildField('Property Name', _nameController),
                _buildField('Address', _addressController),
                _buildField(
                  'Rent Amount',
                  _rentController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                _buildField(
                  'Total Units',
                  _unitsController,
                  keyboardType: TextInputType.number,
                ),
                _buildField(
                  'Occupied Units',
                  _occupiedController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: (_isSaving || _isDeleting) ? null : _saveChanges,
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
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text('Save Changes'),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: (_isSaving || _isDeleting)
                      ? null
                      : _deleteProperty,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isDeleting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text('Delete Property'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Color.fromARGB(255, 63, 63, 63)),
        cursorColor: const Color.fromARGB(255, 53, 53, 53),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Required';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
          floatingLabelStyle: const TextStyle(
            color: Color.fromARGB(255, 0, 0, 0),
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _rentController.removeListener(_onInputsChanged);
    _occupiedController.removeListener(_onInputsChanged);
    _nameController.dispose();
    _addressController.dispose();
    _rentController.dispose();
    _unitsController.dispose();
    _occupiedController.dispose();
    super.dispose();
  }
}
