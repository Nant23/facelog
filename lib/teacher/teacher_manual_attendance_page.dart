import 'package:flutter/material.dart';

class TeacherManualAttendancePage extends StatelessWidget {
  final String className;
  final String classCode;

  const TeacherManualAttendancePage({
    super.key,
    required this.className,
    required this.classCode,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              className,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Text(
              classCode,
              style: const TextStyle(color: Colors.black54, fontSize: 14),
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          // ---------------- Date Selector ----------------
          _dateHeader(),

          // ---------------- Student List ----------------
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _students.length,
              itemBuilder: (context, index) {
                return _studentTile(_students[index]);
              },
            ),
          ),
        ],
      ),

      // ---------------- Save Button ----------------
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF478AFF),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: () {
            // TODO: Save attendance to Firestore
          },
          child: const Text(
            "Save Attendance",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------
  // Date Header
  // --------------------------------------------------
  Widget _dateHeader() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF478AFF), Color(0xFF6A4BFF)],
        ),
      ),
      child: Row(
        children: const [
          Icon(Icons.calendar_today, color: Colors.white),
          SizedBox(width: 12),
          Text(
            "Today • Manual Attendance",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // Student Tile
  // --------------------------------------------------
  Widget _studentTile(Student student) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF478AFF),
            child: Text(
              student.name[0],
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  student.rollNo,
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),

          Switch(
            value: student.isPresent,
            activeColor: Colors.green,
            onChanged: (value) {
              student.isPresent = value;
            },
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------
// Dummy Model (replace with Firestore later)
// --------------------------------------------------
class Student {
  final String name;
  final String rollNo;
  bool isPresent;

  Student({
    required this.name,
    required this.rollNo,
    this.isPresent = true,
  });
}

// Dummy student list
final List<Student> _students = [
  Student(name: "Aarav Sharma", rollNo: "ST-01"),
  Student(name: "Nisha Gurung", rollNo: "ST-02"),
  Student(name: "Ramesh Thapa", rollNo: "ST-03"),
  Student(name: "Sita Rai", rollNo: "ST-04"),
];
