import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Computes the real-time state of a class from its date + duration.
String getClassState(Map<String, dynamic> data) {
  final now = DateTime.now();
  final classStart = (data['date'] as Timestamp).toDate();
  final classEnd = classStart.add(Duration(minutes: (data['duration'] as int? ?? 0)));

  if (now.isBefore(classStart)) return 'scheduled';
  if (now.isAfter(classEnd)) return 'completed';
  return 'ongoing';
}

class AdminClassesPage extends StatefulWidget {
  const AdminClassesPage({super.key});

  @override
  State<AdminClassesPage> createState() => _AdminClassesPageState();
}

class _AdminClassesPageState extends State<AdminClassesPage>
    with SingleTickerProviderStateMixin {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: Column(
        children: [
          // ── Tab Bar ──────────────────────────────────────────
          Container(
            color: const Color(0xFF1A1F3C),
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF4F6EF7),
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF8A9BB5),
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.radio_button_checked, size: 14, color: Color(0xFF22C55E)),
                      SizedBox(width: 6),
                      Text('Ongoing'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.schedule_rounded, size: 14, color: Color(0xFF4F6EF7)),
                      SizedBox(width: 6),
                      Text('Scheduled'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline_rounded, size: 14, color: Color(0xFF8A9BB5)),
                      SizedBox(width: 6),
                      Text('Completed'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Tab Views ────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _ClassList(filter: 'ongoing'),
                _ClassList(filter: 'scheduled'),
                _ClassList(filter: 'completed'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Class List filtered by computed state ────────────────
class _ClassList extends StatelessWidget {
  final String filter;
  const _ClassList({required this.filter});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('classes').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // Filter client-side using computed state
        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['date'] == null) return false;
          return getClassState(data) == filter;
        }).toList();

        // Sort: ongoing & scheduled by soonest first, completed by most recent first
        docs.sort((a, b) {
          final aDate = ((a.data() as Map)['date'] as Timestamp).toDate();
          final bDate = ((b.data() as Map)['date'] as Timestamp).toDate();
          return filter == 'completed'
              ? bDate.compareTo(aDate)
              : aDate.compareTo(bDate);
        });

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  filter == 'ongoing'
                      ? Icons.radio_button_checked
                      : filter == 'scheduled'
                          ? Icons.schedule_rounded
                          : Icons.check_circle_outline_rounded,
                  size: 64,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 12),
                Text(
                  'No $filter classes',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _ClassCard(classId: doc.id, data: data);
          },
        );
      },
    );
  }
}

// ─── Individual Class Card ────────────────────────────────
class _ClassCard extends StatelessWidget {
  final String classId;
  final Map<String, dynamic> data;
  const _ClassCard({required this.classId, required this.data});

  @override
  Widget build(BuildContext context) {
    final state = getClassState(data);
    final classStart = (data['date'] as Timestamp).toDate();
    final duration = data['duration'] as int? ?? 0;
    final classEnd = classStart.add(Duration(minutes: duration));
    final attendedCount = (data['attended'] as List?)?.length ?? 0;

    final stateColor = state == 'ongoing'
        ? const Color(0xFF22C55E)
        : state == 'scheduled'
            ? const Color(0xFF4F6EF7)
            : const Color(0xFF8A9BB5);

    final stateIcon = state == 'ongoing'
        ? Icons.radio_button_checked
        : state == 'scheduled'
            ? Icons.schedule_rounded
            : Icons.check_circle_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
        border: state == 'ongoing'
            ? Border.all(color: const Color(0xFF22C55E).withOpacity(0.4), width: 1.5)
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Row: ID + State badge ──────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1F3C).withOpacity(0.07),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    classId,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1F3C),
                    ),
                  ),
                ),
                const Spacer(),
                // Ongoing pulse dot
                if (state == 'ongoing')
                  _PulseDot(),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: stateColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(stateIcon, color: stateColor, size: 13),
                      const SizedBox(width: 5),
                      Text(
                        state[0].toUpperCase() + state.substring(1),
                        style: TextStyle(
                          color: stateColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Subject & Teacher ──────────────────────────
            Row(
              children: [
                _IconLabel(
                  icon: Icons.menu_book_rounded,
                  label: data['subject'] ?? '—',
                  color: const Color(0xFF4F6EF7),
                ),
                const SizedBox(width: 16),
                _IconLabel(
                  icon: Icons.person_rounded,
                  label: data['teacherId'] ?? '—',
                  color: const Color(0xFF22C55E),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // ── Group & Location ───────────────────────────
            Row(
              children: [
                _IconLabel(
                  icon: Icons.groups_rounded,
                  label: data['groupid'] ?? '—',
                  color: const Color(0xFFF59E0B),
                ),
                const SizedBox(width: 16),
                _IconLabel(
                  icon: Icons.location_on_rounded,
                  label: data['location'] ?? '—',
                  color: const Color(0xFFEC4899),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // ── Time & Attendance ──────────────────────────
            Row(
              children: [
                Icon(Icons.access_time_rounded, size: 14, color: Colors.grey.shade400),
                const SizedBox(width: 6),
                Text(
                  '${DateFormat('EEE, MMM d • HH:mm').format(classStart)} → ${DateFormat('HH:mm').format(classEnd)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const Spacer(),
                Icon(Icons.how_to_reg_rounded, size: 14, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Text(
                  '$attendedCount present',
                  style: TextStyle(
                    fontSize: 12,
                    color: attendedCount > 0 ? const Color(0xFF22C55E) : Colors.grey.shade400,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            // ── Ongoing: time remaining bar ────────────────
            if (state == 'ongoing') ...[
              const SizedBox(height: 12),
              _ProgressBar(start: classStart, end: classEnd),
            ],

            // ── Scheduled: countdown ──────────────────────
            if (state == 'scheduled') ...[
              const SizedBox(height: 10),
              _CountdownLabel(classStart: classStart),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Animated pulse dot for ongoing ──────────────────────
class _PulseDot extends StatefulWidget {
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
    _anim = Tween(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Color(0xFF22C55E),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// ─── Progress bar for ongoing classes ────────────────────
class _ProgressBar extends StatelessWidget {
  final DateTime start;
  final DateTime end;
  const _ProgressBar({required this.start, required this.end});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final total = end.difference(start).inSeconds;
    final elapsed = now.difference(start).inSeconds.clamp(0, total);
    final progress = total == 0 ? 0.0 : elapsed / total;
    final remaining = end.difference(now);
    final mins = remaining.inMinutes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('In progress', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            Text(
              '$mins min remaining',
              style: const TextStyle(fontSize: 11, color: Color(0xFF22C55E), fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0xFF22C55E).withOpacity(0.15),
            valueColor: const AlwaysStoppedAnimation(Color(0xFF22C55E)),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

// ─── Countdown label for scheduled classes ────────────────
class _CountdownLabel extends StatelessWidget {
  final DateTime classStart;
  const _CountdownLabel({required this.classStart});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final diff = classStart.difference(now);

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
        const Icon(Icons.hourglass_bottom_rounded, size: 13, color: Color(0xFF4F6EF7)),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF4F6EF7), fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

// ─── Icon + label helper ──────────────────────────────────
class _IconLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _IconLabel({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
