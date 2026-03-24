import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class StudentHome extends StatefulWidget {
  const StudentHome({super.key});

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome>
    with SingleTickerProviderStateMixin {
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Future<Map<String, dynamic>> _fetchAttendanceStats() async {
    final classesSnap =
        await FirebaseFirestore.instance.collection('classes').get();
    int total = classesSnap.docs.length;
    int present = classesSnap.docs
        .where((doc) => ((doc['attended'] as List?) ?? []).contains(uid))
        .length;
    return {
      'total': total,
      'present': present,
      'absent': total - present,
      'pct': total == 0 ? 0.0 : (present / total) * 100,
    };
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
            const Text('FaceLog',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    letterSpacing: 0.3)),
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
                      '${_greeting()}, $name 👋',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1F3C),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('EEEE, MMMM d').format(DateTime.now()),
                      style:
                          TextStyle(color: Colors.grey.shade500, fontSize: 13),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 20),

            // ── Attendance Overview Card ───────────────────
            FutureBuilder<Map<String, dynamic>>(
              future: _fetchAttendanceStats(),
              builder: (context, snap) {
                final stats = snap.data;
                final pct = (stats?['pct'] as double?) ?? 0.0;
                final present = stats?['present'] ?? 0;
                final absent = stats?['absent'] ?? 0;
                final total = stats?['total'] ?? 0;
                final color = _attColor(pct);
                final status = pct >= 75
                    ? 'Good Standing'
                    : pct >= 50
                        ? 'At Risk'
                        : 'Critical';

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
                          const Text('Overall Attendance',
                              style: TextStyle(
                                  color: Color(0xFF8A9BB5), fontSize: 14)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(status,
                                style: TextStyle(
                                    color: color,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700)),
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
                          : const SizedBox(
                              height: 52,
                              child: Center(
                                  child: CircularProgressIndicator(
                                      color: Colors.white))),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct / 100,
                          backgroundColor: Colors.white12,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _AttBlock(
                              label: 'Present',
                              value: present.toString(),
                              color: const Color(0xFF22C55E)),
                          Container(width: 1, height: 30, color: Colors.white12),
                          _AttBlock(
                              label: 'Absent',
                              value: absent.toString(),
                              color: const Color(0xFFEF4444)),
                          Container(width: 1, height: 30, color: Colors.white12),
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

            // ── My Classes with Tabs ───────────────────────
            const Text(
              'My Classes',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1F3C)),
            ),
            const SizedBox(height: 14),

            // Tab bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04), blurRadius: 8)
                ],
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: const Color(0xFF1A1F3C),
                  borderRadius: BorderRadius.circular(12),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFF8A9BB5),
                labelStyle:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                padding: const EdgeInsets.all(4),
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
                        Text('Done'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Tab content — fixed height, no nested scroll conflict
            _StudentClassTabContent(
              uid: uid,
              tabController: _tabController,
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Tab Content (non-scrollable, embedded in parent scroll) ─
class _StudentClassTabContent extends StatefulWidget {
  final String uid;
  final TabController tabController;
  const _StudentClassTabContent(
      {required this.uid, required this.tabController});

  @override
  State<_StudentClassTabContent> createState() =>
      _StudentClassTabContentState();
}

class _StudentClassTabContentState extends State<_StudentClassTabContent> {
  @override
  void initState() {
    super.initState();
    widget.tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  String _getState(Map<String, dynamic> data) {
    final now = DateTime.now();
    final start = (data['date'] as Timestamp).toDate();
    final end = start.add(Duration(minutes: data['duration'] as int? ?? 0));
    if (now.isBefore(start)) return 'scheduled';
    if (now.isAfter(end)) return 'completed';
    return 'ongoing';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('students')
          .doc(widget.uid)
          .get(),
      builder: (context, studentSnap) {
        if (!studentSnap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final group = studentSnap.data!['group'] as String? ?? '';

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('classes')
              .where('groupid', isEqualTo: group)
              .snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final allDocs = snap.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['date'] != null;
            }).toList();

            final filters = ['ongoing', 'scheduled', 'completed'];
            final currentFilter = filters[widget.tabController.index];

            var filtered = allDocs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return _getState(data) == currentFilter;
            }).toList();

            // Sort
            filtered.sort((a, b) {
              final aDate =
                  ((a.data() as Map)['date'] as Timestamp).toDate();
              final bDate =
                  ((b.data() as Map)['date'] as Timestamp).toDate();
              return currentFilter == 'completed'
                  ? bDate.compareTo(aDate)
                  : aDate.compareTo(bDate);
            });

            if (filtered.isEmpty) {
              return _emptyState(currentFilter);
            }

            return Column(
              children: filtered
                  .map((doc) => _ClassCard(
                        classId: doc.id,
                        data: doc.data() as Map<String, dynamic>,
                        uid: widget.uid,
                        state: currentFilter,
                      ))
                  .toList(),
            );
          },
        );
      },
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          Text(msgs[filter]!,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
        ],
      ),
    );
  }
}

// ─── Class Card ───────────────────────────────────────────
class _ClassCard extends StatelessWidget {
  final String classId, uid, state;
  final Map<String, dynamic> data;
  const _ClassCard(
      {required this.classId,
      required this.data,
      required this.uid,
      required this.state});

