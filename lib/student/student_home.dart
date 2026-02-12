import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class StudentHome extends StatefulWidget {
  const StudentHome({super.key});

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f6ff),

      // ------------ APP BAR ------------
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.only(left: 16),
          child: Icon(Icons.calendar_month, color: Colors.blue, size: 30),
        ),
        title: const Text(
          "Facelog",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.notifications_none, color: Colors.black),
          )
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const SizedBox(height: 10),

            const Text(
              "Hi, Student!",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              "Track your attendance and stay updated",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),

            const SizedBox(height: 20),

            // ------------ ATTENDANCE CARD ------------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xff5271ff), Color(0xff675fff)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    "Overall Attendance",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "90%",
                    style: TextStyle(
                      fontSize: 48,
                      height: 1,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: const [
                      _attBlock("Present", "112"),
                      _attBlock("Absent", "13"),
                      _attBlock("Total", "125"),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // ------------ TODAY'S CLASSES ------------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  "Today's Classes",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(Icons.calendar_today, size: 20),
              ],
            ),

            const SizedBox(height: 15),

            _todayClassesSection(),

            const SizedBox(height: 25),

            const Text(
              "My Attendance",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ------------ FETCH AND SHOW TODAY'S CLASSES ------------
  Widget _todayClassesSection() {
    final String uid = FirebaseAuth.instance.currentUser!.uid;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('students').doc(uid).get(),
      builder: (context, studentSnapshot) {
        if (!studentSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!studentSnapshot.data!.exists) {
          return const Text("Student record not found");
        }

        String group = studentSnapshot.data!['group'];

        DateTime now = DateTime.now();
        DateTime startOfDay = DateTime(now.year, now.month, now.day);
        DateTime endOfDay = startOfDay.add(const Duration(days: 1));

        return StreamBuilder<QuerySnapshot>(
          
          stream: FirebaseFirestore.instance
              .collection('classes')
              .where('groupid', isEqualTo: group)
              .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
              .where('date', isLessThan: Timestamp.fromDate(endOfDay))
              .orderBy('date')
              .snapshots(),
          builder: (context, classSnapshot) {
            if (!classSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            if (classSnapshot.data!.docs.isEmpty) {
              return const Text("No classes today 🎉");
            }

            return Column(
              children: classSnapshot.data!.docs.map((doc) {
                List attendedList = doc['attended'] ?? [];
                bool isAttended = attendedList.contains(uid);

                Timestamp ts = doc['date'];
                DateTime classTime = ts.toDate();
                String formattedTime = DateFormat.jm().format(classTime);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _classTile(
                    title: doc['subject'],
                    subtitle: doc['location'],
                    time: formattedTime,
                    attended: isAttended,
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  // ------------ CLASS LIST TILE ------------
  Widget _classTile({
    required String title,
    required String subtitle,
    required String time,
    required bool attended,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 10,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              color: attended
                  ? Colors.green.withOpacity(0.1)
                  : Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              attended ? Icons.check_circle : Icons.menu_book,
              color: attended ? Colors.green : Colors.blue,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          Column(
            children: [
              Text(
                time,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                attended ? "Attended" : "Pending",
                style: TextStyle(
                  fontSize: 12,
                  color: attended ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}

// ------------ SMALL BOX (Present/Absent/Total) ------------
class _attBlock extends StatelessWidget {
  final String title;
  final String value;

  const _attBlock(this.title, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
