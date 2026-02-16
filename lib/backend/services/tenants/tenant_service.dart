import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:arma2/backend/models/tenant_model.dart';

class TenantService {
  TenantService._();

  static final TenantService instance = TenantService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> _propertiesRef(String ownerId) {
    return _firestore.collection('users').doc(ownerId).collection('properties');
  }

  Stream<List<TenantModel>> watchCurrentUserTenants() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(const <TenantModel>[]);
    }
    final ownerId = user.uid;

    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? propertiesSub;
    final tenantSubs =
        <String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>{};
    final tenantsByProperty = <String, List<TenantModel>>{};

    void cancelTenantSubscriptions() {
      final subs = tenantSubs.values.toList();
      tenantSubs.clear();
      for (final sub in subs) {
        sub.cancel();
      }
    }

    List<TenantModel> flattenAndSortTenants() {
      final tenants = tenantsByProperty.values
          .expand((propertyTenants) => propertyTenants)
          .toList();
      tenants.sort((a, b) {
        final aMillis = a.createdAt?.millisecondsSinceEpoch ?? 0;
        final bMillis = b.createdAt?.millisecondsSinceEpoch ?? 0;
        return bMillis.compareTo(aMillis);
      });
      return tenants;
    }

    late final StreamController<List<TenantModel>> controller;
    controller = StreamController<List<TenantModel>>(
      onListen: () {
        propertiesSub = _propertiesRef(ownerId).snapshots().listen(
          (propertiesSnapshot) {
            cancelTenantSubscriptions();
            tenantsByProperty.clear();

            if (propertiesSnapshot.docs.isEmpty) {
              controller.add(const <TenantModel>[]);
              return;
            }

            for (final propertyDoc in propertiesSnapshot.docs) {
              final propertyId = propertyDoc.id;
              final propertyData = propertyDoc.data();
              final propertyNameValue = propertyData['propertyName'];
              final propertyRentValue = propertyData['rentAmount'];
              final propertyName =
                  propertyNameValue is String && propertyNameValue.trim().isNotEmpty
                  ? propertyNameValue.trim()
                  : 'Unknown property';
              final propertyRentAmount = _asDouble(propertyRentValue);

              tenantSubs[propertyId] = propertyDoc.reference
                  .collection('tenants')
                  .snapshots()
                  .listen(
                    (tenantsSnapshot) {
                      tenantsByProperty[propertyId] = tenantsSnapshot.docs
                          .map(
                            (doc) => TenantModel.fromFirestore(
                              doc,
                              propertyId: propertyId,
                              propertyName: propertyName,
                              rentAmount: propertyRentAmount,
                            ),
                          )
                          .toList();
                      controller.add(flattenAndSortTenants());
                    },
                    onError: controller.addError,
                  );
            }
          },
          onError: controller.addError,
        );
      },
      onCancel: () async {
        await propertiesSub?.cancel();
        cancelTenantSubscriptions();
      },
    );

    return controller.stream;
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

  static String _normalizeUnitId(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  static String _unitDocId(String normalizedUnitId) {
    return Uri.encodeComponent(normalizedUnitId);
  }

  static String _normalizedUnitFromData(Map<String, dynamic> data) {
    final normalizedValue = data['unitIdNormalized'];
    if (normalizedValue is String && normalizedValue.trim().isNotEmpty) {
      return _normalizeUnitId(normalizedValue);
    }

    final unitValue = data['unitId'];
    if (unitValue is String) {
      return _normalizeUnitId(unitValue);
    }

    return '';
  }

  Future<bool> _isUnitOccupied({
    required DocumentReference<Map<String, dynamic>> propertyRef,
    required String normalizedUnitId,
    String? excludePath,
  }) async {
    final tenantsSnapshot = await propertyRef.collection('tenants').get();
    for (final tenantDoc in tenantsSnapshot.docs) {
      if (excludePath != null && tenantDoc.reference.path == excludePath) {
        continue;
      }

      final normalized = _normalizedUnitFromData(tenantDoc.data());
      if (normalized == normalizedUnitId) {
        return true;
      }
    }

    return false;
  }

  Future<DocumentReference<Map<String, dynamic>>> _resolveTenantAssignmentRef({
    required DocumentReference<Map<String, dynamic>> propertyRef,
    required String tenantUid,
    required String unitId,
    String? assignmentDocId,
  }) async {
    final cleanedAssignmentDocId = assignmentDocId?.trim() ?? '';
    if (cleanedAssignmentDocId.isNotEmpty) {
      final explicitRef = propertyRef.collection('tenants').doc(
        cleanedAssignmentDocId,
      );
      final explicitSnapshot = await explicitRef.get();
      if (explicitSnapshot.exists) {
        return explicitRef;
      }
    }

    final normalizedUnitId = _normalizeUnitId(unitId);
    if (normalizedUnitId.isNotEmpty) {
      final byUnitRef = propertyRef.collection('tenants').doc(
        _unitDocId(normalizedUnitId),
      );
      final byUnitSnapshot = await byUnitRef.get();
      if (byUnitSnapshot.exists) {
        return byUnitRef;
      }
    }

    final byTenantSnapshot = await propertyRef
        .collection('tenants')
        .where('tenantUid', isEqualTo: tenantUid)
        .get();
    for (final tenantDoc in byTenantSnapshot.docs) {
      if (normalizedUnitId.isEmpty ||
          _normalizedUnitFromData(tenantDoc.data()) == normalizedUnitId) {
        return tenantDoc.reference;
      }
    }

    final legacyTenantRef = propertyRef.collection('tenants').doc(tenantUid);
    final legacyTenantSnapshot = await legacyTenantRef.get();
    if (legacyTenantSnapshot.exists) {
      return legacyTenantRef;
    }

    throw ArgumentError('Tenant assignment was not found in this property.');
  }

  Future<void> refreshCurrentUserTenants() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'User not logged in.',
      );
    }

    final propertiesSnapshot = await _propertiesRef(
      user.uid,
    ).get(const GetOptions(source: Source.server));

    await Future.wait(
      propertiesSnapshot.docs.map(
        (propertyDoc) => propertyDoc.reference.collection(
          'tenants',
        ).get(const GetOptions(source: Source.server)),
      ),
    );
  }

  Future<void> cleanupLegacyTenantUserCopies() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'User not logged in.',
      );
    }

    final propertiesSnapshot = await _propertiesRef(user.uid).get();
    if (propertiesSnapshot.docs.isEmpty) {
      return;
    }

    const legacyFields = <String>[
      'tenantName',
      'tenantEmail',
      'ownerId',
      'propertyId',
      'propertyName',
    ];

    var batch = _firestore.batch();
    var operationsInBatch = 0;

    Future<void> commitBatchIfNeeded({bool force = false}) async {
      if (operationsInBatch == 0) {
        return;
      }
      if (!force && operationsInBatch < 450) {
        return;
      }
      await batch.commit();
      batch = _firestore.batch();
      operationsInBatch = 0;
    }

    for (final propertyDoc in propertiesSnapshot.docs) {
      final tenantsSnapshot = await propertyDoc.reference
          .collection('tenants')
          .get();

      for (final tenantDoc in tenantsSnapshot.docs) {
        final data = tenantDoc.data();
        final payload = <String, dynamic>{};

        for (final field in legacyFields) {
          if (data.containsKey(field)) {
            payload[field] = FieldValue.delete();
          }
        }

        if (payload.isNotEmpty) {
          batch.update(tenantDoc.reference, payload);
          operationsInBatch++;
          await commitBatchIfNeeded();
        }
      }
    }

    await commitBatchIfNeeded(force: true);
  }

  Future<void> addTenantToProperty({
    required String propertyId,
    required String unitId,
    required String tenantEmail,
  }) async {
    final owner = _auth.currentUser;
    if (owner == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'User not logged in.',
      );
    }

    final cleanedPropertyId = propertyId.trim();
    final cleanedUnitId = unitId.trim();
    final cleanedTenantEmail = tenantEmail.trim();
    final normalizedUnitId = _normalizeUnitId(cleanedUnitId);

    if (cleanedPropertyId.isEmpty) {
      throw ArgumentError('Property is required.');
    }
    if (normalizedUnitId.isEmpty) {
      throw ArgumentError('Unit ID is required.');
    }
    if (cleanedTenantEmail.isEmpty) {
      throw ArgumentError('Tenant email is required.');
    }

    final propertyRef = _propertiesRef(owner.uid).doc(cleanedPropertyId);
    final propertySnapshot = await propertyRef.get();
    if (!propertySnapshot.exists) {
      throw ArgumentError('Selected property was not found.');
    }

    final isOccupied = await _isUnitOccupied(
      propertyRef: propertyRef,
      normalizedUnitId: normalizedUnitId,
    );
    if (isOccupied) {
      throw ArgumentError('This unit already has a tenant.');
    }

    var userQuery = await _firestore
        .collection('users')
        .where('email', isEqualTo: cleanedTenantEmail)
        .limit(1)
        .get();

    if (userQuery.docs.isEmpty &&
        cleanedTenantEmail != cleanedTenantEmail.toLowerCase()) {
      userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: cleanedTenantEmail.toLowerCase())
          .limit(1)
          .get();
    }

    if (userQuery.docs.isEmpty) {
      throw ArgumentError('No user found for this email.');
    }

    final tenantDoc = userQuery.docs.first;
    final tenantUid = tenantDoc.id;
    final tenantData = tenantDoc.data();

    final role = tenantData['role'];
    if (role is String && role.toLowerCase() != 'tenant') {
      throw ArgumentError('This email belongs to a non-tenant account.');
    }

    final unitRef = propertyRef
        .collection('tenants')
        .doc(_unitDocId(normalizedUnitId));

    await _firestore.runTransaction((transaction) async {
      final txPropertySnapshot = await transaction.get(propertyRef);
      if (!txPropertySnapshot.exists) {
        throw ArgumentError('Selected property was not found.');
      }

      final txPropertyData = txPropertySnapshot.data() ?? const <String, dynamic>{};
      final occupied = _asInt(txPropertyData['occupied']);
      final totalUnits = _asInt(txPropertyData['units']);

      if (totalUnits <= 0) {
        throw StateError('Property unit count is invalid.');
      }
      if (occupied >= totalUnits) {
        throw ArgumentError('This property has no available units.');
      }

      final txUnitSnapshot = await transaction.get(unitRef);
      if (txUnitSnapshot.exists) {
        throw ArgumentError('This unit already has a tenant.');
      }

      transaction.set(unitRef, {
        'tenantUid': tenantUid,
        'unitId': cleanedUnitId,
        'unitIdNormalized': normalizedUnitId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      transaction.update(propertyRef, {'occupied': occupied + 1});
    });
  }

  Future<void> moveTenantAssignment({
    required String tenantUid,
    required String currentPropertyId,
    required String currentUnitId,
    required String targetPropertyId,
    required String targetUnitId,
    String? currentAssignmentDocId,
  }) async {
    final owner = _auth.currentUser;
    if (owner == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'User not logged in.',
      );
    }

    final cleanedTenantUid = tenantUid.trim();
    final cleanedCurrentPropertyId = currentPropertyId.trim();
    final cleanedCurrentUnitId = currentUnitId.trim();
    final cleanedTargetPropertyId = targetPropertyId.trim();
    final cleanedTargetUnitId = targetUnitId.trim();
    final normalizedCurrentUnitId = _normalizeUnitId(cleanedCurrentUnitId);
    final normalizedTargetUnitId = _normalizeUnitId(cleanedTargetUnitId);

    if (cleanedTenantUid.isEmpty) {
      throw ArgumentError('Tenant id is required.');
    }
    if (cleanedCurrentPropertyId.isEmpty) {
      throw ArgumentError('Current property is required.');
    }
    if (normalizedCurrentUnitId.isEmpty) {
      throw ArgumentError('Current unit is required.');
    }
    if (cleanedTargetPropertyId.isEmpty) {
      throw ArgumentError('Target property is required.');
    }
    if (normalizedTargetUnitId.isEmpty) {
      throw ArgumentError('Target unit is required.');
    }

    final currentPropertyRef = _propertiesRef(owner.uid).doc(
      cleanedCurrentPropertyId,
    );
    final targetPropertyRef = _propertiesRef(owner.uid).doc(
      cleanedTargetPropertyId,
    );

    final currentPropertySnapshot = await currentPropertyRef.get();
    if (!currentPropertySnapshot.exists) {
      throw ArgumentError('Current property was not found.');
    }

    if (cleanedCurrentPropertyId != cleanedTargetPropertyId) {
      final targetPropertySnapshot = await targetPropertyRef.get();
      if (!targetPropertySnapshot.exists) {
        throw ArgumentError('Selected target property was not found.');
      }
    }

    if (cleanedCurrentPropertyId == cleanedTargetPropertyId &&
        normalizedCurrentUnitId == normalizedTargetUnitId) {
      return;
    }

    final currentAssignmentRef = await _resolveTenantAssignmentRef(
      propertyRef: currentPropertyRef,
      tenantUid: cleanedTenantUid,
      unitId: cleanedCurrentUnitId,
      assignmentDocId: currentAssignmentDocId,
    );

    final targetUnitRef = targetPropertyRef
        .collection('tenants')
        .doc(_unitDocId(normalizedTargetUnitId));
    final isTargetOccupied = await _isUnitOccupied(
      propertyRef: targetPropertyRef,
      normalizedUnitId: normalizedTargetUnitId,
      excludePath: cleanedCurrentPropertyId == cleanedTargetPropertyId
          ? currentAssignmentRef.path
          : null,
    );
    if (isTargetOccupied) {
      throw ArgumentError('This unit already has a tenant.');
    }

    await _firestore.runTransaction((transaction) async {
      final txCurrentPropertySnapshot = await transaction.get(currentPropertyRef);
      if (!txCurrentPropertySnapshot.exists) {
        throw ArgumentError('Current property was not found.');
      }

      final txTargetPropertySnapshot = cleanedCurrentPropertyId ==
              cleanedTargetPropertyId
          ? txCurrentPropertySnapshot
          : await transaction.get(targetPropertyRef);
      if (!txTargetPropertySnapshot.exists) {
        throw ArgumentError('Selected target property was not found.');
      }

      final txCurrentAssignmentSnapshot = await transaction.get(
        currentAssignmentRef,
      );
      if (!txCurrentAssignmentSnapshot.exists) {
        throw ArgumentError('Tenant assignment was not found in this property.');
      }

      final txTargetUnitSnapshot = await transaction.get(targetUnitRef);
      final isSameDocument =
          txCurrentAssignmentSnapshot.reference.path == targetUnitRef.path;
      if (txTargetUnitSnapshot.exists && !isSameDocument) {
        throw ArgumentError('This unit already has a tenant.');
      }

      final currentData =
          txCurrentAssignmentSnapshot.data() ?? const <String, dynamic>{};
      final createdAt = currentData['createdAt'];

      transaction.set(targetUnitRef, {
        'tenantUid': cleanedTenantUid,
        'unitId': cleanedTargetUnitId,
        'unitIdNormalized': normalizedTargetUnitId,
        'createdAt': createdAt is Timestamp
            ? createdAt
            : FieldValue.serverTimestamp(),
      });

      if (!isSameDocument) {
        transaction.delete(currentAssignmentRef);
      }

      if (cleanedCurrentPropertyId != cleanedTargetPropertyId) {
        final currentPropertyData =
            txCurrentPropertySnapshot.data() ?? const <String, dynamic>{};
        final targetPropertyData =
            txTargetPropertySnapshot.data() ?? const <String, dynamic>{};

        final currentOccupied = _asInt(currentPropertyData['occupied']);
        final targetOccupied = _asInt(targetPropertyData['occupied']);
        final targetUnits = _asInt(targetPropertyData['units']);

        if (targetUnits <= 0) {
          throw StateError('Property unit count is invalid.');
        }
        if (targetOccupied >= targetUnits) {
          throw ArgumentError('Selected property has no available units.');
        }

        transaction.update(currentPropertyRef, {
          'occupied': currentOccupied > 0 ? currentOccupied - 1 : 0,
        });
        transaction.update(targetPropertyRef, {'occupied': targetOccupied + 1});
      }
    });
  }

  Future<void> removeTenantFromProperty({
    required String tenantUid,
    required String propertyId,
    required String unitId,
    String? assignmentDocId,
  }) async {
    final owner = _auth.currentUser;
    if (owner == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'User not logged in.',
      );
    }

    final cleanedTenantUid = tenantUid.trim();
    final cleanedPropertyId = propertyId.trim();
    final cleanedUnitId = unitId.trim();

    if (cleanedTenantUid.isEmpty) {
      throw ArgumentError('Tenant id is required.');
    }
    if (cleanedPropertyId.isEmpty) {
      throw ArgumentError('Property is required.');
    }
    if (_normalizeUnitId(cleanedUnitId).isEmpty) {
      throw ArgumentError('Unit is required.');
    }

    final propertyRef = _propertiesRef(owner.uid).doc(cleanedPropertyId);
    final propertySnapshot = await propertyRef.get();
    if (!propertySnapshot.exists) {
      throw ArgumentError('Selected property was not found.');
    }

    final assignmentRef = await _resolveTenantAssignmentRef(
      propertyRef: propertyRef,
      tenantUid: cleanedTenantUid,
      unitId: cleanedUnitId,
      assignmentDocId: assignmentDocId,
    );

    await _firestore.runTransaction((transaction) async {
      final txPropertySnapshot = await transaction.get(propertyRef);
      if (!txPropertySnapshot.exists) {
        throw ArgumentError('Selected property was not found.');
      }

      final txAssignmentSnapshot = await transaction.get(assignmentRef);
      if (!txAssignmentSnapshot.exists) {
        throw ArgumentError('Tenant assignment was already removed.');
      }

      final propertyData = txPropertySnapshot.data() ?? const <String, dynamic>{};
      final occupied = _asInt(propertyData['occupied']);

      transaction.delete(assignmentRef);
      transaction.update(propertyRef, {'occupied': occupied > 0 ? occupied - 1 : 0});
    });
  }
}
