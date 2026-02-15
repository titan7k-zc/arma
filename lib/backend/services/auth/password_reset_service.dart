import 'package:firebase_auth/firebase_auth.dart';

class PasswordResetService {
  PasswordResetService._();

  static final PasswordResetService instance = PasswordResetService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> sendPasswordResetEmail({required String email}) {
    return _auth.sendPasswordResetEmail(email: email);
  }
}
