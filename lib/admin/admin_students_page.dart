import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'student_detail_page.dart';

class AdminStudentsPage extends StatefulWidget {
  const AdminStudentsPage({super.key});

  @override
  State<AdminStudentsPage> createState() => _AdminStudentsPageState();
}

class _AdminStudentsPageState extends State<AdminStudentsPage> {
  String? selectedGroup;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Students",
        style: TextStyle(
          color: Colors.white,
        )
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
        elevation: 2,
      ),
      body: Column(
        children: [
          /// 🔽 GROUP DROPDOWN
          StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('groups').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                );
              }

              final groups = snapshot.data!.docs;

              return Padding(
                padding: const EdgeInsets.all(12.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.deepPurple.shade200),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: const Text("Select Group"),
                      value: selectedGroup,
                      items: groups.map((doc) {
                        return DropdownMenuItem<String>(
                          value: doc.id,
                          child: Text(
                            doc['name'],
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedGroup = value;
                        });
                      },
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 10),

          /// 📋 STUDENT LIST
          Expanded(
            child: selectedGroup == null
                ? const Center(
                    child: Text(
                      "Select a group",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('students')
                        .where('group', isEqualTo: selectedGroup)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final students = snapshot.data!.docs;

                      if (students.isEmpty) {
                        return const Center(
                          child: Text(
                            "No students found",
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: students.length,
                        itemBuilder: (context, index) {
                          final data = students[index];

                          double attendancePercentage = 0.0; // TODO: fetch real data

                          return Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: CircleAvatar(
                                backgroundColor: Colors.deepPurple.shade100,
                                child: Text(
                                  data['name'][0].toUpperCase(),
                                  style: const TextStyle(
                                      color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(
                                data['name'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    "Email: ${data['email']}",
                                    style: TextStyle(color: Colors.grey.shade700),
                                  ),
                                  Text(
                                    "Department: ${data['department']}",
                                    style: TextStyle(color: Colors.grey.shade700),
                                  ),
                                  Text(
                                    "Attendance: ${attendancePercentage.toStringAsFixed(1)}%",
                                    style: TextStyle(color: Colors.grey.shade700),
                                  ),
                                ],
                              ),
                              trailing: Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.deepPurple.shade300,
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => StudentDetailPage(studentId: data.id),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
