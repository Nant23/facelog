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
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  /// Calculate real attendance stats from Firestore
  Future<Map<String, dynamic>> _fetchAttendanceStats() async {
    final classesSnap =
        await FirebaseFirestore.instance.collection('classes').get();
    int total = classesSnap.docs.length;
    int present = classesSnap.docs
        .where((doc) => ((doc['attended'] as List?) ?? []).contains(uid))
        .length;
    int absent = total - present;
    double pct = total == 0 ? 0.0 : (present / total) * 100;
    return {'total': total, 'present': present, 'absent': absent, 'pct': pct};
  }

  Color _attColor(double pct) {
    if (pct >= 75) return const Color(0xFF22C55E);
    if (pct >= 50) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
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
              child: const Icon(Icons.face_retouching_natural,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'FaceLog',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  letterSpacing: 0.3),
            ),
          ],
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF4F6EF7),
              child: Text('S',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Greeting ──────────────────────────────────
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('students')
                  .doc(uid)
                  .get(),
              builder: (context, snap) {
                final name = snap.data?['name'] ?? 'Student';
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good morning, $name 👋',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1F3C),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('EEEE, MMMM d').format(today),
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 13),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 20),

            // ── Attendance Card ────────────────────────────
            FutureBuilder<Map<String, dynamic>>(
              future: _fetchAttendanceStats(),
              builder: (context, snap) {
                final stats = snap.data;
                final pct = (stats?['pct'] as double?) ?? 0.0;
                final present = stats?['present'] ?? 0;
                final absent = stats?['absent'] ?? 0;
                final total = stats?['total'] ?? 0;
                final color = _attColor(pct);
                final status =
                    pct >= 75 ? 'Good Standing' : pct >= 50 ? 'At Risk' : 'Critical';

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A1F3C), Color(0xFF2D3561)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                          color: const Color(0xFF1A1F3C).withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8)),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.bar_chart_rounded,
                              color: Color(0xFF4F6EF7), size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Overall Attendance',
                            style: TextStyle(
                                color: Color(0xFF8A9BB5), fontSize: 14),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                  color: color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      snap.hasData
                          ? Text(
                              '${pct.toStringAsFixed(1)}%',
                              style: TextStyle(
                                  fontSize: 52,
                                  height: 1,
                                  color: color,
                                  fontWeight: FontWeight.bold),
                            )
                          : const CircularProgressIndicator(
                              color: Colors.white),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _AttBlock(
                              label: 'Present',
                              value: present.toString(),
                              color: const Color(0xFF22C55E)),
                          Container(
                              width: 1, height: 30, color: Colors.white12),
                          _AttBlock(
                              label: 'Absent',
                              value: absent.toString(),
                              color: const Color(0xFFEF4444)),
                          Container(
                              width: 1, height: 30, color: Colors.white12),
                          _AttBlock(
                              label: 'Total',
                              value: total.toString(),
                              color: Colors.white70),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 28),

            // ── Today's Classes ────────────────────────────
            Row(
              children: [
                const Text(
                  "Today's Classes",
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1F3C)),
                ),
                const Spacer(),
                Text(
                  DateFormat('MMM d').format(today),
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              ],
            ),

            const SizedBox(height: 14),

            _TodayClassesSection(uid: uid),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Today's Classes Section ──────────────────────────────
class _TodayClassesSection extends StatelessWidget {
  final String uid;
  const _TodayClassesSection({required this.uid});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('students').doc(uid).get(),
      builder: (context, studentSnap) {
        if (!studentSnap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!studentSnap.data!.exists) {
          return _emptyState('Student record not found');
        }

        final group = studentSnap.data!['group'] as String;
        final now = DateTime.now();
        final startOfDay = DateTime(now.year, now.month, now.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('classes')
              .where('groupid', isEqualTo: group)
              .where('date',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
              .where('date', isLessThan: Timestamp.fromDate(endOfDay))
              .orderBy('date')
              .snapshots(),
          builder: (context, classSnap) {
            if (!classSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (classSnap.data!.docs.isEmpty) {
              return _emptyState('No classes scheduled today 🎉');
            }

            return Column(
              children: classSnap.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final attended =
                    ((data['attended'] as List?) ?? []).contains(uid);
                final time = DateFormat.jm()
                    .format((data['date'] as Timestamp).toDate());

                return _ClassTile(
                  subjectId: data['subject'] ?? '',
                  locationId: data['location'] ?? '',
                  time: time,
                  attended: attended,
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  Widget _emptyState(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_available_rounded,
              size: 40, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          Text(msg,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
        ],
      ),
    );
  }
}

// ─── Class Tile (resolves subject/location names) ─────────
class _ClassTile extends StatelessWidget {
  final String subjectId, locationId, time;
  final bool attended;
  const _ClassTile({
    required this.subjectId,
    required this.locationId,
    required this.time,
    required this.attended,
  });

  Future<List<String>> _resolve() async {
    final subDoc = await FirebaseFirestore.instance
        .collection('subjects')
        .doc(subjectId)
        .get();
    final locDoc = await FirebaseFirestore.instance
        .collection('locations')
        .doc(locationId)
        .get();
    final subject = subDoc.exists ? subDoc['name'] as String : subjectId;
    final location = locDoc.exists ? locDoc['name'] as String : locationId;
    return [subject, location];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: _resolve(),
      builder: (context, snap) {
        final subject = snap.data?[0] ?? subjectId;
        final location = snap.data?[1] ?? locationId;
        final color =
            attended ? const Color(0xFF22C55E) : const Color(0xFF4F6EF7);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  attended
                      ? Icons.check_circle_rounded
                      : Icons.menu_book_rounded,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF1A1F3C)),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded,
                            size: 12, color: Colors.grey.shade400),
                        const SizedBox(width: 3),
                        Text(location,
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    time,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: color),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      attended ? 'Attended' : 'Pending',
                      style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Attendance Stat Block ────────────────────────────────
class _AttBlock extends StatelessWidget {
  final String label, value;
  final Color color;
  const _AttBlock(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 22, color: color, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label,
            style:
                const TextStyle(color: Color(0xFF8A9BB5), fontSize: 12)),
      ],
    );
  }
}
