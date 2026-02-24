import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_student_page.dart';

class StudentDetailPage extends StatelessWidget {
  final String studentId;
  const StudentDetailPage({super.key, required this.studentId});

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Details"),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      EditStudentPage(studentId: studentId),
                ),
              );
            },
          )
        ],
      ),
      
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('students').doc(studentId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final student = snapshot.data!;
          final data = student.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                /// 🔹 PROFILE PICTURE
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.deepPurple.shade100,
                  backgroundImage: data['photoUrl'] != null
                      ? NetworkImage(data['photoUrl'])
                      : null,
                  child: data['photoUrl'] == null
                      ? Text(
                          data['name'][0].toUpperCase(),
                          style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        )
                      : null,
                ),
                const SizedBox(height: 20),

                /// 🔹 NAME
                Text(
                  data['name'],
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                /// 🔹 EMAIL
                Text(
                  data['email'],
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 16),
                ),
                const SizedBox(height: 8),

                /// 🔹 DEPARTMENT & GROUP
                Text(
                  "Department: ${data['department']}",
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 16),
                ),
                Text(
                  "Group: ${data['group']}",
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 16),
                ),
                const SizedBox(height: 20),

                /// 🔹 ATTENDANCE
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                  child: ListTile(
                    leading: const Icon(Icons.check_circle, color: Colors.green),
                    title: const Text("Attendance"),
                    trailing: Text(
                      "${data['attendance'] ?? 0}%",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                /// 🔹 ADDITIONAL INFO (optional)
                if (data['phone'] != null)
                  ListTile(
                    leading: const Icon(Icons.phone),
                    title: const Text("Phone"),
                    subtitle: Text(data['phone']),
                  ),
                if (data['address'] != null)
                  ListTile(
                    leading: const Icon(Icons.home),
                    title: const Text("Address"),
                    subtitle: Text(data['address']),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
