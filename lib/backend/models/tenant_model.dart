import 'package:cloud_firestore/cloud_firestore.dart';

class TenantModel {
  const TenantModel({
    required this.id,
    required this.propertyName,
    required this.unitId,
    required this.createdAt,
  });

  final String id;
  final String propertyName;
  final String unitId;
  final Timestamp? createdAt;

  Map<String, dynamic> toFirestore() {
    return {'unitId': unitId};
  }

  factory TenantModel.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc, {
    required String propertyName,
  }) {
    final data = doc.data();
    return TenantModel(
      id: doc.id,
      propertyName: propertyName,
      unitId: _asString(data['unitId']),
      createdAt: data['createdAt'] is Timestamp
          ? data['createdAt'] as Timestamp
          : null,
    );
  }

  static String _asString(dynamic value) {
    return value is String ? value : '';
  }
}
