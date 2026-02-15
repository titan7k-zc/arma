import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignUpService {
  SignUpService._();

  static final SignUpService instance = SignUpService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> signUpWithProfile({
    required String name,
    required String email,
    required String password,
    required int age,
    required String address,
    required String nicNumber,
    required String mobileNumber,
    required String role,
  }) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = userCredential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'internal-error',
        message: 'User account was not created.',
      );
    }

    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'name': name,
      'email': email,
      'age': age,
      'address': address,
      'nicNumber': nicNumber,
      'mobileNumber': mobileNumber,
      'role': role.toLowerCase(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    await user.updateDisplayName(name);
  }
}
