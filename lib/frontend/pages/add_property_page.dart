import 'package:flutter/material.dart';
import 'package:arma2/backend/services/properties/property_service.dart';

class AddPropertyPage extends StatefulWidget {
  const AddPropertyPage({super.key});

  @override
  State<AddPropertyPage> createState() => _AddPropertyPageState();
}

class _AddPropertyPageState extends State<AddPropertyPage> {
  final _formKey = GlobalKey<FormState>();
  final PropertyService _propertyService = PropertyService.instance;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _rentController = TextEditingController();
  final TextEditingController _unitsController = TextEditingController();
  final TextEditingController _occupiedController = TextEditingController();

  bool _isLoading = false;

  Future<void> _addProperty() async {
    if (!_formKey.currentState!.validate()) return;

    final rentAmount = double.tryParse(_rentController.text.trim());
    final units = int.tryParse(_unitsController.text.trim());
    final occupied = int.tryParse(_occupiedController.text.trim());

    if (rentAmount == null || rentAmount < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid rent amount")),
      );
      return;
    }

    if (units == null || units <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Total units must be greater than 0")),
      );
      return;
    }

    if (occupied == null || occupied < 0 || occupied > units) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Occupied units must be between 0 and total units"),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _propertyService.addProperty(
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
        const SnackBar(content: Text("Property Added Successfully")),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
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
        title: const Text("Add Property"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Container(
        color: const Color.fromARGB(255, 244, 244, 244),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                _buildField("Property Name", _nameController),
                _buildField("Address", _addressController),
                _buildField("Rent Amount", _rentController, isNumber: true),
                _buildField("Total Units", _unitsController, isNumber: true),
                _buildField(
                  "Occupied Units",
                  _occupiedController,
                  isNumber: true,
                ),

                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: _isLoading ? null : _addProperty,
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
                      : const Text("Add"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    bool isNumber = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        style: const TextStyle(color: Colors.black),
        cursorColor: Colors.black,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return "Required";
          }
          return null;
        },
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
    _nameController.dispose();
    _addressController.dispose();
    _rentController.dispose();
    _unitsController.dispose();
    _occupiedController.dispose();
    super.dispose();
  }
}
