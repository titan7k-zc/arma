import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:arma2/backend/services/auth/signup_service.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController nicController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  final SignUpService _signUpService = SignUpService.instance;

  bool hidePassword = true;
  bool hideConfirmPassword = true;
  bool isLoading = false;
  String message = '';
  String? selectedRole;

  Future<void> signUp() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final ageText = ageController.text.trim();
    final address = addressController.text.trim();
    final nicNumber = nicController.text.trim();
    final mobileNumber = mobileController.text.trim();
    final password = passwordController.text.trim();
    final confirm = confirmPasswordController.text.trim();
    final role = selectedRole;

    if (name.isEmpty ||
        email.isEmpty ||
        ageText.isEmpty ||
        address.isEmpty ||
        nicNumber.isEmpty ||
        mobileNumber.isEmpty ||
        password.isEmpty ||
        confirm.isEmpty ||
        role == null) {
      setState(() => message = 'Please fill all fields.');
      return;
    }

    final age = int.tryParse(ageText);
    if (age == null || age <= 0) {
      setState(() => message = 'Please enter a valid age.');
      return;
    }

    if (password != confirm) {
      setState(() => message = 'Passwords do not match.');
      return;
    }

    if (password.length < 6) {
      setState(() => message = 'Password must be at least 6 characters.');
      return;
    }

    setState(() {
      isLoading = true;
      message = '';
    });

    try {
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

      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
        message = 'Account created successfully.';
      });

      Navigator.pop(context);
    } on FirebaseAuthException catch (error) {
      setState(() {
        isLoading = false;
        if (error.code == 'email-already-in-use') {
          message = 'Email already in use.';
        } else if (error.code == 'invalid-email') {
          message = 'Invalid email.';
        } else if (error.code == 'weak-password') {
          message = 'Password is too weak.';
        } else {
          message = error.message ?? 'Signup failed.';
        }
      });
    } catch (_) {
      setState(() {
        isLoading = false;
        message = 'Something went wrong.';
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
                      const SizedBox(height: 40),
                      SizedBox(
                        height: 80,
                        child: Image.asset(
                          'assets/logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.timer,
                            size: 80,
                            color: Color(0xFFC77DFF),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Create Account',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Sign up to get started',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 40),
                      Row(
                        children: [
                          Expanded(
                            child: _buildRoleButton(
                              label: 'Owner',
                              value: 'owner',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildRoleButton(
                              label: 'Tenant',
                              value: 'tenant',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _inputField(
                        controller: nameController,
                        hint: 'Full Name',
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 16),
                      _inputField(
                        controller: ageController,
                        hint: 'Age',
                        icon: Icons.cake_outlined,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      _inputField(
                        controller: nicController,
                        hint: 'NIC Number',
                        icon: Icons.badge_outlined,
                      ),
                      const SizedBox(height: 16),
                      _inputField(
                        controller: addressController,
                        hint: 'Address',
                        icon: Icons.home_outlined,
                        keyboardType: TextInputType.streetAddress,
                      ),
                      const SizedBox(height: 16),
                      _inputField(
                        controller: mobileController,
                        hint: 'Mobile Number',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      _inputField(
                        controller: emailController,
                        hint: 'Email',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      _inputField(
                        controller: passwordController,
                        hint: 'Password',
                        icon: Icons.lock_outline,
                        isPassword: true,
                        hidePassword: hidePassword,
                        toggle: () {
                          setState(() => hidePassword = !hidePassword);
                        },
                      ),
                      const SizedBox(height: 16),
                      _inputField(
                        controller: confirmPasswordController,
                        hint: 'Confirm Password',
                        icon: Icons.lock_outline,
                        isPassword: true,
                        hidePassword: hideConfirmPassword,
                        toggle: () {
                          setState(() {
                            hideConfirmPassword = !hideConfirmPassword;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      Text(
                        message,
                        style: const TextStyle(
                          color: Colors.orangeAccent,
                          fontSize: 15,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : signUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF64B5F6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                )
                              : const Text(
                                  'Sign Up',
                                  style: TextStyle(fontSize: 18),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Already have an account? ',
                            style: TextStyle(color: Colors.white70),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Text(
                              'Login',
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

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool hidePassword = true,
    VoidCallback? toggle,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? hidePassword : false,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(0.15),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white70),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  hidePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white70,
                ),
                onPressed: toggle,
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildRoleButton({required String label, required String value}) {
    final isSelected = selectedRole == value;

    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            selectedRole = value;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected
              ? const Color(0xFF64B5F6)
              : Colors.white24,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: Text(label),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    ageController.dispose();
    addressController.dispose();
    nicController.dispose();
    mobileController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
