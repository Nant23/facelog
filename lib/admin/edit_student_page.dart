import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditStudentPage extends StatefulWidget {
  final String studentId;
  const EditStudentPage({super.key, required this.studentId});

  @override
  State<EditStudentPage> createState() => _EditStudentPageState();
}

class _EditStudentPageState extends State<EditStudentPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController nameController = TextEditingController();

  String? selectedDepartmentCode;
  String? selectedDepartmentName;
  String? selectedGroup;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadStudentData();
  }

  Future<void> loadStudentData() async {
    final doc =
        await _firestore.collection('students').doc(widget.studentId).get();

    final data = doc.data()!;

    setState(() {
      nameController.text = data['name'];
      selectedDepartmentCode = data['department'];
      selectedGroup = data['group'];
      isLoading = false;
    });
  }

  Future<void> updateStudent() async {
    final studentRef =
        _firestore.collection('students').doc(widget.studentId);

    final oldStudentDoc = await studentRef.get();
    final oldGroupId = oldStudentDoc['group'];

    final newGroupId = selectedGroup;

    final batch = _firestore.batch();

    /// 1️⃣ Update student document
    batch.update(studentRef, {
      'name': nameController.text.trim(),
      'department': selectedDepartmentCode,
      'group': newGroupId,
    });

    /// 2️⃣ If group changed → update group arrays
    if (oldGroupId != newGroupId) {
      final oldGroupRef =
          _firestore.collection('groups').doc(oldGroupId);

      final newGroupRef =
          _firestore.collection('groups').doc(newGroupId);

      // Remove from old group
      batch.update(oldGroupRef, {
        'students': FieldValue.arrayRemove([widget.studentId])
      });

      // Add to new group
      batch.update(newGroupRef, {
        'students': FieldValue.arrayUnion([widget.studentId])
      });
    }

    await batch.commit();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Student updated successfully")),
    );

    Navigator.pop(context);
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
        title: const Text("Edit Student"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            /// 🔹 NAME FIELD
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Student Name",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            /// 🔹 DEPARTMENT DROPDOWN
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('departments').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                final departments = snapshot.data!.docs;

                return DropdownButtonFormField<String>(
                  value: selectedDepartmentCode,
                  decoration: const InputDecoration(
                    labelText: "Select Department",
                    border: OutlineInputBorder(),
                  ),
                  items: departments.map((doc) {
                    return DropdownMenuItem<String>(
                      value: doc['code'], // important
                      child: Text(doc['name']), // show full name
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedDepartmentCode = value;
                      selectedGroup = null; // reset group
                    });
                  },
                );
              },
            ),

            const SizedBox(height: 20),

            /// 🔹 GROUP DROPDOWN (FILTERED)
            if (selectedDepartmentCode != null)
              StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('groups')
                    .where('departmentId',
                        isEqualTo: selectedDepartmentCode)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }

                  final groups = snapshot.data!.docs;

                  return DropdownButtonFormField<String>(
                    value: selectedGroup,
                    decoration: const InputDecoration(
                      labelText: "Select Group",
                      border: OutlineInputBorder(),
                    ),
                    items: groups.map((doc) {
                      return DropdownMenuItem<String>(
                        value: doc.id,
                        child: Text(doc['name']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedGroup = value;
                      });
                    },
                  );
                },
              ),

            const SizedBox(height: 30),

            /// 🔹 SAVE BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: updateStudent,
                child: const Text(
                  "Update Student",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
