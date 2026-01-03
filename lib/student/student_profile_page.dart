import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../login_page.dart'; // <-- Import your login page here

class StudentProfilePage extends StatefulWidget {
  const StudentProfilePage({super.key});

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  String studentName = "John Doe";
  String studentEmail = "john.doe@example.com";
  String studentClass = "Mathematics 101";

  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // --------- PROFILE IMAGE ---------
            Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey.shade300,
                  child: const Icon(Icons.person, size: 60, color: Colors.white),
                ),
                Positioned(
                  bottom: 0,
                  right: 4,
                  child: GestureDetector(
                    onTap: () {
                      // Add code to pick image from gallery/camera
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Change Profile Picture")),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // --------- NAME ---------
            ListTile(
              leading: const Icon(Icons.person, color: Colors.blue),
              title: const Text("Name"),
              subtitle: Text(studentName),
              trailing: IconButton(
                icon: const Icon(Icons.edit, color: Colors.grey),
                onPressed: () {
                  _editField("Name", studentName, (val) {
                    setState(() {
                      studentName = val;
                    });
                  });
                },
              ),
            ),
            const Divider(),

            // --------- EMAIL ---------
            ListTile(
              leading: const Icon(Icons.email, color: Colors.blue),
              title: const Text("Email"),
              subtitle: Text(studentEmail),
            ),
            const Divider(),

            // --------- CLASS ---------
            ListTile(
              leading: const Icon(Icons.school, color: Colors.blue),
              title: const Text("Class"),
              subtitle: Text(studentClass),
            ),
            const Divider(),

            const SizedBox(height: 30),

            // --------- LOGOUT BUTTON ---------
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    await _auth.signOut(); // Firebase logout
                    // Navigate to login page and remove all previous routes
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginPage()),
                      (route) => false,
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Logout failed: $e")),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
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

  // --------- EDIT FIELD DIALOG ---------
  void _editField(String field, String currentValue, Function(String) onSave) {
    final TextEditingController controller =
        TextEditingController(text: currentValue);

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
              onSave(controller.text.trim());
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}
