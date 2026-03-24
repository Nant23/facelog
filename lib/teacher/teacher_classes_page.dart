import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'teacher_manual_attendance_page.dart';

// ─── State helper (shared across widgets) ────────────────
String computeClassState(Map<String, dynamic> data) {
  final now = DateTime.now();
  final start = (data['date'] as Timestamp).toDate();
  final end = start.add(Duration(minutes: data['duration'] as int? ?? 0));
  if (now.isBefore(start)) return 'scheduled';
  if (now.isAfter(end)) return 'completed';
  return 'ongoing';
}

class TeacherClassesPage extends StatefulWidget {
  const TeacherClassesPage({super.key});

  @override
  State<TeacherClassesPage> createState() => _TeacherClassesPageState();
}

class _TeacherClassesPageState extends State<TeacherClassesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<String?> _resolveTeacherId() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final doc = await FirebaseFirestore.instance
        .collection('teachers')
        .doc(uid)
        .get();
    return doc.exists ? doc['teacherId'] as String? : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: Column(
        children: [
          // ── Header ───────────────────────────────────────
          Container(
            color: const Color(0xFF1A1F3C),
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('My Classes',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  onChanged: (v) =>
                      setState(() => _searchQuery = v.toLowerCase()),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search classes...',
                    hintStyle:
                        const TextStyle(color: Color(0xFF8A9BB5)),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: Color(0xFF8A9BB5)),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded,
                                color: Color(0xFF8A9BB5)),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.08),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TabBar(
                  controller: _tabController,
                  indicatorColor: const Color(0xFF4F6EF7),
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: const Color(0xFF8A9BB5),
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                  tabs: const [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.radio_button_checked,
                              size: 13, color: Color(0xFF22C55E)),
                          SizedBox(width: 5),
                          Text('Ongoing'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.schedule_rounded,
                              size: 13, color: Color(0xFF4F6EF7)),
                          SizedBox(width: 5),
                          Text('Scheduled'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline_rounded,
                              size: 13, color: Color(0xFF8A9BB5)),
                          SizedBox(width: 5),
                          Text('Completed'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Content ──────────────────────────────────────
          Expanded(
            child: FutureBuilder<String?>(
              future: _resolveTeacherId(),
              builder: (context, teacherSnap) {
                if (teacherSnap.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator());
                }
                final teacherId = teacherSnap.data;
                if (teacherId == null) {
                  return _errorState(
                      'Teacher profile not found.\nContact your admin.');
                }

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

                    final allDocs = snapshot.data!.docs.where((doc) {
                      final data =
                          doc.data() as Map<String, dynamic>;
                      return data['date'] != null;
                    }).toList();

                    final filters = [
                      'ongoing',
                      'scheduled',
                      'completed'
                    ];
                    final currentFilter =
                        filters[_tabController.index];

                    var filtered = allDocs.where((doc) {
                      final data =
                          doc.data() as Map<String, dynamic>;
                      return computeClassState(data) ==
                          currentFilter;
                    }).toList();

                    // Apply search
                    if (_searchQuery.isNotEmpty) {
                      filtered = filtered.where((doc) {
                        final data =
                            doc.data() as Map<String, dynamic>;
                        final subject = (data['subject'] ?? '')
                            .toString()
                            .toLowerCase();
                        final group = (data['groupid'] ?? '')
                            .toString()
                            .toLowerCase();
                        return subject.contains(_searchQuery) ||
                            group.contains(_searchQuery);
                      }).toList();
                    }

                    // Sort
                    filtered.sort((a, b) {
                      final aDate =
                          ((a.data() as Map)['date'] as Timestamp)
                              .toDate();
                      final bDate =
                          ((b.data() as Map)['date'] as Timestamp)
                              .toDate();
                      return currentFilter == 'completed'
                          ? bDate.compareTo(aDate)
                          : aDate.compareTo(bDate);
                    });

                    if (filtered.isEmpty) {
                      return _emptyState(currentFilter);
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final doc = filtered[index];
                        final data =
                            doc.data() as Map<String, dynamic>;
                        return _ClassCard(
                          classId: doc.id,
                          data: data,
                          state: currentFilter,
                          context: context,
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

  Widget _emptyState(String filter) {
    final icon = filter == 'ongoing'
        ? Icons.radio_button_checked
        : filter == 'scheduled'
            ? Icons.schedule_rounded
            : Icons.check_circle_outline_rounded;
    final msgs = {
      'ongoing': 'No classes happening right now',
      'scheduled': 'No upcoming classes',
      'completed': 'No completed classes yet',
    };
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(msgs[filter]!,
              style: TextStyle(
                  color: Colors.grey.shade400, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _errorState(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(msg,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.grey.shade400, fontSize: 15)),
      ),
    );
  }
}

// ─── Class Card ───────────────────────────────────────────
class _ClassCard extends StatelessWidget {
  final String classId, state;
  final Map<String, dynamic> data;
  final BuildContext context;
  const _ClassCard({
    required this.classId,
    required this.data,
    required this.state,
    required this.context,
  });

  Future<Map<String, dynamic>> _resolve() async {
    final subjectId = data['subject'] as String? ?? '';
    final locationId = data['location'] as String? ?? '';
    final groupId = data['groupid'] as String? ?? '';

    final results = await Future.wait([
      subjectId.isNotEmpty
          ? FirebaseFirestore.instance
              .collection('subjects')
              .doc(subjectId)
              .get()
          : Future.value(null),
      locationId.isNotEmpty
          ? FirebaseFirestore.instance
              .collection('locations')
              .doc(locationId)
              .get()
          : Future.value(null),
      groupId.isNotEmpty
          ? FirebaseFirestore.instance
              .collection('groups')
              .doc(groupId)
              .get()
          : Future.value(null),
    ]);

    final subDoc = results[0] as DocumentSnapshot?;
    final locDoc = results[1] as DocumentSnapshot?;
    final grpDoc = results[2] as DocumentSnapshot?;

    final studentCount = grpDoc != null && grpDoc.exists
        ? ((grpDoc['students'] as List?)?.length ?? 0)
        : 0;

    return {
      'subject': (subDoc != null && subDoc.exists)
          ? subDoc['name'] as String
          : subjectId,
      'location': (locDoc != null && locDoc.exists)
          ? locDoc['name'] as String
          : locationId,
      'students': studentCount,
    };
  }

  @override
  Widget build(BuildContext ctx) {
    final classStart = (data['date'] as Timestamp).toDate();
    final duration = data['duration'] as int? ?? 0;
    final classEnd = classStart.add(Duration(minutes: duration));
    final attendedCount =
        (data['attended'] as List?)?.length ?? 0;

    final stateColor = state == 'ongoing'
        ? const Color(0xFF22C55E)
        : state == 'scheduled'
            ? const Color(0xFF4F6EF7)
            : const Color(0xFF8A9BB5);

    return FutureBuilder<Map<String, dynamic>>(
      future: _resolve(),
      builder: (context, snap) {
        final subject =
            snap.data?['subject'] ?? data['subject'] ?? '—';
        final location =
            snap.data?['location'] ?? data['location'] ?? '—';
        final students = snap.data?['students'] ?? 0;

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TeacherManualAttendancePage(
                classId: classId,
                className: subject,
                classCode: data['groupid'] ?? '',
              ),
            ),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: state == 'ongoing'
                  ? Border.all(
                      color: const Color(0xFF22C55E).withOpacity(0.4),
                      width: 1.5)
                  : null,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3)),
              ],
            ),
            child: Column(
              children: [
                // Colored top bar for state
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: stateColor,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(18)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subject + state badge
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: stateColor.withOpacity(0.1),
                              borderRadius:
                                  BorderRadius.circular(10),
                            ),
                            child: Icon(
                              state == 'ongoing'
                                  ? Icons.radio_button_checked
                                  : state == 'scheduled'
                                      ? Icons.schedule_rounded
                                      : Icons.check_circle_rounded,
                              color: stateColor,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  subject,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Color(0xFF1A1F3C)),
                                ),
                                Text(
                                  data['groupid'] ?? '—',
                                  style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: stateColor.withOpacity(0.1),
                              borderRadius:
                                  BorderRadius.circular(20),
                            ),
                            child: Text(
                              state[0].toUpperCase() +
                                  state.substring(1),
                              style: TextStyle(
                                  color: stateColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),
                      const Divider(
                          height: 1, color: Color(0xFFF0F2F8)),
                      const SizedBox(height: 12),

                      // Meta info
                      Wrap(
                        spacing: 14,
                        runSpacing: 6,
                        children: [
                          _Chip(
                              icon: Icons.access_time_rounded,
                              label:
                                  '${DateFormat('HH:mm').format(classStart)} → ${DateFormat('HH:mm').format(classEnd)}'),
                          _Chip(
                              icon: Icons.location_on_rounded,
                              label: location),
                          _Chip(
                              icon: Icons.groups_rounded,
                              label: '$students students'),
                          _Chip(
                              icon: Icons.how_to_reg_rounded,
                              label: '$attendedCount present'),
                        ],
                      ),

                      // Ongoing: progress bar
                      if (state == 'ongoing') ...[
                        const SizedBox(height: 12),
                        _ProgressBar(
                            start: classStart, end: classEnd),
                      ],

                      // Scheduled: countdown
                      if (state == 'scheduled') ...[
                        const SizedBox(height: 10),
                        _Countdown(classStart: classStart),
                      ],

                      const SizedBox(height: 12),

                      // CTA
                      Container(
                        width: double.infinity,
                        padding:
                            const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: stateColor.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: stateColor.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Icon(Icons.how_to_reg_rounded,
                                color: stateColor, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              state == 'completed'
                                  ? 'View Attendance Record'
                                  : 'Manage Attendance',
                              style: TextStyle(
                                  color: stateColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600),
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
      },
    );
  }
}

// ─── Progress bar ─────────────────────────────────────────
class _ProgressBar extends StatelessWidget {
  final DateTime start, end;
  const _ProgressBar({required this.start, required this.end});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final total = end.difference(start).inSeconds;
    final elapsed =
        now.difference(start).inSeconds.clamp(0, total);
    final progress = total == 0 ? 0.0 : elapsed / total;
    final remaining = end.difference(now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('In progress',
                style: TextStyle(
                    fontSize: 11, color: Colors.grey.shade500)),
            Text('${remaining.inMinutes}m remaining',
                style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF22C55E),
                    fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor:
                const Color(0xFF22C55E).withOpacity(0.15),
            valueColor:
                const AlwaysStoppedAnimation(Color(0xFF22C55E)),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

// ─── Countdown ────────────────────────────────────────────
class _Countdown extends StatelessWidget {
  final DateTime classStart;
  const _Countdown({required this.classStart});

  @override
  Widget build(BuildContext context) {
    final diff = classStart.difference(DateTime.now());
    String label;
    if (diff.inDays >= 1) {
      label =
          'Starts in ${diff.inDays}d ${diff.inHours % 24}h';
    } else if (diff.inHours >= 1) {
      label =
          'Starts in ${diff.inHours}h ${diff.inMinutes % 60}m';
    } else {
      label = 'Starts in ${diff.inMinutes}m';
    }
    return Row(
      children: [
        const Icon(Icons.hourglass_bottom_rounded,
            size: 13, color: Color(0xFF4F6EF7)),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF4F6EF7),
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ─── Chip ─────────────────────────────────────────────────
class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: const Color(0xFF8A9BB5)),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                color: Color(0xFF8A9BB5), fontSize: 12)),
      ],
    );
  }
}
