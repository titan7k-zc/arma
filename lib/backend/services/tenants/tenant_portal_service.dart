import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:arma2/backend/models/maintenance_request_status.dart';

class TenantLeaseInfo {
  const TenantLeaseInfo({
    required this.ownerId,
    required this.propertyId,
    required this.assignmentId,
    required this.propertyName,
    required this.address,
    required this.unitId,
    required this.rentAmount,
    required this.leaseProgress,
    required this.daysUntilCurrentDue,
    required this.nextDueAt,
    required this.createdAt,
  });

  final String ownerId;
  final String propertyId;
  final String assignmentId;
  final String propertyName;
  final String address;
  final String unitId;
  final double rentAmount;
  final double leaseProgress;
  final int daysUntilCurrentDue;
  final DateTime nextDueAt;
  final DateTime? createdAt;
}

class TenantPaymentRecord {
  const TenantPaymentRecord({
    required this.id,
    required this.amount,
    required this.method,
    required this.status,
    required this.paidAt,
    required this.dueAt,
  });

  final String id;
  final double amount;
  final String method;
  final String status;
  final DateTime? paidAt;
  final DateTime? dueAt;
}

class TenantMaintenanceRequestRecord {
  const TenantMaintenanceRequestRecord({
    required this.id,
    required this.message,
    required this.status,
    required this.ownerMessage,
    required this.ownerMessageUpdatedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String message;
  final String status;
  final String ownerMessage;
  final DateTime? ownerMessageUpdatedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}

class TenantPortalService {
  TenantPortalService._();

  static final TenantPortalService instance = TenantPortalService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  Stream<TenantLeaseInfo?> watchCurrentTenantLease() async* {
    final user = _auth.currentUser;
    if (user == null) {
      yield null;
      return;
    }

    final tenantUid = user.uid;

    try {
      await for (final snapshot in _firestore.collectionGroup('tenants').snapshots()) {
        final matchingDocs = snapshot.docs.where((doc) {
          final data = doc.data();
          return _asString(data['tenantUid']).trim() == tenantUid;
        }).toList();

        if (matchingDocs.isEmpty) {
          yield null;
          continue;
        }

        final resolved = await Future.wait(
          matchingDocs.map(_resolveLeaseFromAssignmentDoc),
        );

        final leases = resolved.whereType<TenantLeaseInfo>().toList();
        yield _pickLatestLease(leases);
      }
    } on FirebaseException catch (error) {
      if (error.code == 'failed-precondition') {
        yield* _watchCurrentTenantLeaseByScan(tenantUid);
        return;
      }
      rethrow;
    }
  }

  Stream<List<TenantPaymentRecord>> watchTenantPayments() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(const <TenantPaymentRecord>[]);
    }

    return watchCurrentTenantLease().asyncExpand((lease) {
      if (lease == null) {
        return Stream.value(const <TenantPaymentRecord>[]);
      }

      return _assignmentRef(lease).collection('payments').snapshots().map((snapshot) {
        final payments = snapshot.docs.map((doc) {
          final data = doc.data();
          return TenantPaymentRecord(
            id: doc.id,
            amount: _asDouble(data['amount']),
            method: _asString(data['method']).trim().isEmpty
                ? 'Unknown'
                : _asString(data['method']).trim(),
            status: _asString(data['status']).trim().isEmpty
                ? 'paid'
                : _asString(data['status']).trim(),
            paidAt: _asDateTime(data['paidAt']),
            dueAt: _asDateTime(data['dueAt']),
          );
        }).toList();

        payments.sort((a, b) {
          final aMillis = a.paidAt?.millisecondsSinceEpoch ?? 0;
          final bMillis = b.paidAt?.millisecondsSinceEpoch ?? 0;
          return bMillis.compareTo(aMillis);
        });

        return payments;
      });
    });
  }

