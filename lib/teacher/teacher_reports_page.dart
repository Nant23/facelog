import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TeacherReportsPage extends StatelessWidget {
  const TeacherReportsPage({super.key});

  /// Step 1: Get the custom teacher ID (e.g. "TCH001") from the teachers
  /// collection by matching the Firebase Auth UID.
  Future<String?> _getTeacherId(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection('teachers')
        .doc(uid)          // ← document ID is the Firebase Auth UID directly
        .get();
    if (!doc.exists) return null;
    return doc['teacherId'] as String?;  // ← returns "TCH001"
  }

  Future<Map<String, dynamic>> _fetchReportData(
      String classId, String groupId) async {
    final classDoc = await FirebaseFirestore.instance
        .collection('classes')
        .doc(classId)
        .get();
    final groupDoc = await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .get();

    final attended =
        List<String>.from(classDoc.data()?['attended'] ?? []);
    final allStudents =
        List<String>.from(groupDoc.data()?['students'] ?? []);

    final total = allStudents.length;
    final present = attended.length;
    final absent = total - present;
    final pct = total > 0 ? (present / total * 100) : 0.0;

    return {
      'total': total,
      'present': present,
      'absent': absent,
      'pct': pct,
    };
  }

  Color _attColor(double pct) {
    if (pct >= 75) return const Color(0xFF22C55E);
    if (pct >= 50) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────
          Container(
            color: const Color(0xFF1A1F3C),
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
            child: const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Reports & Analytics',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),

          Expanded(
            child: uid == null
                ? const Center(child: Text('Not logged in'))
                : FutureBuilder<String?>(
                    // Step 1: resolve custom teacherId from Firebase Auth UID
                    future: _getTeacherId(uid),
                    builder: (context, teacherSnap) {
                      if (teacherSnap.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }

                      final teacherId = teacherSnap.data;

                      if (teacherId == null) {
                        return const Center(
                            child: Text('Teacher profile not found.'));
                      }

                      // Step 2: stream classes using the custom teacherId
                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('classes')
                            .where('teacherId', isEqualTo: teacherId)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          final docs = snapshot.data!.docs;

                          if (docs.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.bar_chart_rounded,
                                      size: 60,
                                      color: Colors.grey.shade300),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No class data yet',
                                    style: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 16),
                                  ),
                                ],
                              ),
                            );
                          }

                          return FutureBuilder<List<Map<String, dynamic>>>(
                            future: Future.wait(docs.map((doc) async {
                              final data =
                                  doc.data() as Map<String, dynamic>;
                              final subjectName =
                                  await _getSubjectName(data['subject']);
                              final stats = await _fetchReportData(
                                  doc.id, data['groupid']);
                              return {
                                'subject': subjectName,
                                'classId': doc.id,
                                ...stats
                              };
                            })),
                            builder: (context, snap) {
                              if (!snap.hasData) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }

                              final reports = snap.data!;

                              final overallPct = reports.isEmpty
                                  ? 0.0
                                  : reports
                                          .map((r) => r['pct'] as double)
                                          .reduce((a, b) => a + b) /
                                      reports.length;

                              return SingleChildScrollView(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    // ── Overall Summary Card ──────────
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(22),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF1A1F3C),
                                            Color(0xFF2D3561)
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(
                                                        10),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                          0xFF4F6EF7)
                                                      .withOpacity(0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10),
                                                ),
                                                child: const Icon(
                                                    Icons.bar_chart_rounded,
                                                    color:
                                                        Color(0xFF4F6EF7),
                                                    size: 22),
                                              ),
                                              const SizedBox(width: 14),
                                              const Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment
                                                        .start,
                                                children: [
                                                  Text(
                                                    'Overall Attendance',
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16),
                                                  ),
                                                  Text(
                                                    'Across all your classes',
                                                    style: TextStyle(
                                                        color: Color(
                                                            0xFF8A9BB5),
                                                        fontSize: 12),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 20),
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                '${overallPct.toStringAsFixed(1)}%',
                                                style: TextStyle(
                                                  color: _attColor(
                                                      overallPct),
                                                  fontSize: 44,
                                                  fontWeight:
                                                      FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(width: 14),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.only(
                                                        bottom: 8),
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 12,
                                                      vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: _attColor(
                                                            overallPct)
                                                        .withOpacity(0.15),
                                                    borderRadius:
                                                        BorderRadius
                                                            .circular(20),
                                                  ),
                                                  child: Text(
                                                    overallPct >= 75
                                                        ? 'Good'
                                                        : overallPct >= 50
                                                            ? 'At Risk'
                                                            : 'Critical',
                                                    style: TextStyle(
                                                        color: _attColor(
                                                            overallPct),
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 13),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${docs.length} class${docs.length != 1 ? 'es' : ''} tracked',
                                            style: const TextStyle(
                                                color: Color(0xFF8A9BB5),
                                                fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 24),

                                    const Text(
                                      'Class-wise Breakdown',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1A1F3C)),
                                    ),
                                    const SizedBox(height: 14),

                                    ...reports.map((r) => _ReportCard(
                                          className:
                                              r['subject'] as String,
                                          present: r['present'] as int,
                                          absent: r['absent'] as int,
                                          total: r['total'] as int,
                                          pct: r['pct'] as double,
                                        )),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Report Card ────────────────────────────────────────────────────────────────

class _ReportCard extends StatelessWidget {
  final String className;
  final int present, absent, total;
  final double pct;

  const _ReportCard({
    required this.className,
    required this.present,
    required this.absent,
    required this.total,
    required this.pct,
  });

  Color get _color {
    if (pct >= 75) return const Color(0xFF22C55E);
    if (pct >= 50) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(className,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1F3C))),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${pct.toStringAsFixed(1)}%',
                  style: TextStyle(
                      color: _color,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: total > 0 ? pct / 100 : 0,
              backgroundColor: _color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(_color),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                  child: _StatBox(
                      label: 'Present',
                      value: present.toString(),
                      color: const Color(0xFF22C55E))),
              const SizedBox(width: 10),
              Expanded(
                  child: _StatBox(
                      label: 'Absent',
                      value: absent.toString(),
                      color: const Color(0xFFEF4444))),
              const SizedBox(width: 10),
              Expanded(
                  child: _StatBox(
                      label: 'Total',
                      value: total.toString(),
                      color: const Color(0xFF4F6EF7))),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Stat Box ───────────────────────────────────────────────────────────────────

class _StatBox extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatBox(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 18, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(color: color.withOpacity(0.7), fontSize: 11)),
        ],
      ),
    );
  }
}

// ── Helper ─────────────────────────────────────────────────────────────────────

Future<String> _getSubjectName(String id) async {
  final doc = await FirebaseFirestore.instance
      .collection('subjects')
      .doc(id)
      .get();
  return doc.exists ? doc['name'] : id;
}