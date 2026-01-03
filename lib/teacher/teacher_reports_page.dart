import 'package:flutter/material.dart';

class TeacherReportsPage extends StatelessWidget {
  const TeacherReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          "Reports & Analytics",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------------- Overall Summary ----------------
            _summaryCard(),

            const SizedBox(height: 25),

            const Text(
              "Class-wise Reports",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 15),

            _reportCard(
              className: "Mathematics 101",
              attendance: "85%",
              present: 27,
              absent: 5,
            ),

            const SizedBox(height: 15),

            _reportCard(
              className: "Chemistry Lab",
              attendance: "78%",
              present: 19,
              absent: 5,
            ),

            const SizedBox(height: 15),

            _reportCard(
              className: "Physics",
              attendance: "90%",
              present: 36,
              absent: 4,
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
  // Overall Summary Card
  // --------------------------------------------------
  Widget _summaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF478AFF), Color(0xFF6A4BFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "Overall Attendance",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Text(
            "86%",
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            "Average attendance across all classes",
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // Class Report Card
  // --------------------------------------------------
  Widget _reportCard({
    required String className,
    required String attendance,
    required int present,
    required int absent,
  }) {
    return Container(
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
          Text(
            className,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statTile("Present", present.toString(), Icons.check_circle, Colors.green),
              _statTile("Absent", absent.toString(), Icons.cancel, Colors.red),
              _statTile("Avg", attendance, Icons.bar_chart, const Color(0xFF478AFF)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statTile(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(label, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }
}
