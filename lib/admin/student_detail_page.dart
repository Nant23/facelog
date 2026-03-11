import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_student_page.dart';

class StudentDetailPage extends StatelessWidget {
  final String studentId;
  const StudentDetailPage({super.key, required this.studentId});

  Future<double> _fetchAttendance(String studentId) async {
    final classesSnap = await FirebaseFirestore.instance.collection('classes').get();
    if (classesSnap.docs.isEmpty) return 0.0;
    int total = classesSnap.docs.length;
    int attended = classesSnap.docs.where((doc) {
      final List a = doc['attended'] ?? [];
      return a.contains(studentId);
    }).length;
    return total == 0 ? 0.0 : (attended / total) * 100;
  }

  Color _attColor(double pct) {
    if (pct >= 75) return const Color(0xFF22C55E);
    if (pct >= 50) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1F3C),
        foregroundColor: Colors.white,
        title: const Text('Student Details'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => EditStudentPage(studentId: studentId)),
            ),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('students').doc(studentId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            child: Column(
              children: [
                // ── Hero Banner ──────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A1F3C),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: const Color(0xFF4F6EF7),
                        backgroundImage: data['photoUrl'] != null ? NetworkImage(data['photoUrl']) : null,
                        child: data['photoUrl'] == null
                            ? Text(
                                (data['name'] ?? '?')[0].toUpperCase(),
                                style: const TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: Colors.white),
                              )
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        data['name'] ?? '—',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data['email'] ?? '—',
                        style: const TextStyle(color: Color(0xFF8A9BB5), fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _Badge(label: data['department'] ?? '—', icon: Icons.school_rounded),
                          const SizedBox(width: 10),
                          _Badge(label: 'Group: ${data['group'] ?? '—'}', icon: Icons.groups_rounded),
                        ],
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Attendance Card ──────────────────────
                      FutureBuilder<double>(
                        future: _fetchAttendance(studentId),
                        builder: (context, snap) {
                          final att = snap.data ?? 0.0;
                          final color = _attColor(att);
                          return Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.check_circle_rounded, color: color, size: 28),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Attendance Rate', style: TextStyle(color: Color(0xFF8A9BB5), fontSize: 13)),
                                      Text(
                                        '${att.toStringAsFixed(1)}%',
                                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    att >= 75 ? 'Good' : att >= 50 ? 'At Risk' : 'Critical',
                                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 20),
                      const Text('Contact Info', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A1F3C))),
                      const SizedBox(height: 12),

                      // ── Additional Info ──────────────────────
                      if (data['phone'] != null)
                        _InfoTile(icon: Icons.phone_rounded, label: 'Phone', value: data['phone']),
                      if (data['address'] != null)
                        _InfoTile(icon: Icons.home_rounded, label: 'Address', value: data['address']),
                      if (data['phone'] == null && data['address'] == null)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline_rounded, color: Colors.grey.shade400),
                              const SizedBox(width: 12),
                              Text('No additional contact info', style: TextStyle(color: Colors.grey.shade400)),
                            ],
                          ),
                        ),

                      const SizedBox(height: 20),

                      // ── Edit Button ──────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => EditStudentPage(studentId: studentId)),
                          ),
                          icon: const Icon(Icons.edit_rounded),
                          label: const Text('Edit Student', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F6EF7),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final IconData icon;
  const _Badge({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 14),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF4F6EF7).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF4F6EF7), size: 18),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Color(0xFF8A9BB5), fontSize: 12)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }
}
