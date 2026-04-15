import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:facelog/student/student_main_page.dart';
import 'package:facelog/teacher/teacher_main_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'admin/admin_dashboard.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _obscurePassword = true;
  bool _isLoading = false;


  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = cred.user;
      if (user == null) { _showSnack("Login failed", isError: true); return; }

      final token = await FirebaseMessaging.instance.getToken();
      final userRef = FirebaseFirestore.instance.collection("users").doc(user.uid);

      await userRef.set({
        "email": user.email,
        "fcmToken": token,
        "lastLogin": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      DocumentSnapshot userDoc = await userRef.get();
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>? ?? {};

      if (!userData.containsKey("role")) {
        await userRef.set({"role": "student"}, SetOptions(merge: true));
        userDoc = await userRef.get();
        userData = userDoc.data() as Map<String, dynamic>? ?? {};
      }

      _showSnack("Welcome back!", isError: false);
      _navigateToRolePage(userData["role"]);
    } on FirebaseAuthException catch (e) {
      _showSnack(e.message ?? "Login failed", isError: true);
    } catch (e) {
      _showSnack("An error occurred: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  void _navigateToRolePage(String role) {
    if (role == "student") {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const StudentMainPage()));
    } else if (role == "teacher") {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TeacherMainPage()));
    } else if (role == "admin") {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboard()));
    } else {
      _showSnack("Invalid user role", isError: true);
    }
  }

  void _showSnack(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(isError ? Icons.error_outline_rounded : Icons.check_circle_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ]),
        backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Top Dark Banner ──────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(28, 48, 28, 40),
                decoration: const BoxDecoration(
                  color: Color(0xFF1A1F3C),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
                ),
                child: Column(
                  children: [
                    // Logo
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F6EF7),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF4F6EF7).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8)),
                        ],
                      ),
                      child: const Icon(Icons.face_retouching_natural, color: Colors.white, size: 38),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'FaceLog',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Facial Attendance System',
                      style: TextStyle(color: Color(0xFF8A9BB5), fontSize: 14),
                    ),
                  ],
                ),
              ),

              // ── Form ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1F3C)),
                      ),
                      const SizedBox(height: 4),
                      Text('Sign in to your account', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),

                      const SizedBox(height: 28),

                      // Email
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF8A9BB5)),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFF4F6EF7), width: 2),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFEF4444)),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Email is required';
                          if (!v.contains('@')) return 'Enter a valid email';
                          return null;
                        },
                      ),

                      const SizedBox(height: 14),

                      // Password
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF8A9BB5)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: const Color(0xFF8A9BB5),
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFF4F6EF7), width: 2),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFEF4444)),
                          ),
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? 'Password is required' : null,
                      ),

                      const SizedBox(height: 28),

                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F6EF7),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),

                      const SizedBox(height: 14),


                      
                      const SizedBox(height: 24),


                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
