import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'teacher_manual_attendance_page.dart';

class TeacherClassesPage extends StatelessWidget {
  const TeacherClassesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          "My Classes",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(Icons.search, color: Colors.black),
          )
        ],
      ),

      // ----------------------------------------------------
      // Classes Stream
      // ----------------------------------------------------
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('classes')
            .snapshots(),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No classes found"));
          }

          final classes = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: classes.length,
            itemBuilder: (context, index) {

              final classDoc = classes[index];
              final data = classDoc.data() as Map<String, dynamic>;

              final DateTime dateTime =
                  (data['date'] as Timestamp).toDate();

              final formattedDate =
                  DateFormat('EEE, MMM d • h:mm a').format(dateTime);

              final String subjectId = data['subject'];
              final String locationId = data['location'];
              final String groupId = data['groupid'];

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: FutureBuilder<List<dynamic>>(
                  future: Future.wait([
                    getSubjectName(subjectId),
                    getLocationName(locationId),
                    getNumberOfStudents(groupId),
                  ]),
                  builder: (context, snapshot) {

                    if (!snapshot.hasData) {
                      return const Center(
                          child: CircularProgressIndicator());
                    }

                    final subjectName = snapshot.data![0] as String;
                    final locationName = snapshot.data![1] as String;
                    final studentsCount = snapshot.data![2] as int;

                    return _classCard(
                      context: context,
                      classId: classDoc.id,
                      className: subjectName,
                      classCode: groupId,
                      students: studentsCount,
                      schedule: formattedDate,
                      location: locationName,
                      attendance: "--%",
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ----------------------------------------------------
  // Class Card Widget
  // ----------------------------------------------------
  Widget _classCard({
    required BuildContext context,
    required String classId,
    required String className,
    required String classCode,
    required int students,
    required String schedule,
    required String location,
    required String attendance,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TeacherManualAttendancePage(
              className: className,
              classCode: classCode,
              classId: classId,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Title Row
            Row(
              children: [
                Expanded(
                  child: Text(
                    className,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(0xFF478AFF),
                  child: Icon(Icons.arrow_forward_ios,
                      size: 16, color: Colors.white),
                ),
              ],
            ),

            const SizedBox(height: 4),

            Text(
              classCode,
              style: const TextStyle(color: Colors.black54),
            ),

            const SizedBox(height: 14),

            // Students
            Row(
              children: [
                const Icon(Icons.group,
                    size: 20, color: Colors.black54),
                const SizedBox(width: 8),
                Text("$students students"),
              ],
            ),

            const SizedBox(height: 8),

            // Schedule
            Row(
              children: [
                const Icon(Icons.schedule,
                    size: 20, color: Colors.black54),
                const SizedBox(width: 8),
                Text(schedule),
              ],
            ),

            const SizedBox(height: 8),

            // Location
            Row(
              children: [
                const Icon(Icons.location_on,
                    size: 20, color: Colors.black54),
                const SizedBox(width: 8),
                Text(location),
              ],
            ),

            const SizedBox(height: 14),

            // Attendance
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Avg. Attendance",
                  style: TextStyle(color: Colors.black54),
                ),
                Text(
                  attendance,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF478AFF),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// Firestore Helpers
// ----------------------------------------------------

Future<String> getSubjectName(String subjectId) async {
  final doc = await FirebaseFirestore.instance
      .collection('subjects')
      .doc(subjectId)
      .get();

  if (!doc.exists) return subjectId;

  return doc['name'];
}

Future<String> getLocationName(String locationId) async {
  final doc = await FirebaseFirestore.instance
      .collection('locations')
      .doc(locationId)
      .get();

  if (!doc.exists) return locationId;

  return doc['name'];
}

Future<int> getNumberOfStudents(String groupId) async {
  final doc = await FirebaseFirestore.instance
      .collection('groups')
      .doc(groupId)
      .get();

  if (!doc.exists) return 0;

  final students = doc['students'] as List<dynamic>?;

  return students?.length ?? 0;
}
