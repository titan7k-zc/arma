import 'package:cloud_firestore/cloud_firestore.dart';

class PropertyModel {
  const PropertyModel({
    required this.id,
    required this.ownerId,
    required this.propertyName,
    required this.address,
    required this.rentAmount,
    required this.units,
    required this.occupied,
    required this.createdAt,
  });

  final String id;
  final String ownerId;
  final String propertyName;
  final String address;
  final double rentAmount;
  final int units;
  final int occupied;
  final Timestamp? createdAt;

  double get revenue => rentAmount * occupied;

  Map<String, dynamic> toFirestore() {
    return {
      'ownerId': ownerId,
      'propertyName': propertyName,
      'address': address,
      'rentAmount': rentAmount,
      'units': units,
      'occupied': occupied,
    };
  }

  factory PropertyModel.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return PropertyModel(
      id: doc.id,
      ownerId: _asString(data['ownerId']),
      propertyName: _asString(data['propertyName']),
      address: _asString(data['address']),
      rentAmount: _asDouble(data['rentAmount']),
      units: _asInt(data['units']),
      occupied: _asInt(data['occupied']),
      createdAt: data['createdAt'] is Timestamp
          ? data['createdAt'] as Timestamp
          : null,
    );
  }

  static String _asString(dynamic value) {
    return value is String ? value : '';
  }

  static int _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value.trim()) ?? 0;
    }
    return 0;
  }

  static double _asDouble(dynamic value) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value.trim()) ?? 0;
    }
    return 0;
  }
}
