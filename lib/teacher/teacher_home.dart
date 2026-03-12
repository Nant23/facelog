import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'teacher_manual_attendance_page.dart';

class TeacherDashboardPage extends StatelessWidget {
  const TeacherDashboardPage({super.key});

  /// Fetches the custom teacherId (e.g. "T001") stored in the teachers
  /// collection. The document ID in that collection is the Firebase Auth UID.
  Future<String?> _resolveTeacherId() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final doc = await FirebaseFirestore.instance
        .collection('teachers')
        .doc(uid)
        .get();
    if (!doc.exists) return null;
    return doc['teacherId'] as String?;
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final today = DateTime.now();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1F3C),
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF4F6EF7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.face_retouching_natural, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'FaceLog',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, letterSpacing: 0.3),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF4F6EF7),
              child: Text('T', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        ],
      ),

      // Step 1: resolve the custom teacherId from Firestore
      body: FutureBuilder<String?>(
        future: _resolveTeacherId(),
        builder: (context, teacherSnap) {
          if (teacherSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final teacherId = teacherSnap.data;

          if (teacherId == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Teacher profile not found.\nAsk your admin to set up your account.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF8A9BB5), fontSize: 15),
                ),
              ),
            );
          }

          // Step 2: query classes using the custom teacherId (e.g. "T001")
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('classes')
                .where('teacherId', isEqualTo: teacherId)
                .snapshots(),
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
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Greeting ──────────────────────────────
                    FutureBuilder<DocumentSnapshot>(
                      future: uid != null
                          ? FirebaseFirestore.instance.collection('teachers').doc(uid).get()
                          : null,
                      builder: (context, snap) {
                        final teacherName = snap.data?['name'] ?? 'Teacher';
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Good morning, $teacherName 👋',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1F3C),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('EEEE, MMMM d').format(today),
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // ── Stat Row ───────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Total Classes',
                            value: docs.length.toString(),
                            icon: Icons.class_rounded,
                            color: const Color(0xFF4F6EF7),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _StatCard(
                            label: 'Today',
                            value: todaysClasses.length.toString(),
                            icon: Icons.today_rounded,
                            color: const Color(0xFF22C55E),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ── Today's Schedule ───────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1A1F3C), Color(0xFF2D3561)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.today_rounded, color: Color(0xFF4F6EF7), size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                "Today's Schedule",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4F6EF7).withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${todaysClasses.length} class${todaysClasses.length != 1 ? 'es' : ''}',
                                  style: const TextStyle(
                                    color: Color(0xFF4F6EF7),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (todaysClasses.isEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.event_available_rounded, color: Color(0xFF8A9BB5), size: 22),
                                  SizedBox(width: 10),
                                  Text(
                                    'No classes scheduled today',
                                    style: TextStyle(color: Color(0xFF8A9BB5)),
                                  ),
                                ],
                              ),
                            )
                          else
                            ...todaysClasses.map((doc) {
                              final date = (doc['date'] as Timestamp).toDate();
                              final time = DateFormat('h:mm a').format(date);
                              return FutureBuilder<List<String>>(
                                future: Future.wait([
                                  _getSubjectName(doc['subject']),
                                  _getLocationName(doc['location']),
                                ]),
                                builder: (context, snap) {
                                  if (!snap.hasData) return const SizedBox();
                                  return _ScheduleTile(
                                    title: snap.data![0],
                                    subtitle: snap.data![1],
                                    time: time,
                                  );
                                },
                              );
                            }),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── My Classes ────────────────────────────
                    Row(
                      children: [
                        const Text(
                          'My Classes',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1F3C),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${docs.length} total',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    if (docs.isEmpty)
                      Center(
                        child: Text(
                          'No classes assigned yet',
                          style: TextStyle(color: Colors.grey.shade400),
                        ),
                      )
                    else
                      ...docs.take(3).map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return FutureBuilder<Map<String, dynamic>>(
                          future: _getClassFullData(doc),
                          builder: (context, snap) {
                            if (!snap.hasData) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              );
                            }
                            final d = snap.data!;
                            return _ClassCard(
                              context: context,
                              classId: doc.id,
                              className: d['subject'],
                              classCode: data['groupid'],
                              location: d['location'],
                              schedule: d['schedule'],
                              students: d['students'],
                              attendance: d['attendance'],
                            );
                          },
                        );
                      }),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ─── Schedule Tile ────────────────────────────────────────
