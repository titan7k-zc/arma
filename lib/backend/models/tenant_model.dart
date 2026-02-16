import 'package:cloud_firestore/cloud_firestore.dart';

class TenantModel {
  const TenantModel({
    required this.id,
    required this.tenantUid,
    required this.propertyId,
    required this.propertyName,
    required this.rentAmount,
    required this.unitId,
    required this.createdAt,
  });

  final String id;
  final String tenantUid;
  final String propertyId;
  final String propertyName;
  final double rentAmount;
  final String unitId;
  final Timestamp? createdAt;

  Map<String, dynamic> toFirestore() {
    return {'tenantUid': tenantUid, 'unitId': unitId};
  }

  factory TenantModel.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc, {
    required String propertyId,
    required String propertyName,
    required double rentAmount,
  }) {
    final data = doc.data();
    final tenantUid = _asString(data['tenantUid']).trim();
    return TenantModel(
      id: doc.id,
      tenantUid: tenantUid.isEmpty ? doc.id : tenantUid,
      propertyId: propertyId,
      propertyName: propertyName,
      rentAmount: rentAmount,
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
