import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:arma2/backend/models/maintenance_request_status.dart';

class OwnerMaintenanceNotificationRecord {
  const OwnerMaintenanceNotificationRecord({
    required this.id,
    required this.ownerId,
    required this.propertyId,
    required this.assignmentId,
    required this.tenantUid,
    required this.tenantLabel,
    required this.propertyName,
    required this.unitId,
    required this.message,
    required this.status,
    required this.ownerMessage,
    required this.ownerMessageUpdatedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String ownerId;
  final String propertyId;
  final String assignmentId;
  final String tenantUid;
  final String tenantLabel;
  final String propertyName;
  final String unitId;
  final String message;
  final String status;
  final String ownerMessage;
  final DateTime? ownerMessageUpdatedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}

class OwnerRentPaymentNotificationRecord {
  const OwnerRentPaymentNotificationRecord({
    required this.id,
    required this.ownerId,
    required this.propertyId,
    required this.assignmentId,
    required this.tenantUid,
    required this.tenantLabel,
    required this.propertyName,
    required this.unitId,
    required this.amount,
    required this.method,
    required this.status,
    required this.paidAt,
    required this.createdAt,
  });

  final String id;
  final String ownerId;
  final String propertyId;
  final String assignmentId;
  final String tenantUid;
  final String tenantLabel;
  final String propertyName;
  final String unitId;
  final double amount;
  final String method;
  final String status;
  final DateTime? paidAt;
  final DateTime? createdAt;
}

class OwnerMaintenanceService {
  OwnerMaintenanceService._();

  static final OwnerMaintenanceService instance = OwnerMaintenanceService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  Stream<List<OwnerMaintenanceNotificationRecord>>
  watchOwnerMaintenanceNotifications() async* {
    final owner = _auth.currentUser;
    if (owner == null) {
      yield const <OwnerMaintenanceNotificationRecord>[];
      return;
    }

    final ownerId = owner.uid;
    final query = _firestore
        .collectionGroup('maintenanceRequests')
        .where('ownerId', isEqualTo: ownerId);

    try {
      await for (final snapshot in query.snapshots()) {
        final records = snapshot.docs
            .map((doc) => _recordFromCollectionGroupDoc(doc))
            .whereType<OwnerMaintenanceNotificationRecord>()
            .toList();
        _sortRecordsNewestFirst(records);
        yield records;
      }
    } on FirebaseException catch (error) {
      if (error.code == 'failed-precondition') {
        yield* _watchOwnerMaintenanceNotificationsByScan(ownerId);
        return;
      }
      rethrow;
    }
  }

  Future<void> updateMaintenanceRequestStatus({
    required OwnerMaintenanceNotificationRecord request,
    required String status,
  }) async {
    final owner = _auth.currentUser;
    if (owner == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'User not logged in.',
      );
    }
    if (owner.uid != request.ownerId) {
      throw ArgumentError('You are not allowed to update this request.');
    }

    final normalizedStatus = MaintenanceRequestStatus.normalize(status);
    if (!MaintenanceRequestStatus.ownerSelectableStatuses.contains(
      normalizedStatus,
    )) {
      throw ArgumentError('Invalid maintenance request status.');
    }

    final requestRef = _firestore
        .collection('users')
        .doc(request.ownerId)
        .collection('properties')
        .doc(request.propertyId)
        .collection('tenants')
        .doc(request.assignmentId)
        .collection('maintenanceRequests')
        .doc(request.id);

    await requestRef.update({
      'status': normalizedStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateMaintenanceRequestMessage({
    required OwnerMaintenanceNotificationRecord request,
    required String ownerMessage,
  }) async {
    final owner = _auth.currentUser;
    if (owner == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'User not logged in.',
      );
    }
    if (owner.uid != request.ownerId) {
      throw ArgumentError('You are not allowed to update this request.');
    }

    final requestRef = _firestore
        .collection('users')
        .doc(request.ownerId)
        .collection('properties')
        .doc(request.propertyId)
        .collection('tenants')
        .doc(request.assignmentId)
        .collection('maintenanceRequests')
        .doc(request.id);

    await requestRef.update({
      'ownerMessage': ownerMessage.trim(),
      'ownerMessageUpdatedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<OwnerRentPaymentNotificationRecord>>
  watchOwnerPaymentNotifications() async* {
    final owner = _auth.currentUser;
    if (owner == null) {
      yield const <OwnerRentPaymentNotificationRecord>[];
      return;
    }

    final ownerId = owner.uid;
    final query = _firestore
        .collectionGroup('payments')
        .where('ownerId', isEqualTo: ownerId);

    try {
      await for (final snapshot in query.snapshots()) {
        final records = snapshot.docs
            .map((doc) => _paymentRecordFromCollectionGroupDoc(doc))
            .whereType<OwnerRentPaymentNotificationRecord>()
            .toList();
        _sortPaymentsNewestFirst(records);
        yield records;
      }
    } on FirebaseException catch (error) {
      if (error.code == 'failed-precondition') {
        yield* _watchOwnerPaymentNotificationsByScan(ownerId);
        return;
      }
      rethrow;
    }
  }

  Stream<List<OwnerMaintenanceNotificationRecord>>
  _watchOwnerMaintenanceNotificationsByScan(String ownerId) async* {
    while (true) {
      yield await _fetchOwnerMaintenanceNotificationsByScan(ownerId);
      await Future<void>.delayed(const Duration(seconds: 12));
    }
  }

  Future<List<OwnerMaintenanceNotificationRecord>>
  _fetchOwnerMaintenanceNotificationsByScan(String ownerId) async {
    final propertiesSnapshot = await _firestore
        .collection('users')
        .doc(ownerId)
        .collection('properties')
        .get();

    final records = <OwnerMaintenanceNotificationRecord>[];

    for (final propertyDoc in propertiesSnapshot.docs) {
      final propertyData = propertyDoc.data();
      final propertyName = _asString(propertyData['propertyName']).trim();

      final assignmentsSnapshot = await propertyDoc.reference
          .collection('tenants')
          .get();

      for (final assignmentDoc in assignmentsSnapshot.docs) {
        final assignmentData = assignmentDoc.data();
        final unitId = _asString(assignmentData['unitId']).trim();

        final requestsSnapshot = await assignmentDoc.reference
            .collection('maintenanceRequests')
            .get();

        for (final requestDoc in requestsSnapshot.docs) {
          final record = _recordFromMaintenanceRequestDoc(
            doc: requestDoc,
            ownerId: ownerId,
            propertyId: propertyDoc.id,
            assignmentId: assignmentDoc.id,
            fallbackPropertyName: propertyName,
            fallbackUnitId: unitId,
          );
          if (record != null) {
            records.add(record);
          }
        }
      }
    }

    _sortRecordsNewestFirst(records);
    return records;
  }

  Stream<List<OwnerRentPaymentNotificationRecord>>
  _watchOwnerPaymentNotificationsByScan(String ownerId) async* {
    while (true) {
      yield await _fetchOwnerPaymentNotificationsByScan(ownerId);
      await Future<void>.delayed(const Duration(seconds: 12));
    }
  }

  Future<List<OwnerRentPaymentNotificationRecord>>
  _fetchOwnerPaymentNotificationsByScan(String ownerId) async {
    final propertiesSnapshot = await _firestore
        .collection('users')
        .doc(ownerId)
        .collection('properties')
        .get();

    final records = <OwnerRentPaymentNotificationRecord>[];

    for (final propertyDoc in propertiesSnapshot.docs) {
      final propertyData = propertyDoc.data();
      final propertyName = _asString(propertyData['propertyName']).trim();

      final assignmentsSnapshot = await propertyDoc.reference
          .collection('tenants')
          .get();

      for (final assignmentDoc in assignmentsSnapshot.docs) {
        final assignmentData = assignmentDoc.data();
        final unitId = _asString(assignmentData['unitId']).trim();

        final paymentsSnapshot = await assignmentDoc.reference
            .collection('payments')
            .get();

        for (final paymentDoc in paymentsSnapshot.docs) {
          final record = _paymentRecordFromPaymentDoc(
            doc: paymentDoc,
            ownerId: ownerId,
            propertyId: propertyDoc.id,
            assignmentId: assignmentDoc.id,
            fallbackPropertyName: propertyName,
            fallbackUnitId: unitId,
          );
          if (record != null) {
            records.add(record);
          }
        }
      }
    }

    _sortPaymentsNewestFirst(records);
    return records;
  }

  OwnerMaintenanceNotificationRecord? _recordFromCollectionGroupDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final pathSegments = doc.reference.path.split('/');
    if (pathSegments.length < 8) {
      return null;
    }

    return _recordFromMaintenanceRequestDoc(
      doc: doc,
      ownerId: pathSegments[1],
      propertyId: pathSegments[3],
      assignmentId: pathSegments[5],
    );
  }

  OwnerMaintenanceNotificationRecord? _recordFromMaintenanceRequestDoc({
    required QueryDocumentSnapshot<Map<String, dynamic>> doc,
    required String ownerId,
    required String propertyId,
    required String assignmentId,
    String? fallbackPropertyName,
    String? fallbackUnitId,
  }) {
    final data = doc.data();

    final tenantUid = _asString(data['tenantUid']).trim();
    final tenantDisplayName = _asString(data['tenantDisplayName']).trim();
    final tenantName = _asString(data['tenantName']).trim();
    final tenantEmail = _asString(data['tenantEmail']).trim();

    final resolvedName = tenantDisplayName.isNotEmpty ? tenantDisplayName : tenantName;
    final tenantLabel = _resolveTenantLabel(
      name: resolvedName,
      email: tenantEmail,
      tenantUid: tenantUid,
    );

    final requestPropertyName = _asString(data['propertyName']).trim();
    final requestUnitId = _asString(data['unitId']).trim();

    final resolvedPropertyName = requestPropertyName.isNotEmpty
        ? requestPropertyName
        : (fallbackPropertyName == null || fallbackPropertyName.trim().isEmpty
              ? 'Property $propertyId'
              : fallbackPropertyName.trim());
    final resolvedUnitId = requestUnitId.isNotEmpty
        ? requestUnitId
        : (fallbackUnitId?.trim().isNotEmpty ?? false
              ? fallbackUnitId!.trim()
              : '-');

    return OwnerMaintenanceNotificationRecord(
      id: doc.id,
      ownerId: ownerId,
      propertyId: propertyId,
      assignmentId: assignmentId,
      tenantUid: tenantUid,
      tenantLabel: tenantLabel,
      propertyName: resolvedPropertyName,
      unitId: resolvedUnitId,
      message: _asString(data['message']).trim(),
      status: MaintenanceRequestStatus.normalize(_asString(data['status'])),
      createdAt: _asDateTime(data['createdAt']),
      updatedAt: _asDateTime(data['updatedAt']),
      ownerMessage: _asString(data['ownerMessage']).trim(),
      ownerMessageUpdatedAt: _asDateTime(data['ownerMessageUpdatedAt']),
    );
  }

  OwnerRentPaymentNotificationRecord? _paymentRecordFromCollectionGroupDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final pathSegments = doc.reference.path.split('/');
    if (pathSegments.length < 8) {
      return null;
    }

    return _paymentRecordFromPaymentDoc(
      doc: doc,
      ownerId: pathSegments[1],
      propertyId: pathSegments[3],
      assignmentId: pathSegments[5],
    );
  }

  OwnerRentPaymentNotificationRecord? _paymentRecordFromPaymentDoc({
    required QueryDocumentSnapshot<Map<String, dynamic>> doc,
    required String ownerId,
    required String propertyId,
    required String assignmentId,
    String? fallbackPropertyName,
    String? fallbackUnitId,
  }) {
    final data = doc.data();

    final tenantUid = _asString(data['tenantUid']).trim();
    final tenantDisplayName = _asString(data['tenantDisplayName']).trim();
    final tenantName = _asString(data['tenantName']).trim();
    final tenantEmail = _asString(data['tenantEmail']).trim();
    final resolvedName = tenantDisplayName.isNotEmpty ? tenantDisplayName : tenantName;

    final propertyName = _asString(data['propertyName']).trim().isNotEmpty
        ? _asString(data['propertyName']).trim()
        : (fallbackPropertyName == null || fallbackPropertyName.trim().isEmpty
              ? 'Property $propertyId'
              : fallbackPropertyName.trim());
    final unitId = _asString(data['unitId']).trim().isNotEmpty
        ? _asString(data['unitId']).trim()
        : (fallbackUnitId?.trim().isNotEmpty ?? false
              ? fallbackUnitId!.trim()
              : '-');

    return OwnerRentPaymentNotificationRecord(
      id: doc.id,
      ownerId: ownerId,
      propertyId: propertyId,
      assignmentId: assignmentId,
      tenantUid: tenantUid,
      tenantLabel: _resolveTenantLabel(
        name: resolvedName,
        email: tenantEmail,
        tenantUid: tenantUid,
      ),
      propertyName: propertyName,
      unitId: unitId,
      amount: _asDouble(data['amount']),
      method: _asString(data['method']).trim().isEmpty
          ? 'Unknown'
          : _asString(data['method']).trim(),
      status: _asString(data['status']).trim().isEmpty
          ? 'paid'
          : _asString(data['status']).trim(),
      paidAt: _asDateTime(data['paidAt']),
      createdAt: _asDateTime(data['createdAt']),
    );
  }

  static void _sortRecordsNewestFirst(
    List<OwnerMaintenanceNotificationRecord> records,
  ) {
    records.sort((a, b) {
      final aMillis =
          (a.updatedAt ?? a.createdAt)?.millisecondsSinceEpoch ?? 0;
      final bMillis =
          (b.updatedAt ?? b.createdAt)?.millisecondsSinceEpoch ?? 0;
      return bMillis.compareTo(aMillis);
    });
  }

  static void _sortPaymentsNewestFirst(
    List<OwnerRentPaymentNotificationRecord> records,
  ) {
    records.sort((a, b) {
      final aMillis = (a.paidAt ?? a.createdAt)?.millisecondsSinceEpoch ?? 0;
      final bMillis = (b.paidAt ?? b.createdAt)?.millisecondsSinceEpoch ?? 0;
      return bMillis.compareTo(aMillis);
    });
  }

  static String _resolveTenantLabel({
    required String name,
    required String email,
    required String tenantUid,
  }) {
    final cleanedName = name.trim();
    if (cleanedName.isNotEmpty) {
      return cleanedName;
    }

    final cleanedEmail = email.trim();
    if (cleanedEmail.isNotEmpty) {
      return cleanedEmail;
    }

    if (tenantUid.length >= 6) {
      return 'Tenant ${tenantUid.substring(0, 6)}';
    }
    return 'Tenant';
  }

  static String _asString(dynamic value) {
    return value is String ? value : '';
  }

  static DateTime? _asDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return null;
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
