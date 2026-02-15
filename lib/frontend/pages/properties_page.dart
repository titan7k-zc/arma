import 'package:flutter/material.dart';
import 'package:arma2/backend/models/property_model.dart';
import 'package:arma2/backend/services/properties/property_service.dart';
import 'package:arma2/frontend/pages/add_property_page.dart';

class PropertiesPage extends StatelessWidget {
  const PropertiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final propertyService = PropertyService.instance;

    if (propertyService.currentUserId == null) {
      return const Center(child: Text("User not logged in"));
    }

    return Container(
      color: const Color.fromARGB(255, 244, 244, 244),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Title + Add Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Properties",
                  style: TextStyle(
                    fontSize: 22,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddPropertyPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("Add"),
                ),
              ],
            ),
          ),

          /// Firestore Property List
          Expanded(
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
                        "Failed to load properties.\n${snapshot.error}",
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final properties = snapshot.data ?? const <PropertyModel>[];
                if (properties.isEmpty) {
                  return const Center(child: Text("No properties added yet"));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: properties.length,
                  itemBuilder: (context, index) {
                    final property = properties[index];

                    return PropertyCard(
                      title: property.propertyName,
                      location: property.address,
                      units: property.units.toString(),
                      occupied: property.occupied.toString(),
                      revenue: "LKR ${property.revenue.toStringAsFixed(0)}",
                    );
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

class PropertyCard extends StatelessWidget {
  final String title;
  final String location;
  final String units;
  final String occupied;
  final String revenue;

  const PropertyCard({
    super.key,
    required this.title,
    required this.location,
    required this.units,
    required this.occupied,
    required this.revenue,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),

            const SizedBox(height: 4),

            /// Address
            Text(
              location,
              style: const TextStyle(color: Color.fromARGB(255, 104, 104, 104)),
            ),

            const Divider(height: 24),

            /// Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStat("Units", units),
                _buildStat("Occupied", occupied),
                _buildStat("Revenue", revenue, isRevenue: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, {bool isRevenue = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isRevenue
                ? Colors.green
                : const Color.fromARGB(255, 0, 0, 0),
          ),
        ),
      ],
    );
  }
}
