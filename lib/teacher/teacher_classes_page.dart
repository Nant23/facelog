import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'teacher_manual_attendance_page.dart';

class TeacherClassesPage extends StatefulWidget {
  const TeacherClassesPage({super.key});

  @override
  State<TeacherClassesPage> createState() => _TeacherClassesPageState();
}

class _TeacherClassesPageState extends State<TeacherClassesPage> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  /// Fetches the custom teacherId (e.g. "T001") from the teachers collection
  /// using the Firebase Auth UID as the document ID.
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
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: Column(
        children: [
          // ── Top Bar ──────────────────────────────────────
          Container(
            color: const Color(0xFF1A1F3C),
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Classes',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search classes...',
                    hintStyle: const TextStyle(color: Color(0xFF8A9BB5)),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF8A9BB5)),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, color: Color(0xFF8A9BB5)),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.08),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Classes List ─────────────────────────────────
          Expanded(
            // Step 1: resolve the custom teacherId
            child: FutureBuilder<String?>(
              future: _resolveTeacherId(),
              builder: (context, teacherSnap) {
                if (teacherSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final teacherId = teacherSnap.data;

                if (teacherId == null) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline_rounded, size: 52, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          'Teacher profile not found.\nContact your admin.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 15),
                        ),
                      ],
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
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.class_outlined, size: 60, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text(
                              'No classes assigned yet',
                              style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
                            ),
                          ],
                        ),
                      );
                    }

                    final classes = snapshot.data!.docs;

                    return ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: classes.length,
                      itemBuilder: (context, index) {
                        final classDoc = classes[index];
                        final data = classDoc.data() as Map<String, dynamic>;
                        final dateTime = (data['date'] as Timestamp).toDate();
                        final formattedDate = DateFormat('EEE, MMM d • h:mm a').format(dateTime);
                        final groupId = data['groupid'] as String;

                        return FutureBuilder<List<dynamic>>(
                          future: Future.wait([
                            _getSubjectName(data['subject']),
                            _getLocationName(data['location']),
                            _getNumberOfStudents(groupId),
                          ]),
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

                            final subjectName = snap.data![0] as String;
                            final locationName = snap.data![1] as String;
                            final studentsCount = snap.data![2] as int;

                            // Filter by search query
                            if (_searchQuery.isNotEmpty &&
                                !subjectName.toLowerCase().contains(_searchQuery) &&
                                !groupId.toLowerCase().contains(_searchQuery)) {
                              return const SizedBox.shrink();
                            }

                            return _ClassCard(
                              context: context,
                              classId: classDoc.id,
                              className: subjectName,
                              classCode: groupId,
                              students: studentsCount,
                              schedule: formattedDate,
                              location: locationName,
                              isToday: dateTime.year == DateTime.now().year &&
                                  dateTime.month == DateTime.now().month &&
                                  dateTime.day == DateTime.now().day,
                            );
                          },
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

// ─── Class Card ───────────────────────────────────────────
class _ClassCard extends StatelessWidget {
  final BuildContext context;
  final String classId, className, classCode, schedule, location;
  final int students;
  final bool isToday;

  const _ClassCard({
    required this.context,
    required this.classId,
    required this.className,
    required this.classCode,
    required this.students,
    required this.schedule,
    required this.location,
    required this.isToday,
  });

  @override
  Widget build(BuildContext ctx) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TeacherManualAttendancePage(
            className: className,
            classCode: classCode,
            classId: classId,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            if (isToday)
              Container(
                height: 4,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4F6EF7), Color(0xFF22C55E)],
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
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
                        child: const Icon(Icons.menu_book_rounded, color: Color(0xFF4F6EF7), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              className,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF1A1F3C),
                              ),
                            ),
                            Text(
                              classCode,
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      if (isToday)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Today',
                            style: TextStyle(
                              color: Color(0xFF22C55E),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F6EF7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: Color(0xFFF0F2F8)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _Chip(icon: Icons.groups_rounded, label: '$students students'),
                      const SizedBox(width: 12),
                      _Chip(icon: Icons.location_on_rounded, label: location),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _Chip(icon: Icons.schedule_rounded, label: schedule),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F6EF7).withOpacity(0.07),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF4F6EF7).withOpacity(0.15)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.how_to_reg_rounded, color: Color(0xFF4F6EF7), size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Tap to manage attendance',
                          style: TextStyle(
                            color: Color(0xFF4F6EF7),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});

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
