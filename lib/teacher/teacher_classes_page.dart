import 'package:flutter/material.dart';
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

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            _classCard(
              context: context,
              className: "Mathematics 101",
              classCode: "MATH101",
              students: 32,
              schedule: "Mon, Wed, Fri • 9:00 AM",
              attendance: "85%",
            ),
            const SizedBox(height: 16),

            _classCard(
              context: context,
              className: "Chemistry Lab",
              classCode: "CHEM201",
              students: 24,
              schedule: "Tue, Thu • 2:00 PM",
              attendance: "78%",
            ),
            const SizedBox(height: 16),

            _classCard(
              context: context,
              className: "Physics",
              classCode: "PHY110",
              students: 40,
              schedule: "Mon–Fri • 11:00 AM",
              attendance: "90%",
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF478AFF),
        onPressed: () {
          // TODO: Add create class action
        },
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
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFF478AFF),
                  child: const Icon(Icons.arrow_forward_ios,
                      size: 16, color: Colors.white),
                ),
              ],
            ),
      
            const SizedBox(height: 4),
            Text(classCode, style: const TextStyle(color: Colors.black54)),
      
            const SizedBox(height: 14),
      
            Row(
              children: [
                const Icon(Icons.group, size: 20, color: Colors.black54),
                const SizedBox(width: 8),
                Text("$students students"),
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