class _ScheduleTile extends StatelessWidget {
  final String title, subtitle, time;
  const _ScheduleTile({required this.title, required this.subtitle, required this.time});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF4F6EF7),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                Text(subtitle, style: const TextStyle(color: Color(0xFF8A9BB5), fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF4F6EF7).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              time,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: color.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1F3C))),
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Class Card ───────────────────────────────────────────
class _ClassCard extends StatelessWidget {
  final BuildContext context;
  final String classId, className, classCode, schedule, location, attendance;
  final int students;
  const _ClassCard({
    required this.context,
    required this.classId,
    required this.className,
    required this.classCode,
    required this.schedule,
    required this.location,
    required this.students,
    required this.attendance,
  });

  @override
  Widget build(BuildContext ctx) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TeacherManualAttendancePage(
            classId: classId,
            className: className,
            classCode: classCode,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F6EF7).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.class_rounded, color: Color(0xFF4F6EF7), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(className, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A1F3C))),
                      Text(classCode, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F6EF7).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    attendance,
                    style: const TextStyle(color: Color(0xFF4F6EF7), fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                _MetaChip(icon: Icons.groups_rounded, label: '$students students'),
                const SizedBox(width: 10),
                _MetaChip(icon: Icons.location_on_rounded, label: location),
              ],
            ),
            const SizedBox(height: 6),
            _MetaChip(icon: Icons.schedule_rounded, label: schedule),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF8A9BB5)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Color(0xFF8A9BB5), fontSize: 12)),
      ],
    );
  }
}

// ─── Firestore Helpers ────────────────────────────────────
Future<String> _getSubjectName(String id) async {
  final doc = await FirebaseFirestore.instance.collection('subjects').doc(id).get();
  return doc.exists ? doc['name'] : id;
}

Future<String> _getLocationName(String id) async {
  final doc = await FirebaseFirestore.instance.collection('locations').doc(id).get();
  return doc.exists ? doc['name'] : id;
}

Future<int> _getNumberOfStudents(String groupId) async {
  final doc = await FirebaseFirestore.instance.collection('groups').doc(groupId).get();
  if (!doc.exists) return 0;
  return ((doc['students'] as List<dynamic>?)?.length ?? 0);
}

Future<String> _calcAverageAttendance(String classId, int totalStudents) async {
  if (totalStudents == 0) return "0%";
  final snap = await FirebaseFirestore.instance
      .collection('classes')
      .doc(classId)
      .collection('attendance')
      .get();
  if (snap.docs.isEmpty) return "0%";
  int totalPresent = 0;
  for (var d in snap.docs) {
    totalPresent += ((d['presentStudents'] as List<dynamic>?)?.length ?? 0);
  }
  final pct = (totalPresent / (totalStudents * snap.docs.length)) * 100;
  return "${pct.toStringAsFixed(0)}%";
}

Future<Map<String, dynamic>> _getClassFullData(QueryDocumentSnapshot doc) async {
  final subject = await _getSubjectName(doc['subject']);
  final location = await _getLocationName(doc['location']);
  final students = await _getNumberOfStudents(doc['groupid']);
  final attendance = await _calcAverageAttendance(doc.id, students);
  final date = (doc['date'] as Timestamp).toDate();
  return {
    'subject': subject,
    'location': location,
    'students': students,
    'attendance': attendance,
    'schedule': DateFormat('EEE, MMM d • h:mm a').format(date),
  };
}