  Stream<List<TenantMaintenanceRequestRecord>> watchTenantMaintenanceRequests() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(const <TenantMaintenanceRequestRecord>[]);
    }

    return watchCurrentTenantLease().asyncExpand((lease) {
      if (lease == null) {
        return Stream.value(const <TenantMaintenanceRequestRecord>[]);
      }

      return _assignmentRef(lease)
          .collection('maintenanceRequests')
          .snapshots()
          .map((snapshot) {
            final requests = snapshot.docs.map((doc) {
              final data = doc.data();
              final createdAt = _asDateTime(data['createdAt']);
              final updatedAt = _asDateTime(data['updatedAt']);
              return TenantMaintenanceRequestRecord(
                id: doc.id,
                message: _asString(data['message']).trim(),
                status: MaintenanceRequestStatus.normalize(_asString(data['status'])),
                ownerMessage: _asString(data['ownerMessage']).trim(),
                ownerMessageUpdatedAt: _asDateTime(data['ownerMessageUpdatedAt']),
                createdAt: createdAt,
                updatedAt: updatedAt ?? createdAt,
              );
            }).toList();

            requests.sort((a, b) {
              final aMillis = (a.updatedAt ?? a.createdAt)?.millisecondsSinceEpoch ?? 0;
              final bMillis = (b.updatedAt ?? b.createdAt)?.millisecondsSinceEpoch ?? 0;
              return bMillis.compareTo(aMillis);
            });

            return requests;
          });
    });
  }

  Future<void> payRent({
    required TenantLeaseInfo lease,
    String method = 'Card',
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'User not logged in.',
      );
    }

    final assignmentRef = _assignmentRef(lease);
    final paymentsRef = assignmentRef.collection('payments').doc();

    final now = DateTime.now();
    final nextDueAt = lease.nextDueAt;
    final dueCycleCount = _dueCycleCount(nextDueAt: nextDueAt, now: now);
    final amountToPay = lease.rentAmount;
    final monthlyRentAmount = dueCycleCount < 1
        ? lease.rentAmount
        : amountToPay / dueCycleCount;
    final coveredMonthKeys = _coveredMonthKeys(
      startDueAt: nextDueAt,
      cycleCount: dueCycleCount,
    );
    final coveredMonthLabels = _coveredMonthLabels(
      startDueAt: nextDueAt,
      cycleCount: dueCycleCount,
    );
    final nextDueAfterPayment = _addMonthsSameDay(
      date: nextDueAt,
      monthCount: dueCycleCount,
    );

    final paymentPayload = <String, dynamic>{
      'tenantUid': user.uid,
      'propertyId': lease.propertyId,
      'ownerId': lease.ownerId,
      'assignmentId': lease.assignmentId,
      'unitId': lease.unitId,
      'amount': amountToPay,
      'monthlyRentAmount': monthlyRentAmount,
      'coveredCycleCount': dueCycleCount,
      'coveredMonthKeys': coveredMonthKeys,
      'coveredMonthLabels': coveredMonthLabels,
      'method': method,
      'status': 'paid',
      'paidAt': FieldValue.serverTimestamp(),
      'dueAt': Timestamp.fromDate(nextDueAt),
      'propertyName': lease.propertyName,
      'tenantDisplayName': user.displayName?.trim() ?? '',
      'tenantEmail': user.email?.trim() ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    };

    final assignmentPayload = <String, dynamic>{
      'nextDueAt': Timestamp.fromDate(nextDueAfterPayment),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      await _firestore.runTransaction((transaction) async {
        transaction.set(paymentsRef, paymentPayload);
        transaction.set(assignmentRef, assignmentPayload, SetOptions(merge: true));
      });
    } on FirebaseException {
      final legacyPaymentPayload = <String, dynamic>{
        'tenantUid': user.uid,
        'propertyId': lease.propertyId,
        'ownerId': lease.ownerId,
        'assignmentId': lease.assignmentId,
        'unitId': lease.unitId,
        'amount': amountToPay,
        'method': method,
        'status': 'paid',
        'paidAt': FieldValue.serverTimestamp(),
        'dueAt': Timestamp.fromDate(nextDueAt),
        'propertyName': lease.propertyName,
        'tenantDisplayName': user.displayName?.trim() ?? '',
        'tenantEmail': user.email?.trim() ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore.runTransaction((transaction) async {
        transaction.set(paymentsRef, legacyPaymentPayload);
        transaction.set(assignmentRef, assignmentPayload, SetOptions(merge: true));
      });
    }
  }

  Future<void> submitMaintenanceRequest({
    required TenantLeaseInfo lease,
    required String message,
    bool isEmergency = false,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'User not logged in.',
      );
    }

    final cleanedMessage = message.trim();
    if (cleanedMessage.isEmpty) {
      throw ArgumentError('Please describe the maintenance issue.');
    }

    final requestsRef = _assignmentRef(lease).collection('maintenanceRequests');

    await requestsRef.add({
      'tenantUid': user.uid,
      'propertyId': lease.propertyId,
      'ownerId': lease.ownerId,
      'assignmentId': lease.assignmentId,
      'unitId': lease.unitId,
      'propertyName': lease.propertyName,
      'tenantDisplayName': user.displayName?.trim() ?? '',
      'tenantEmail': user.email?.trim() ?? '',
      'message': cleanedMessage,
      'status': MaintenanceRequestStatus.pending,
      'priority': isEmergency ? 'high' : 'normal',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<TenantLeaseInfo?> _watchCurrentTenantLeaseByScan(String tenantUid) async* {
    while (true) {
      yield await _fetchCurrentTenantLeaseByScan(tenantUid);
      await Future<void>.delayed(const Duration(seconds: 12));
    }
  }

  Future<TenantLeaseInfo?> _fetchCurrentTenantLeaseByScan(String tenantUid) async {
    final ownersSnapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'owner')
        .get();

    final leases = <TenantLeaseInfo>[];

    for (final ownerDoc in ownersSnapshot.docs) {
      final propertiesSnapshot = await ownerDoc.reference.collection('properties').get();

      for (final propertyDoc in propertiesSnapshot.docs) {
        final tenantSnapshot = await propertyDoc.reference
            .collection('tenants')
            .where('tenantUid', isEqualTo: tenantUid)
            .get();

        for (final assignmentDoc in tenantSnapshot.docs) {
          leases.add(
            _buildLeaseInfo(
              ownerId: ownerDoc.id,
              propertyId: propertyDoc.id,
              propertyData: propertyDoc.data(),
              assignmentId: assignmentDoc.id,
              assignmentData: assignmentDoc.data(),
            ),
          );
        }
      }
    }

    return _pickLatestLease(leases);
  }

  Future<TenantLeaseInfo?> _resolveLeaseFromAssignmentDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> assignmentDoc,
  ) async {
    final propertyRef = assignmentDoc.reference.parent.parent;
    if (propertyRef == null) {
      return null;
    }

    final ownerRef = propertyRef.parent.parent;
    if (ownerRef == null) {
      return null;
    }

    final propertySnapshot = await propertyRef.get();
    if (!propertySnapshot.exists) {
      return null;
    }

    final propertyData = propertySnapshot.data() ?? const <String, dynamic>{};

    return _buildLeaseInfo(
      ownerId: ownerRef.id,
      propertyId: propertyRef.id,
      propertyData: propertyData,
      assignmentId: assignmentDoc.id,
      assignmentData: assignmentDoc.data(),
    );
  }

  TenantLeaseInfo _buildLeaseInfo({
    required String ownerId,
    required String propertyId,
    required Map<String, dynamic> propertyData,
    required String assignmentId,
    required Map<String, dynamic> assignmentData,
  }) {
    final now = DateTime.now();

    final rentAmount = _asDouble(propertyData['rentAmount']);
    final propertyName = _asString(propertyData['propertyName']).trim().isEmpty
        ? 'Unknown property'
        : _asString(propertyData['propertyName']).trim();
    final address = _asString(propertyData['address']).trim();
    final unitId = _asString(assignmentData['unitId']).trim().isEmpty
        ? '-'
        : _asString(assignmentData['unitId']).trim();

    final createdAt = _asDateTime(assignmentData['createdAt']);
    final leaseStart = _asDateTime(assignmentData['leaseStartAt']) ?? createdAt;
    final leaseEnd = _asDateTime(assignmentData['leaseEndAt']) ??
        (leaseStart == null
            ? null
            : DateTime(leaseStart.year + 1, leaseStart.month, leaseStart.day));

    final leaseProgress = _calculateLeaseProgress(
      now: now,
      leaseStart: leaseStart,
      leaseEnd: leaseEnd,
    );

    final dueDay = _resolveDueDay(assignmentData, propertyData);
    final explicitNextDueAt = _asDateTime(assignmentData['nextDueAt']);
    final inferredNextDueAt = _dueDateOnOrAfter(
      reference: leaseStart ?? createdAt ?? now,
      dueDay: dueDay,
    );
    final nextDueAt = explicitNextDueAt ?? inferredNextDueAt;
    final dueCycleCount = _dueCycleCount(nextDueAt: nextDueAt, now: now);
    final dueRentAmount = rentAmount * dueCycleCount;

    final rawDaysUntilDue = _startOfDay(nextDueAt)
        .difference(_startOfDay(now))
        .inDays;
    final daysUntilCurrentDue = rawDaysUntilDue < 0 ? 0 : rawDaysUntilDue;

    return TenantLeaseInfo(
      ownerId: ownerId,
      propertyId: propertyId,
      assignmentId: assignmentId,
      propertyName: propertyName,
      address: address,
      unitId: unitId,
      rentAmount: dueRentAmount,
      leaseProgress: leaseProgress,
      daysUntilCurrentDue: daysUntilCurrentDue,
      nextDueAt: nextDueAt,
      createdAt: createdAt,
    );
  }

  TenantLeaseInfo? _pickLatestLease(List<TenantLeaseInfo> leases) {
    if (leases.isEmpty) {
      return null;
    }

    leases.sort((a, b) {
      final aMillis = a.createdAt?.millisecondsSinceEpoch ?? 0;
      final bMillis = b.createdAt?.millisecondsSinceEpoch ?? 0;
      return bMillis.compareTo(aMillis);
    });

    return leases.first;
  }

  DocumentReference<Map<String, dynamic>> _assignmentRef(TenantLeaseInfo lease) {
    return _firestore
        .collection('users')
        .doc(lease.ownerId)
        .collection('properties')
        .doc(lease.propertyId)
        .collection('tenants')
        .doc(lease.assignmentId);
  }

  static int _resolveDueDay(
    Map<String, dynamic> assignmentData,
    Map<String, dynamic> propertyData,
  ) {
    final assignmentDue = _asInt(assignmentData['dueDay']);
    if (assignmentDue >= 1 && assignmentDue <= 28) {
      return assignmentDue;
    }

    final propertyDue = _asInt(propertyData['dueDay']);
    if (propertyDue >= 1 && propertyDue <= 28) {
      return propertyDue;
    }

    return 1;
  }

  static double _calculateLeaseProgress({
    required DateTime now,
    required DateTime? leaseStart,
    required DateTime? leaseEnd,
  }) {
    if (leaseStart == null || leaseEnd == null || !leaseEnd.isAfter(leaseStart)) {
      return 0;
    }

    final total = leaseEnd.difference(leaseStart).inSeconds;
    if (total <= 0) {
      return 0;
    }

    final elapsed = now.difference(leaseStart).inSeconds;
    final ratio = elapsed / total;
    if (ratio < 0) {
      return 0;
    }
    if (ratio > 1) {
      return 1;
    }

    return ratio;
  }

  static DateTime _currentCycleDueDate({required DateTime now, required int dueDay}) {
    final clampedDay = dueDay.clamp(1, 28) as int;
    return DateTime(now.year, now.month, clampedDay);
  }

  static DateTime _dueDateOnOrAfter({required DateTime reference, required int dueDay}) {
    final cycleDue = _currentCycleDueDate(now: reference, dueDay: dueDay);
    if (!_startOfDay(cycleDue).isBefore(_startOfDay(reference))) {
      return cycleDue;
    }
    return _nextMonthSameDay(cycleDue);
  }

  static int _dueCycleCount({required DateTime nextDueAt, required DateTime now}) {
    final startDue = _startOfDay(nextDueAt);
    final today = _startOfDay(now);

    if (startDue.isAfter(today)) {
      return 1;
    }

    var count = 0;
    var cursor = startDue;
    while (!cursor.isAfter(today)) {
      count++;
      cursor = _nextMonthSameDay(cursor);
    }
    return count < 1 ? 1 : count;
  }

  static DateTime _addMonthsSameDay({
    required DateTime date,
    required int monthCount,
  }) {
    var result = _startOfDay(date);
    final safeMonthCount = monthCount < 0 ? 0 : monthCount;
    for (var index = 0; index < safeMonthCount; index++) {
      result = _nextMonthSameDay(result);
    }
    return result;
  }

  static List<String> _coveredMonthKeys({
    required DateTime startDueAt,
    required int cycleCount,
  }) {
    final keys = <String>[];
    var cursor = _startOfDay(startDueAt);
    final safeCycleCount = cycleCount < 1 ? 1 : cycleCount;

    for (var index = 0; index < safeCycleCount; index++) {
      final month = cursor.month.toString().padLeft(2, '0');
      keys.add('${cursor.year}-$month');
      cursor = _nextMonthSameDay(cursor);
    }

    return keys;
  }

  static List<String> _coveredMonthLabels({
    required DateTime startDueAt,
    required int cycleCount,
  }) {
    const monthNames = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final labels = <String>[];
    var cursor = _startOfDay(startDueAt);
    final safeCycleCount = cycleCount < 1 ? 1 : cycleCount;

    for (var index = 0; index < safeCycleCount; index++) {
      labels.add('${monthNames[cursor.month - 1]} ${cursor.year}');
      cursor = _nextMonthSameDay(cursor);
    }

    return labels;
  }

  static DateTime _nextMonthSameDay(DateTime date) {
    final year = date.month == 12 ? date.year + 1 : date.year;
    final month = date.month == 12 ? 1 : date.month + 1;
    final day = date.day.clamp(1, 28) as int;
    return DateTime(year, month, day);
  }

  static DateTime _startOfDay(DateTime value) {
    return DateTime(value.year, value.month, value.day);
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

  static DateTime? _asDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return null;
  }
}
