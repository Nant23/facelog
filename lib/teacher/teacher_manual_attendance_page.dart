import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherManualAttendancePage extends StatefulWidget {
  final String className;
  final String classCode; // this is groupid
  final String classId;   // Firestore document id of class

  const TeacherManualAttendancePage({
    super.key,
    required this.className,
    required this.classCode,
    required this.classId,
  });

  @override
  State<TeacherManualAttendancePage> createState() =>
      _TeacherManualAttendancePageState();
}

class _TeacherManualAttendancePageState
    extends State<TeacherManualAttendancePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<StudentModel> students = [];
  List<String> attendedList = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      // 1️⃣ Get class document
      final classDoc =
          await _firestore.collection('classes').doc(widget.classId).get();

      attendedList =
          List<String>.from(classDoc.data()?['attended'] ?? []);

      // 2️⃣ Get group document
      final groupDoc = await _firestore
          .collection('groups')
          .doc(widget.classCode)
          .get();

      List<dynamic> studentUids = groupDoc['students'];

      // 3️⃣ Fetch student names
      for (var uid in studentUids) {
        final studentDoc =
            await _firestore.collection('students').doc(uid).get();

        final name = studentDoc['name'];

        students.add(
          StudentModel(
            uid: uid,
            name: name,
            isPresent: attendedList.contains(uid),
          ),
        );
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print("Error loading attendance data: $e");
    }
  }

  Future<void> saveAttendance() async {
    List<String> updatedPresent =
        students.where((s) => s.isPresent).map((s) => s.uid).toList();

    await _firestore.collection('classes').doc(widget.classId).update({
      'attended': updatedPresent,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Attendance Saved Successfully")),
    );
  }

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
              widget.className,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Text(
              widget.classCode,
              style:
                  const TextStyle(color: Colors.black54, fontSize: 14),
            ),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _dateHeader(),
                Expanded(
                  child: ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      return _studentTile(students[index]);
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF478AFF),
            padding:
                const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: saveAttendance,
          child: const Text(
            "Save Attendance",
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

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

  Widget _studentTile(StudentModel student) {
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
              style:
                  const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              student.name,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
          ),
          Switch(
            value: student.isPresent,
            activeColor: Colors.green,
            onChanged: (value) {
              setState(() {
                student.isPresent = value;
              });
            },
          ),
        ],
      ),
    );
  }
}

class StudentModel {
  final String uid;
  final String name;
  bool isPresent;

  StudentModel({
    required this.uid,
    required this.name,
    required this.isPresent,
  });
}