  Future<Map<String, String>> _resolve() async {
    final subjectId = data['subject'] as String? ?? '';
    final locationId = data['location'] as String? ?? '';
    final teacherId = data['teacherId'] as String? ?? '';

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
      teacherId.isNotEmpty
          ? FirebaseFirestore.instance
              .collection('teachers')
              .where('teacherId', isEqualTo: teacherId)
              .limit(1)
              .get()
          : Future.value(null),
    ]);

    final subDoc = results[0] as DocumentSnapshot?;
    final locDoc = results[1] as DocumentSnapshot?;
    final teacherQuery = results[2] as QuerySnapshot?;

    return {
      'subject': (subDoc != null && subDoc.exists)
          ? subDoc['name'] as String
          : subjectId,
      'location': (locDoc != null && locDoc.exists)
          ? locDoc['name'] as String
          : locationId,
      'teacher': (teacherQuery != null && teacherQuery.docs.isNotEmpty)
          ? teacherQuery.docs.first['name'] as String
          : teacherId,
    };
  }

  @override
  Widget build(BuildContext context) {
    final classStart = (data['date'] as Timestamp).toDate();
    final duration = data['duration'] as int? ?? 0;
    final classEnd = classStart.add(Duration(minutes: duration));
    final attended = ((data['attended'] as List?) ?? []).contains(uid);
    final attendedCount = (data['attended'] as List?)?.length ?? 0;

    final stateColor = state == 'ongoing'
        ? const Color(0xFF22C55E)
        : state == 'scheduled'
            ? const Color(0xFF4F6EF7)
            : const Color(0xFF8A9BB5);

    return FutureBuilder<Map<String, String>>(
      future: _resolve(),
      builder: (context, snap) {
        final subject = snap.data?['subject'] ?? data['subject'] ?? '—';
        final location = snap.data?['location'] ?? data['location'] ?? '—';
        final teacher = snap.data?['teacher'] ?? data['teacherId'] ?? '—';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: state == 'ongoing'
                ? Border.all(
                    color: const Color(0xFF22C55E).withOpacity(0.4), width: 1.5)
                : null,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: subject + state badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: stateColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
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
                      child: Text(
                        subject,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF1A1F3C)),
                      ),
                    ),
                    // Personal attendance badge
                    if (state == 'completed')
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (attended
                                  ? const Color(0xFF22C55E)
                                  : const Color(0xFFEF4444))
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          attended ? 'Attended' : 'Missed',
                          style: TextStyle(
                              color: attended
                                  ? const Color(0xFF22C55E)
                                  : const Color(0xFFEF4444),
                              fontWeight: FontWeight.bold,
                              fontSize: 11),
                        ),
                      ),
                    if (state != 'completed')
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: stateColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          state[0].toUpperCase() + state.substring(1),
                          style: TextStyle(
                              color: stateColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 11),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                // Info row
                Wrap(
                  spacing: 16,
                  runSpacing: 6,
                  children: [
                    _InfoChip(
                        icon: Icons.access_time_rounded,
                        label:
                            '${DateFormat('HH:mm').format(classStart)} → ${DateFormat('HH:mm').format(classEnd)}'),
                    _InfoChip(
                        icon: Icons.location_on_rounded, label: location),
                    _InfoChip(
                        icon: Icons.person_rounded, label: teacher),
                    _InfoChip(
                        icon: Icons.how_to_reg_rounded,
                        label: '$attendedCount present'),
                  ],
                ),

                // Ongoing progress bar
                if (state == 'ongoing') ...[
                  const SizedBox(height: 12),
                  _ProgressBar(start: classStart, end: classEnd),
                ],

                // Scheduled countdown
                if (state == 'scheduled') ...[
                  const SizedBox(height: 10),
                  _Countdown(classStart: classStart),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Info Chip ────────────────────────────────────────────
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: const Color(0xFF8A9BB5)),
        const SizedBox(width: 4),
        Text(label,
            style:
                const TextStyle(fontSize: 12, color: Color(0xFF8A9BB5))),
      ],
    );
  }
}

// ─── Progress bar for ongoing ─────────────────────────────
class _ProgressBar extends StatelessWidget {
  final DateTime start, end;
  const _ProgressBar({required this.start, required this.end});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final total = end.difference(start).inSeconds;
    final elapsed = now.difference(start).inSeconds.clamp(0, total);
    final progress = total == 0 ? 0.0 : elapsed / total;
    final remaining = end.difference(now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('In progress',
                style:
                    TextStyle(fontSize: 11, color: Colors.grey.shade500)),
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
            backgroundColor: const Color(0xFF22C55E).withOpacity(0.15),
            valueColor:
                const AlwaysStoppedAnimation(Color(0xFF22C55E)),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

// ─── Countdown for scheduled ──────────────────────────────
class _Countdown extends StatelessWidget {
  final DateTime classStart;
  const _Countdown({required this.classStart});

  @override
  Widget build(BuildContext context) {
    final diff = classStart.difference(DateTime.now());
    String label;
    if (diff.inDays >= 1) {
      label = 'Starts in ${diff.inDays}d ${diff.inHours % 24}h';
    } else if (diff.inHours >= 1) {
      label = 'Starts in ${diff.inHours}h ${diff.inMinutes % 60}m';
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
            style: const TextStyle(
                color: Color(0xFF8A9BB5), fontSize: 12)),
      ],
    );
  }
}
