import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TeacherDashboardPage extends StatelessWidget {
  const TeacherDashboardPage({super.key});

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

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('classes').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          // Filter today's classes
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
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                          Spacer(),
                          Icon(Icons.calendar_month, color: Colors.white),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (todaysClasses.isEmpty)
                        const Text(
                          "No classes today",
                          style: TextStyle(color: Colors.white70),
                        ),

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
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _scheduleTile(
                                snap.data![0],
                                snap.data![1],
                                time,
                              ),
                            );
                          },
                        );
                      }).toList(),
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
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                if (docs.isNotEmpty)
                  FutureBuilder<List<String>>(
                    future: Future.wait([
                      getSubjectName(docs.first['subject']),
                      getLocationName(docs.first['location']),
                    ]),
                    builder: (context, snap) {
                      if (!snap.hasData) return const SizedBox();

                      final date =
                          (docs.first['date'] as Timestamp).toDate();

                      return _classCard(
                        className: snap.data![0],
                        classCode: docs.first['groupid'],
                        location: snap.data![1],
                        schedule:
                            DateFormat('EEE, MMM d • h:mm a').format(date),
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

  // --------------------------------------------------------------
  // Schedule Tile
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
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
              Text(subtitle,
                  style: const TextStyle(color: Colors.white70)),
            ],
          ),
          const Spacer(),
          Text(time,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // --------------------------------------------------------------
  // Class Card
  // --------------------------------------------------------------
  Widget _classCard({
    required String className,
    required String classCode,
    required String schedule,
    required String location,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(className,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              const CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFF478AFF),
                child: Icon(Icons.copy, color: Colors.white),
              )
            ],
          ),
          const SizedBox(height: 4),
          Text(classCode, style: const TextStyle(color: Colors.black54)),

          const SizedBox(height: 12),
          Row(
            children: const [
              Icon(Icons.group, color: Colors.black54, size: 20),
              SizedBox(width: 8),
              Text("Students TBD"),
            ],
          ),

          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today,
                  color: Colors.black54, size: 20),
              const SizedBox(width: 8),
              Text(schedule),
            ],
          ),

          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on,
                  color: Colors.black54, size: 20),
              const SizedBox(width: 8),
              Text(location),
            ],
          ),

          const SizedBox(height: 14),
          const Text("Avg. Attendance",
              style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 4),
          const Text("85%",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------
// Firestore Helpers
// --------------------------------------------------------------
Future<String> getSubjectName(String subjectId) async {
  final doc = await FirebaseFirestore.instance
      .collection('subjects')
      .doc(subjectId)
      .get();
  return doc.exists ? doc['name'] : subjectId;
}

Future<String> getLocationName(String locationId) async {
  final doc = await FirebaseFirestore.instance
      .collection('locations')
      .doc(locationId)
      .get();
  return doc.exists ? doc['name'] : locationId;
}
