// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../login_page.dart';

class StudentProfilePage extends StatefulWidget {
  const StudentProfilePage({super.key});

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String studentName = "";
  String studentEmail = "";
  String studentClass = "";

  String? documentId; // <-- store actual firestore doc id
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        setState(() => isLoading = false);
        return;
      }

      print("Logged in UID: ${user.uid}");

      // 🔥 Query by uid field instead of document ID
      final query = await _firestore
          .collection('students')
          .where('uid', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        final data = doc.data();

        documentId = doc.id; // Save actual document ID

        if (!mounted) return;

        setState(() {
          studentName = data['name'] ?? "";
          studentEmail = data['email'] ?? user.email ?? "";
          studentClass =
              "${data['department'] ?? ""} - ${data['group'] ?? ""}";
          isLoading = false;
        });
      } else {
        if (!mounted) return;

        setState(() => isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Student data not found.")),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading data: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // PROFILE IMAGE
            const CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, size: 60, color: Colors.white),
            ),

            const SizedBox(height: 30),

            // NAME
            ListTile(
              leading: const Icon(Icons.person, color: Colors.blue),
              title: const Text("Name"),
              subtitle: Text(studentName),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  _editField("Name", studentName, (val) async {
                    if (documentId != null) {
                      await _firestore
                          .collection('students')
                          .doc(documentId)
                          .update({'name': val});
                    }

                    setState(() => studentName = val);
                  });
                },
              ),
            ),
            const Divider(),

            // EMAIL
            ListTile(
              leading: const Icon(Icons.email, color: Colors.blue),
              title: const Text("Email"),
              subtitle: Text(studentEmail),
            ),
            const Divider(),

            // CLASS
            ListTile(
              leading: const Icon(Icons.school, color: Colors.blue),
              title: const Text("Class"),
              subtitle: Text(studentClass),
            ),
            const Divider(),

            const SizedBox(height: 40),

            // LOGOUT
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  await _auth.signOut();

                  if (!mounted) return;

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginPage()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Logout",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editField(String field, String currentValue,
      Function(String) onSave) {
    final controller = TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit $field"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: "Enter $field"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) {
                onSave(value);
              }
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}
