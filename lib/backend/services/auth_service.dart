import 'package:arma2/backend/services/auth/login_service.dart';
import 'package:arma2/backend/services/auth/password_reset_service.dart';
import 'package:arma2/backend/services/auth/session_service.dart';
import 'package:arma2/backend/services/auth/signup_service.dart';
import 'package:arma2/backend/services/auth/user_role_service.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final LoginService _loginService = LoginService.instance;
  final SignUpService _signUpService = SignUpService.instance;
  final UserRoleService _userRoleService = UserRoleService.instance;
  final PasswordResetService _passwordResetService =
      PasswordResetService.instance;
  final SessionService _sessionService = SessionService.instance;

  Future<void> signIn({required String email, required String password}) async {
    await _loginService.signIn(email: email, password: password);
  }

  Future<String?> getCurrentUserRole() async {
    return _userRoleService.getCurrentUserRole();
  }

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
    await _signUpService.signUpWithProfile(
      name: name,
      email: email,
      password: password,
      age: age,
      address: address,
      nicNumber: nicNumber,
      mobileNumber: mobileNumber,
      role: role,
    );
  }

  Future<void> sendPasswordResetEmail({required String email}) {
    return _passwordResetService.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() {
    return _sessionService.signOut();
  }
}
