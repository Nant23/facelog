import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:facelog/signup_page.dart';
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
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // -----------------------------
  // Email/Password Login
  // -----------------------------
  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showSnack("Please fill all fields");
      return;
    }

    try {
      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = cred.user;

      if (user == null) {
        showSnack("Login failed");
        return;
      }

      // Get FCM token
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .update({"fcmToken": token});
      }

      // Get user role
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection("users").doc(user.uid).get();

      if (!userDoc.exists) {
        showSnack("User data not found");
        return;
      }

      String role = userDoc.get("role");

      showSnack("Login successful!");

      _navigateToRolePage(role);
    } on FirebaseAuthException catch (e) {
      showSnack(e.message ?? "Login failed");
    }
  }

  // -----------------------------
  // Google Sign-In
  // -----------------------------
  Future<void> signInWithGoogle() async {
  try {
    final provider = GoogleAuthProvider();

    // Sign in with Firebase directly
    UserCredential userCredential =
        await FirebaseAuth.instance.signInWithProvider(provider);

    User? user = userCredential.user;
    if (user == null) throw Exception("Google login failed");

    // Get FCM token
    String? token = await FirebaseMessaging.instance.getToken();

    // Firestore user document
    DocumentReference userRef =
        FirebaseFirestore.instance.collection("users").doc(user.uid);

    DocumentSnapshot userDoc = await userRef.get();

    if (!userDoc.exists) {
      await userRef.set({
        "email": user.email,
        "role": "student", // default role
        "fcmToken": token,
        "createdAt": FieldValue.serverTimestamp(),
      });
    } else {
      await userRef.update({"fcmToken": token});
    }

    userDoc = await userRef.get();
    String role = userDoc.get("role");

    print("Google login successful, role: $role");
  } catch (e) {
    print("Google login error: $e");
  }
}

  // -----------------------------
  // Navigate by Role
  // -----------------------------
  void _navigateToRolePage(String role) {
    if (role == "student") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const StudentMainPage()),
      );
    } else if (role == "teacher") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TeacherMainPage()),
      );
    } else if (role == "admin") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboard()),
      );
    } else {
      showSnack("Invalid user role");
    }
  }

  // -----------------------------
  // Show SnackBar
  // -----------------------------
  void showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 50),
              Text(
                "Welcome Back",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
              const SizedBox(height: 40),

              // Email input
              TextField(
                keyboardType: TextInputType.emailAddress,
                controller: emailController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'Email',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Password input
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // LOGIN BUTTON
              ElevatedButton(
                onPressed: login,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Login',
                  style: TextStyle(fontSize: 18),
                ),
              ),

              const SizedBox(height: 15),

              // GOOGLE LOGIN BUTTON
              ElevatedButton.icon(
                onPressed: signInWithGoogle,
                icon: const Icon(Icons.login),
                label: const Text("Sign in with Google"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // SIGNUP
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SignUpPage()),
                  );
                },
                child: const Text("Don't have an account? Sign up"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
