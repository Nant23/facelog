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
              final data = classes[index].data() as Map<String, dynamic>;

              final DateTime dateTime =
                  (data['date'] as Timestamp).toDate();

              final formattedDate =
                  DateFormat('EEE, MMM d • h:mm a').format(dateTime);

              final String subjectId = data['subject'];
              final String locationId = data['location'];

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: FutureBuilder<List<String>>(
                  future: Future.wait([
                    getSubjectName(subjectId),
                    getLocationName(locationId),
                  ]),
                  builder: (context, snapshot) {
                    final subjectName =
                        snapshot.data?[0] ?? subjectId;
                    final locationName =
                        snapshot.data?[1] ?? locationId;

                    return _classCard(
                      context: context,
                      className: subjectName,
                      classCode: data['groupid'],
                      students: 0,
                      schedule: formattedDate,
                      location: locationName,
                      attendance: "85%",
                    );
                  },
                ),
              );
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF478AFF),
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }

  // --------------------------------------------------------------
  // Class Card Widget
  // --------------------------------------------------------------
  Widget _classCard({
    required BuildContext context,
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
            Text(classCode, style: const TextStyle(color: Colors.black54)),

            const SizedBox(height: 14),

            Row(
              children: const [
                Icon(Icons.group, size: 20, color: Colors.black54),
                SizedBox(width: 8),
                Text("Students TBD"),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                const Icon(Icons.schedule, size: 20, color: Colors.black54),
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

// --------------------------------------------------------------
// Firestore helpers
// --------------------------------------------------------------
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
