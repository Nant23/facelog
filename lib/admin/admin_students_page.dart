import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'student_detail_page.dart';

class AdminStudentsPage extends StatefulWidget {
  const AdminStudentsPage({super.key});

  @override
  State<AdminStudentsPage> createState() => _AdminStudentsPageState();
}

class _AdminStudentsPageState extends State<AdminStudentsPage> {
  String? selectedGroup;
  String searchQuery = '';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  /// Calculates attendance % for a given student
  Future<double> fetchAttendance(String studentId) async {
    final classesSnap = await _firestore.collection('classes').get();
    if (classesSnap.docs.isEmpty) return 0.0;

    int total = classesSnap.docs.length;
    int attended = classesSnap.docs
        .where((doc) {
          final List attended = doc['attended'] ?? [];
          return attended.contains(studentId);
        })
        .length;

    return total == 0 ? 0.0 : (attended / total) * 100;
  }

  Color _attendanceColor(double pct) {
    if (pct >= 75) return const Color(0xFF22C55E);
    if (pct >= 50) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: Column(
        children: [
          // ── Search Bar ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => searchQuery = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search students...',
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF8A9BB5)),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // ── Group Dropdown ───────────────────────────────────
          StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('groups').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox(height: 60, child: Center(child: CircularProgressIndicator()));

              final groups = snapshot.data!.docs;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: const Row(
                        children: [
                          Icon(Icons.group_rounded, color: Color(0xFF8A9BB5), size: 20),
                          SizedBox(width: 10),
                          Text('Filter by Group', style: TextStyle(color: Color(0xFF8A9BB5))),
                        ],
                      ),
                      value: selectedGroup,
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('All Groups'),
                        ),
                        ...groups.map((doc) => DropdownMenuItem<String>(
                              value: doc.id,
                              child: Text(doc['name'], style: const TextStyle(fontWeight: FontWeight.w500)),
                            )),
                      ],
                      onChanged: (value) => setState(() => selectedGroup = value),
                    ),
                  ),
                ),
              );
            },
          ),

          // ── Student List ─────────────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: selectedGroup != null
                  ? _firestore.collection('students').where('group', isEqualTo: selectedGroup).snapshots()
                  : _firestore.collection('students').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                var students = snapshot.data!.docs;

                if (searchQuery.isNotEmpty) {
                  students = students.where((doc) {
                    final name = (doc['name'] ?? '').toString().toLowerCase();
                    final email = (doc['email'] ?? '').toString().toLowerCase();
                    return name.contains(searchQuery) || email.contains(searchQuery);
                  }).toList();
                }

                if (students.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off_rounded, size: 60, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('No students found', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final doc = students[index];
                    final data = doc.data() as Map<String, dynamic>;

                    return FutureBuilder<double>(
                      future: fetchAttendance(doc.id),
                      builder: (context, attSnap) {
                        final att = attSnap.data ?? 0.0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => StudentDetailPage(studentId: doc.id)),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    // Avatar
                                    CircleAvatar(
                                      radius: 26,
                                      backgroundColor: const Color(0xFF4F6EF7).withOpacity(0.12),
                                      backgroundImage: data['photoUrl'] != null ? NetworkImage(data['photoUrl']) : null,
                                      child: data['photoUrl'] == null
                                          ? Text(
                                              (data['name'] ?? '?')[0].toUpperCase(),
                                              style: const TextStyle(color: Color(0xFF4F6EF7), fontWeight: FontWeight.bold, fontSize: 18),
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 14),
                                    // Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(data['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A1F3C))),
                                          const SizedBox(height: 2),
                                          Text(data['email'] ?? '', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                          const SizedBox(height: 2),
                                          Text('Dept: ${data['department'] ?? '—'}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    // Attendance badge
                                    Column(
                                      children: [
                                        Text(
                                          '${att.toStringAsFixed(0)}%',
                                          style: TextStyle(
                                            color: _attendanceColor(att),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text('Att.', style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                                        const SizedBox(height: 4),
                                        const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
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
