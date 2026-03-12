import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TeacherManualAttendancePage extends StatefulWidget {
  final String className;
  final String classCode;
  final String classId;

  const TeacherManualAttendancePage({
    super.key,
    required this.className,
    required this.classCode,
    required this.classId,
  });

  @override
  State<TeacherManualAttendancePage> createState() => _TeacherManualAttendancePageState();
}

class _TeacherManualAttendancePageState extends State<TeacherManualAttendancePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<_StudentModel> students = [];
  bool isLoading = true;
  bool isSaving = false;
  DateTime? classDate;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final classDoc = await _firestore.collection('classes').doc(widget.classId).get();
      final attendedList = List<String>.from(classDoc.data()?['attended'] ?? []);
      classDate = (classDoc['date'] as Timestamp).toDate();

      final groupDoc = await _firestore.collection('groups').doc(widget.classCode).get();
      final studentUids = List<dynamic>.from(groupDoc['students'] ?? []);

      final loadedStudents = <_StudentModel>[];
      for (var uid in studentUids) {
        final studentDoc = await _firestore.collection('students').doc(uid).get();
        if (studentDoc.exists) {
          loadedStudents.add(_StudentModel(
            uid: uid,
            name: studentDoc['name'],
            isPresent: attendedList.contains(uid),
          ));
        }
      }

      setState(() {
        students = loadedStudents;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _saveAttendance() async {
    setState(() => isSaving = true);
    try {
      final updatedPresent = students.where((s) => s.isPresent).map((s) => s.uid).toList();
      await _firestore.collection('classes').doc(widget.classId).update({'attended': updatedPresent});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text('Attendance saved successfully'),
            ]),
            backgroundColor: const Color(0xFF22C55E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  void _markAll(bool present) {
    setState(() {
      for (var s in students) s.isPresent = present;
    });
  }

  @override
  Widget build(BuildContext context) {
    final presentCount = students.where((s) => s.isPresent).length;
    final total = students.length;
    final pct = total > 0 ? presentCount / total * 100 : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1F3C),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.className, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            Text(widget.classCode, style: const TextStyle(color: Color(0xFF8A9BB5), fontSize: 12)),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ── Summary Header ──────────────────────────
                Container(
                  color: const Color(0xFF1A1F3C),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, color: Color(0xFF4F6EF7), size: 18),
                            const SizedBox(width: 10),
                            Text(
                              classDate != null
                                  ? DateFormat('EEEE, MMMM d, yyyy').format(classDate!)
                                  : 'Manual Attendance',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: _pctColor(pct).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${pct.toStringAsFixed(0)}%',
                                style: TextStyle(color: _pctColor(pct), fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryChip(
                              label: 'Present',
                              count: presentCount,
                              color: const Color(0xFF22C55E),
                              icon: Icons.check_circle_rounded,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _SummaryChip(
                              label: 'Absent',
                              count: total - presentCount,
                              color: const Color(0xFFEF4444),
                              icon: Icons.cancel_rounded,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _SummaryChip(
                              label: 'Total',
                              count: total,
                              color: const Color(0xFF4F6EF7),
                              icon: Icons.groups_rounded,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Mark All Row ────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                  child: Row(
                    children: [
                      Text('Students', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700, fontSize: 14)),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => _markAll(true),
                        icon: const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF22C55E)),
                        label: const Text('All Present', style: TextStyle(color: Color(0xFF22C55E), fontSize: 12)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _markAll(false),
                        icon: const Icon(Icons.cancel_rounded, size: 16, color: Color(0xFFEF4444)),
                        label: const Text('All Absent', style: TextStyle(color: Color(0xFFEF4444), fontSize: 12)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Student List ────────────────────────────
                Expanded(
                  child: students.isEmpty
                      ? Center(child: Text('No students in this group', style: TextStyle(color: Colors.grey.shade400)))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                          itemCount: students.length,
                          itemBuilder: (context, index) {
                            return _StudentTile(
                              student: students[index],
                              index: index,
                              onChanged: (v) => setState(() => students[index].isPresent = v),
                            );
                          },
                        ),
                ),

                // ── Save Button ─────────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  color: Colors.white,
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isSaving ? null : _saveAttendance,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F6EF7),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: isSaving
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.save_rounded),
                                const SizedBox(width: 8),
                                Text(
                                  'Save Attendance ($presentCount/$total)',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Color _pctColor(double pct) {
    if (pct >= 75) return const Color(0xFF22C55E);
    if (pct >= 50) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;
  const _SummaryChip({required this.label, required this.count, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text('$count', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
          Text(label, style: TextStyle(color: color.withOpacity(0.7), fontSize: 10)),
        ],
      ),
    );
  }
}

class _StudentTile extends StatelessWidget {
  final _StudentModel student;
  final int index;
  final ValueChanged<bool> onChanged;
  const _StudentTile({required this.student, required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: student.isPresent ? const Color(0xFF22C55E).withOpacity(0.06) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: student.isPresent ? const Color(0xFF22C55E).withOpacity(0.3) : const Color(0xFFE8ECF4),
        ),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: student.isPresent
                ? const Color(0xFF22C55E).withOpacity(0.15)
                : const Color(0xFF4F6EF7).withOpacity(0.1),
            child: Text(
              student.name[0].toUpperCase(),
              style: TextStyle(
                color: student.isPresent ? const Color(0xFF22C55E) : const Color(0xFF4F6EF7),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF1A1F3C))),
                Text(
                  student.isPresent ? 'Present' : 'Absent',
                  style: TextStyle(
                    fontSize: 12,
                    color: student.isPresent ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: student.isPresent,
            activeColor: const Color(0xFF22C55E),
            activeTrackColor: const Color(0xFF22C55E).withOpacity(0.3),
            inactiveThumbColor: const Color(0xFFEF4444),
            inactiveTrackColor: const Color(0xFFEF4444).withOpacity(0.2),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _StudentModel {
  final String uid;
  final String name;
  bool isPresent;

  _StudentModel({required this.uid, required this.name, required this.isPresent});
}
