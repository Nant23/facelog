import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'teacher_manual_attendance_page.dart';

class TeacherDashboardPage extends StatelessWidget {
  const TeacherDashboardPage({super.key});

  
  Widget _scheduleTile(String title, String subtitle, String time) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600)),
              Text(subtitle,
                  style: const TextStyle(color: Colors.white70)),
            ],
          ),
          const Spacer(),
          Text(time,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text("Welcome Back!",
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 22)),
            SizedBox(height: 4),
            Text("Manage your classes and track attendance",
                style: TextStyle(color: Colors.black54, fontSize: 14)),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('classes').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          final todaysClasses = docs.where((doc) {
            final date = (doc['date'] as Timestamp).toDate();
            return date.year == today.year &&
                date.month == today.month &&
                date.day == today.day;
          }).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ================= TODAY'S SCHEDULE =================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF478AFF), Color(0xFF6A4BFF)],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Today's Schedule",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),

                      if (todaysClasses.isEmpty)
                        const Text("No classes today",
                            style: TextStyle(color: Colors.white70)),

                      ...todaysClasses.map((doc) {
                        final date =
                            (doc['date'] as Timestamp).toDate();
                        final time =
                            DateFormat('h:mm a').format(date);

                        return FutureBuilder<List<String>>(
                          future: Future.wait([
                            getSubjectName(doc['subject']),
                            getLocationName(doc['location']),
                          ]),
                          builder: (context, snap) {
                            if (!snap.hasData) return const SizedBox();

                            return Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 12),
                              child: _scheduleTile(
                                  snap.data![0], snap.data![1], time),
                            );
                          },
                        );
                      }).toList(),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                const Text("My Classes",
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),

                const SizedBox(height: 15),

                if (docs.isNotEmpty)
                  FutureBuilder<Map<String, dynamic>>(
                    future: getClassFullData(docs.first),
                    builder: (context, snap) {
                      if (!snap.hasData) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }

                      final data = snap.data!;

                      return _classCard(
                        context: context,
                        classId: docs.first.id,
                        className: data['subject'],
                        classCode: data['group'],
                        location: data['location'],
                        schedule: data['schedule'],
                        students: data['students'],
                        attendance: data['attendance'],
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // CLASS CARD (NOW CLICKABLE)
  // ============================================================
  Widget _classCard({
    required BuildContext context,
    required String classId,
    required String className,
    required String classCode,
    required String schedule,
    required String location,
    required int students,
    required String attendance,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TeacherManualAttendancePage(
              classId: classId,
              className: className,
              classCode: classCode,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 6)
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Row(
              children: [
                Text(className,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const Spacer(),
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(0xFF478AFF),
                  child: Icon(Icons.arrow_forward_ios,
                      size: 16, color: Colors.white),
                )
              ],
            ),

            const SizedBox(height: 4),
            Text(classCode,
                style: const TextStyle(color: Colors.black54)),

            const SizedBox(height: 12),

            Row(
              children: [
                const Icon(Icons.group,
                    size: 20, color: Colors.black54),
                const SizedBox(width: 8),
                Text("$students students"),
              ],
            ),

            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today,
                    size: 20, color: Colors.black54),
                const SizedBox(width: 8),
                Text(schedule),
              ],
            ),

            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on,
                    size: 20, color: Colors.black54),
                const SizedBox(width: 8),
                Text(location),
              ],
            ),

            const SizedBox(height: 14),
            const Text("Avg. Attendance",
                style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 4),
            Text(attendance,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

Future<String> getSubjectName(String id) async {
  final doc = await FirebaseFirestore.instance
      .collection('subjects')
      .doc(id)
      .get();

  return doc.exists ? doc['name'] : id;
}

Future<String> getLocationName(String id) async {
  final doc = await FirebaseFirestore.instance
      .collection('locations')
      .doc(id)
      .get();

  return doc.exists ? doc['name'] : id;
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

Future<String> calculateAverageAttendance(
    String classId, int totalStudents) async {

  if (totalStudents == 0) return "0%";

  final snapshot = await FirebaseFirestore.instance
      .collection('classes')
      .doc(classId)
      .collection('attendance')
      .get();

  if (snapshot.docs.isEmpty) return "0%";

  int totalPresent = 0;
  int totalSessions = snapshot.docs.length;

  for (var doc in snapshot.docs) {
    final present =
        (doc['presentStudents'] as List<dynamic>?)?.length ?? 0;
    totalPresent += present;
  }

  final percentage =
      (totalPresent / (totalStudents * totalSessions)) * 100;

  return "${percentage.toStringAsFixed(0)}%";
}

Future<Map<String, dynamic>> getClassFullData(
    QueryDocumentSnapshot doc) async {

  final subjectName = await getSubjectName(doc['subject']);
  final locationName = await getLocationName(doc['location']);
  final studentsCount = await getNumberOfStudents(doc['groupid']);
  final avgAttendance =
      await calculateAverageAttendance(doc.id, studentsCount);

  final date = (doc['date'] as Timestamp).toDate();

  return {
    'subject': subjectName,
    'location': locationName,
    'group': doc['groupid'],
    'students': studentsCount,
    'attendance': avgAttendance,
    'schedule': DateFormat('EEE, MMM d • h:mm a').format(date),
  };
}
