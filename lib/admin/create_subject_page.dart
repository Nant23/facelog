import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:facelog/login_page.dart';

class CreateSubjectPage extends StatefulWidget {
  const CreateSubjectPage({super.key});

  @override
  State<CreateSubjectPage> createState() => _CreateSubjectPageState();
}

class _CreateSubjectPageState extends State<CreateSubjectPage> {

  final TextEditingController subjectIdController = TextEditingController();
  final TextEditingController subjectNameController = TextEditingController();

  List<Map<String, dynamic>> departments = [];
  String? selectedDepartmentName;
  String? selectedDepartmentCode;

  @override
  void initState() {
    super.initState();
    loadDepartments();
  }

  Future<void> loadDepartments() async {

    final snapshot =
        await FirebaseFirestore.instance.collection("departments").get();

    setState(() {
      departments = snapshot.docs.map((doc) => doc.data()).toList();
    });

  }

  Future<void> createSubject() async {

    if (selectedDepartmentCode == null) return;

    // find groups belonging to this department
    final groupsSnapshot = await FirebaseFirestore.instance
        .collection("groups")
        .where("departmentId", isEqualTo: selectedDepartmentCode)
        .get();

    List<String> groupIds =
        groupsSnapshot.docs.map((doc) => doc.id).toList();

    await FirebaseFirestore.instance
        .collection("subjects")
        .doc(subjectIdController.text)
        .set({
      "name": subjectNameController.text,
      "departmentId": selectedDepartmentCode,
      "groupIds": groupIds,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Subject Created")),
    );

    subjectIdController.clear();
    subjectNameController.clear();

    setState(() {
      selectedDepartmentName = null;
      selectedDepartmentCode = null;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Create Subject"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
                (route) => false,
              );
            },
          )
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [

            TextField(
              controller: subjectIdController,
              decoration: const InputDecoration(
                labelText: "Subject ID (ex: ai_401)",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: subjectNameController,
              decoration: const InputDecoration(
                labelText: "Subject Name",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: selectedDepartmentName,
              hint: const Text("Select Department"),
              items: departments.map((dept) {

                return DropdownMenuItem<String>(
                  value: dept["name"],
                  child: Text(dept["name"]),
                );

              }).toList(),

              onChanged: (value) {

                setState(() {

                  selectedDepartmentName = value;

                  final dept = departments.firstWhere(
                      (d) => d["name"] == value);

                  selectedDepartmentCode = dept["code"];

                });

              },

              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: createSubject,
              child: const Text("Create Subject"),
            ),

          ],
        ),
      ),
    );
  }
}