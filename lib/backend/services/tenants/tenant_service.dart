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
              final propertyName =
                  propertyNameValue is String && propertyNameValue.trim().isNotEmpty
                  ? propertyNameValue.trim()
                  : 'Unknown property';

              tenantSubs[propertyId] = propertyDoc.reference
                  .collection('tenants')
                  .snapshots()
                  .listen(
                    (tenantsSnapshot) {
                      tenantsByProperty[propertyId] = tenantsSnapshot.docs
                          .map(
                            (doc) => TenantModel.fromFirestore(
                              doc,
                              propertyName: propertyName,
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
      'tenantUid',
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

    if (cleanedPropertyId.isEmpty) {
      throw ArgumentError('Property is required.');
    }
    if (cleanedUnitId.isEmpty) {
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

    final tenantRef = propertyRef.collection('tenants').doc(tenantUid);
    final existingTenant = await tenantRef.get();
    if (existingTenant.exists) {
      throw ArgumentError('Tenant already exists in this property.');
    }

    await tenantRef.set({
      'unitId': cleanedUnitId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
