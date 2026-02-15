import 'package:firebase_auth/firebase_auth.dart';

class SessionService {
  SessionService._();

  static final SessionService instance = SessionService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Future<void> signOut() {
    return _auth.signOut();
  }
}
