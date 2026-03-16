import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:arma2/backend/services/auth/login_service.dart';
import 'package:arma2/backend/services/auth/session_service.dart';
import 'package:arma2/backend/services/auth/user_role_service.dart';
import 'package:arma2/backend/services/messaging_service.dart';
import 'package:arma2/frontend/pages/forgot_password_page.dart';
import 'package:arma2/frontend/pages/OwnerHomeRun.dart';
import 'package:arma2/frontend/pages/TenantHomeRun.dart';
import 'package:arma2/frontend/pages/signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final LoginService _loginService = LoginService.instance;
  final UserRoleService _userRoleService = UserRoleService.instance;
  final SessionService _sessionService = SessionService.instance;
  final MessagingService _messagingService = MessagingService.instance;

  bool _hidePassword = true;
  bool _isLoading = false;
  String _message = '';

  String _mapLoginError(Object error) {
    final raw = error.toString().toLowerCase();

    if (raw.contains('chain validation failed') ||
        raw.contains('network-request-failed') ||
        raw.contains('an internal error has occurred')) {
      return 'Secure connection failed. Turn ON automatic date/time and disable VPN or proxy, then try again.';
    }

    return 'Login failed. Please try again.';
  }

  @override
  void initState() {
    super.initState();
    _initializeMessaging();
  }

  Future<void> _initializeMessaging() async {
    try {
      await _messagingService.initialize();
    } catch (error) {
      debugPrint('Messaging initialization failed: $error');
    }
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _message = 'Please fill in all fields.');
      return;
    }

    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      await _loginService.signIn(email: email, password: password);
      final role = await _userRoleService.getCurrentUserRole();

      if (!mounted) {
        return;
      }

      setState(() => _isLoading = false);

      if (role == 'owner') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OwnerHomeRun()),
        );
        return;
      }

      if (role == 'tenant') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const TenantHomeRun()),
        );
        return;
      }

      await _sessionService.signOut();
      setState(() {
        _message = 'User role not found. Please contact support.';
      });
    } on FirebaseAuthException catch (error) {
      setState(() {
        _isLoading = false;
        if (error.code == 'user-not-found') {
          _message = 'User not found.';
        } else if (error.code == 'wrong-password') {
          _message = 'Wrong password.';
        } else if (error.code == 'invalid-email') {
          _message = 'Invalid email address.';
        } else if (error.code == 'invalid-credential') {
          _message = 'Invalid email or password.';
        } else if (error.code == 'too-many-requests') {
          _message = 'Too many attempts. Please wait and try again.';
        } else {
          _message = _mapLoginError(error);
        }
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
        _message = _mapLoginError(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: screenHeight,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: keyboardHeight),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: screenHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      Flexible(
                        child: Image.asset(
                          'assets/logo.png',
                          height: 80,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) {
                            return const Icon(
                              Icons.timer,
                              size: 80,
                              color: Color(0xFFC77DFF),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Welcome Back',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Log in to continue',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 40),
                      _buildInputField(
                        controller: _emailController,
                        hint: 'Email',
                        icon: Icons.email_outlined,
                      ),
                      const SizedBox(height: 16),
                      _buildInputField(
                        controller: _passwordController,
                        hint: 'Password',
                        icon: Icons.lock_outline,
                        isPassword: true,
                        hidePassword: _hidePassword,
                        onToggleVisibility: () {
                          setState(() => _hidePassword = !_hidePassword);
                        },
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ForgotPasswordPage(),
                              ),
                            );
                          },
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(color: Colors.lightBlueAccent),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF64B5F6),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  'Login',
                                  style: TextStyle(fontSize: 17),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _message,
                        style: const TextStyle(
                          color: Colors.orangeAccent,
                          fontSize: 15,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Don't have an account? ",
                            style: TextStyle(color: Colors.white70),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SignUpPage(),
                                ),
                              );
                            },
                            child: const Text(
                              'Sign Up',
                              style: TextStyle(
                                color: Colors.lightBlueAccent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool hidePassword = true,
    VoidCallback? onToggleVisibility,
  }) {
    return SizedBox(
      width: double.infinity,
      child: TextField(
        controller: controller,
        obscureText: isPassword && hidePassword,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white.withOpacity(0.13),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white54),
          prefixIcon: Icon(icon, color: Colors.white70),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    hidePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white70,
                  ),
                  onPressed: onToggleVisibility,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
