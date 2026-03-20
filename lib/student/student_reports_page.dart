import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class StudentReportsPage extends StatefulWidget {
  const StudentReportsPage({super.key});

  @override
  State<StudentReportsPage> createState() => _StudentReportsPageState();
}

class _StudentReportsPageState extends State<StudentReportsPage> {
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  // Cache the future so it doesn't re-fire on every rebuild
  late final Future<_ReportData> _reportFuture = _loadReport();

  Future<_ReportData> _loadReport() async {
    // ── Step 1: get student's group ──────────────────────
    final studentDoc = await FirebaseFirestore.instance
        .collection('students')
        .doc(uid)
        .get();

    // Also try uid-field fallback if direct lookup misses
    String group = '';
    if (studentDoc.exists) {
      group = (studentDoc.data()?['group'] as String?) ?? '';
    } else {
      final q = await FirebaseFirestore.instance
          .collection('students')
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();
      if (q.docs.isNotEmpty) {
        group = (q.docs.first['group'] as String?) ?? '';
      }
    }

    if (group.isEmpty) {
      return _ReportData.empty();
    }

    // ── Step 2: fetch classes for group ──────────────────
    // NO orderBy — avoids requiring a composite Firestore index
    final classesSnap = await FirebaseFirestore.instance
        .collection('classes')
        .where('groupid', isEqualTo: group)
        .get();

    if (classesSnap.docs.isEmpty) {
      return _ReportData.empty();
    }

    // ── Step 3: fetch all unique subject names in parallel ──
    final subjectIds =
        classesSnap.docs.map((d) => d['subject'] as String).toSet().toList();

    final subjectDocs = await Future.wait(
      subjectIds.map((id) =>
          FirebaseFirestore.instance.collection('subjects').doc(id).get()),
    );

    final subjectNames = <String, String>{};
    for (int i = 0; i < subjectIds.length; i++) {
      final doc = subjectDocs[i];
      subjectNames[subjectIds[i]] =
          doc.exists ? (doc['name'] as String? ?? subjectIds[i]) : subjectIds[i];
    }

    // ── Step 4: build per-subject breakdown ──────────────
    final subjectMap = <String, _SubjectData>{};
    final allEntries = <_ClassEntry>[];

    for (final doc in classesSnap.docs) {
      final subjectId = doc['subject'] as String;
      final subjectName = subjectNames[subjectId] ?? subjectId;
      final attended = ((doc['attended'] as List?) ?? []).contains(uid);
      final date = (doc['date'] as Timestamp).toDate();

      subjectMap.putIfAbsent(subjectId, () => _SubjectData(name: subjectName));
      subjectMap[subjectId]!.total++;
      if (attended) subjectMap[subjectId]!.present++;

      allEntries.add(_ClassEntry(
        subjectName: subjectName,
        date: date,
        attended: attended,
      ));
    }

    // Sort entries by date descending (done in Dart, not Firestore)
    allEntries.sort((a, b) => b.date.compareTo(a.date));

    final totalClasses = classesSnap.docs.length;
    final totalPresent = allEntries.where((e) => e.attended).length;

    return _ReportData(
      totalClasses: totalClasses,
      totalPresent: totalPresent,
      totalAbsent: totalClasses - totalPresent,
      overallPct:
          totalClasses == 0 ? 0.0 : (totalPresent / totalClasses) * 100,
      subjects: subjectMap.values.toList(),
      recentClasses: allEntries,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────
          Container(
            color: const Color(0xFF1A1F3C),
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.of(context).padding.top + 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Attendance Reports',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Your detailed attendance per subject',
                  style: TextStyle(color: Color(0xFF8A9BB5), fontSize: 13),
                ),
              ],
            ),
          ),

          // ── Content ──────────────────────────────────────
          Expanded(
            child: FutureBuilder<_ReportData>(
              future: _reportFuture,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snap.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline_rounded,
                              size: 52, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text(
                            'Could not load report.\n${snap.error}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.grey.shade400, fontSize: 14),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => setState(() {}),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4F6EF7),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final report = snap.data!;

                if (report.totalClasses == 0) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bar_chart_rounded,
                            size: 60, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('No attendance data yet',
                            style: TextStyle(
                                color: Colors.grey.shade400, fontSize: 16)),
                      ],
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Overall card
                    _OverallCard(
                      total: report.totalClasses,
                      present: report.totalPresent,
                      absent: report.totalAbsent,
                      pct: report.overallPct,
                    ),

                    const SizedBox(height: 24),

                    const Text('By Subject',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1F3C))),
                    const SizedBox(height: 12),

                    ...report.subjects.map((s) => _SubjectCard(subject: s)),

                    const SizedBox(height: 24),

                    const Text('Recent Activity',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1F3C))),
                    const SizedBox(height: 12),

                    ...report.recentClasses
                        .take(15)
                        .map((c) => _ActivityTile(entry: c)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Data Models ──────────────────────────────────────────
class _ReportData {
  final int totalClasses, totalPresent, totalAbsent;
  final double overallPct;
  final List<_SubjectData> subjects;
  final List<_ClassEntry> recentClasses;

  _ReportData({
    required this.totalClasses,
    required this.totalPresent,
    required this.totalAbsent,
    required this.overallPct,
    required this.subjects,
    required this.recentClasses,
  });

  factory _ReportData.empty() => _ReportData(
        totalClasses: 0,
        totalPresent: 0,
        totalAbsent: 0,
        overallPct: 0,
        subjects: [],
        recentClasses: [],
      );
}

class _SubjectData {
  final String name;
  int total = 0;
  int present = 0;
  _SubjectData({required this.name});
  double get pct => total == 0 ? 0.0 : (present / total) * 100;
  int get absent => total - present;
}

class _ClassEntry {
  final String subjectName;
  final DateTime date;
  final bool attended;
  _ClassEntry(
      {required this.subjectName,
      required this.date,
      required this.attended});
}

// ─── Overall Card ─────────────────────────────────────────
class _OverallCard extends StatelessWidget {
  final int total, present, absent;
  final double pct;
  const _OverallCard(
      {required this.total,
      required this.present,
      required this.absent,
      required this.pct});

  Color get _color {
    if (pct >= 75) return const Color(0xFF22C55E);
    if (pct >= 50) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  String get _status {
    if (pct >= 75) return 'Good Standing';
    if (pct >= 50) return 'At Risk';
    return 'Critical';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
              const Text('Overall Attendance',
                  style:
                      TextStyle(color: Color(0xFF8A9BB5), fontSize: 14)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _color.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(_status,
                    style: TextStyle(
                        color: _color,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${pct.toStringAsFixed(1)}%',
            style: TextStyle(
                fontSize: 52,
                height: 1,
                color: _color,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct / 100,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(_color),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatBlock(
                  label: 'Present',
                  value: present.toString(),
                  color: const Color(0xFF22C55E)),
              Container(width: 1, height: 30, color: Colors.white12),
              _StatBlock(
                  label: 'Absent',
                  value: absent.toString(),
                  color: const Color(0xFFEF4444)),
              Container(width: 1, height: 30, color: Colors.white12),
              _StatBlock(
                  label: 'Total',
                  value: total.toString(),
                  color: Colors.white70),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatBlock(
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
            style: const TextStyle(
                color: Color(0xFF8A9BB5), fontSize: 12)),
      ],
    );
  }
}

// ─── Subject Card ─────────────────────────────────────────
class _SubjectCard extends StatelessWidget {
  final _SubjectData subject;
  const _SubjectCard({required this.subject});

  Color get _color {
    if (subject.pct >= 75) return const Color(0xFF22C55E);
    if (subject.pct >= 50) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.menu_book_rounded,
                    color: _color, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  subject.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF1A1F3C)),
                ),
              ),
              Text(
                '${subject.pct.toStringAsFixed(0)}%',
                style: TextStyle(
                    color: _color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: subject.pct / 100,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(_color),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _MiniStat(
                  label: '${subject.present} Present',
                  color: const Color(0xFF22C55E)),
              const SizedBox(width: 14),
              _MiniStat(
                  label: '${subject.absent} Absent',
                  color: const Color(0xFFEF4444)),
              const SizedBox(width: 14),
              _MiniStat(
                  label: '${subject.total} Total',
                  color: const Color(0xFF8A9BB5)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final Color color;
  const _MiniStat({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w500));
  }
}

// ─── Activity Tile ────────────────────────────────────────
class _ActivityTile extends StatelessWidget {
  final _ClassEntry entry;
  const _ActivityTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final color = entry.attended
        ? const Color(0xFF22C55E)
        : const Color(0xFFEF4444);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03), blurRadius: 6),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              entry.subjectName,
              style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  color: Color(0xFF1A1F3C)),
            ),
          ),
          Text(
            DateFormat('MMM d, yyyy').format(entry.date),
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          ),
          const SizedBox(width: 10),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              entry.attended ? 'Present' : 'Absent',
              style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
