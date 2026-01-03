import 'package:flutter/material.dart';

class TeacherDashboardPage extends StatelessWidget {
  const TeacherDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "Welcome Back!",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            SizedBox(height: 4),
            Text(
              "Manage your classes and track attendance",
              style: TextStyle(
                color: Colors.black54,
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(Icons.notifications_none, color: Colors.black),
          )
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ------------------------ Today's Schedule ------------------------
            Container(
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
                children: [
                  Row(
                    children: const [
                      Text(
                        "Today's Schedule",
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Spacer(),
                      Icon(Icons.calendar_month, color: Colors.white),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _scheduleTile("Mathematics 101", "Room 204", "9:00 AM"),
                  const SizedBox(height: 12),
                  _scheduleTile("Chemistry Lab", "Lab 3", "2:00 PM"),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // ------------------------- My Classes Title -------------------------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  "My Classes",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(0xFF478AFF),
                  child: Icon(Icons.add, color: Colors.white),
                ),
              ],
            ),

            const SizedBox(height: 15),

            // ------------------------- Class Card -------------------------
            _classCard(),
          ],
        ),
      ),

      // -------------------------- Bottom Navigation --------------------------
    );
  }

  // --------------------------------------------------------------
  // Schedule Card Tile
  // --------------------------------------------------------------
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
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              Text(subtitle, style: const TextStyle(color: Colors.white70)),
            ],
          ),
          const Spacer(),
          Text(
            time,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------
  // Class Card
  // --------------------------------------------------------------
  Widget _classCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text(
                "Mathematics 101",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Spacer(),
              CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFF478AFF),
                child: Icon(Icons.copy, color: Colors.white),
              )
            ],
          ),
          const SizedBox(height: 4),
          const Text("MATH101", style: TextStyle(color: Colors.black54)),

          const SizedBox(height: 12),
          Row(
            children: const [
              Icon(Icons.group, color: Colors.black54, size: 20),
              SizedBox(width: 8),
              Text("32 students"),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            children: const [
              Icon(Icons.calendar_today, color: Colors.black54, size: 20),
              SizedBox(width: 8),
              Text("Mon, Wed, Fri • 9:00 AM"),
            ],
          ),

          const SizedBox(height: 14),
          const Text("Avg. Attendance", style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 4),
          const Text("85%", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
