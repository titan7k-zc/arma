import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:arma2/backend/models/property_model.dart';

class PropertyService {
  PropertyService._();

  static final PropertyService instance = PropertyService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> _propertiesRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('properties');
  }

  Stream<List<PropertyModel>> watchCurrentUserProperties() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(const <PropertyModel>[]);
    }

    return _propertiesRef(user.uid).snapshots().map((snapshot) {
      final properties = snapshot.docs.map(PropertyModel.fromFirestore).toList();

      // Keep latest properties at the top even when older docs do not have createdAt.
      properties.sort((a, b) {
        final aMillis = a.createdAt?.millisecondsSinceEpoch ?? 0;
        final bMillis = b.createdAt?.millisecondsSinceEpoch ?? 0;
        return bMillis.compareTo(aMillis);
      });

      return properties;
    });
  }

  Future<void> refreshCurrentUserProperties() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'User not logged in.',
      );
    }

    // Force a server read so the local cache and active stream get latest data.
    await _propertiesRef(user.uid).get(const GetOptions(source: Source.server));
  }

  Future<void> addProperty({
    required String propertyName,
    required String address,
    required double rentAmount,
    required int units,
    required int occupied,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'User not logged in.',
      );
    }

    final cleanedName = propertyName.trim();
    final cleanedAddress = address.trim();

    if (cleanedName.isEmpty) {
      throw ArgumentError('Property name is required.');
    }
    if (cleanedAddress.isEmpty) {
      throw ArgumentError('Address is required.');
    }
    if (rentAmount < 0) {
      throw ArgumentError('Rent amount cannot be negative.');
    }
    if (units <= 0) {
      throw ArgumentError('Total units must be greater than 0.');
    }
    if (occupied < 0) {
      throw ArgumentError('Occupied units cannot be negative.');
    }
    if (occupied > units) {
      throw ArgumentError('Occupied units cannot be greater than total units.');
    }

    await _propertiesRef(user.uid).add({
      ...PropertyModel(
        id: '',
        ownerId: user.uid,
        propertyName: cleanedName,
        address: cleanedAddress,
        rentAmount: rentAmount,
        units: units,
        occupied: occupied,
        createdAt: null,
      ).toFirestore(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateProperty({
    required String propertyId,
    required String propertyName,
    required String address,
    required double rentAmount,
    required int units,
    required int occupied,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'User not logged in.',
      );
    }

    final cleanedName = propertyName.trim();
    final cleanedAddress = address.trim();

    if (cleanedName.isEmpty) {
      throw ArgumentError('Property name is required.');
    }
    if (cleanedAddress.isEmpty) {
      throw ArgumentError('Address is required.');
    }
    if (rentAmount < 0) {
      throw ArgumentError('Rent amount cannot be negative.');
    }
    if (units <= 0) {
      throw ArgumentError('Total units must be greater than 0.');
    }
    if (occupied < 0) {
      throw ArgumentError('Occupied units cannot be negative.');
    }
    if (occupied > units) {
      throw ArgumentError('Occupied units cannot be greater than total units.');
    }

    await _propertiesRef(user.uid).doc(propertyId).update({
      'propertyName': cleanedName,
      'address': cleanedAddress,
      'rentAmount': rentAmount,
      'units': units,
      'occupied': occupied,
    });
  }

  Future<void> deleteProperty({required String propertyId}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'User not logged in.',
      );
    }

    final cleanedPropertyId = propertyId.trim();
    if (cleanedPropertyId.isEmpty) {
      throw ArgumentError('Property id is required.');
    }

    await _propertiesRef(user.uid).doc(cleanedPropertyId).delete();
  }
}
