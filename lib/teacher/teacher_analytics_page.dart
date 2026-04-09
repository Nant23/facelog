import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;

class TeacherAnalyticsPage extends StatefulWidget {
  const TeacherAnalyticsPage({super.key});

  @override
  State<TeacherAnalyticsPage> createState() => _TeacherAnalyticsPageState();
}

class _TeacherAnalyticsPageState extends State<TeacherAnalyticsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  // ── Summary counts ──────────────────────────────────────────
  int totalStudents = 0;
  int totalClasses = 0;
  int totalGroups = 0;

  // Attendance distribution
  int goodCount = 0;
  int atRiskCount = 0;
  int criticalCount = 0;

  // Per-student attendance (scoped to teacher's groups)
  List<_StudentAtt> studentAttendances = [];

  // Per-group average attendance (scoped to teacher's groups)
  List<_GroupAtt> groupAttendances = [];

  // Classes by day of week (scoped to teacher's groups)
  List<int> classesByDow = List.filled(7, 0);

  // Top absentees (scoped)
  List<_StudentAtt> topAbsentees = [];

  // Currently selected group filter (null = all)
  String? _selectedGroupId;
  List<_GroupAtt> _allGroups = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Data loading ─────────────────────────────────────────────
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final fs = FirebaseFirestore.instance;

    // Step 1: get teacher doc → groups_taken array
    // teachers/{uid}.groups_taken = ["cs_2022_a", "ibm_2026_a", ...]
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) { setState(() => _isLoading = false); return; }

    final teacherDoc = await fs.collection('teachers').doc(uid).get();
    if (!teacherDoc.exists) { setState(() => _isLoading = false); return; }

    final myGroupIds = List<String>.from(
        teacherDoc.data()?['groups_taken'] ?? []);
    if (myGroupIds.isEmpty) { setState(() => _isLoading = false); return; }

    // Step 2: fetch each group doc
    // groups/{groupId}: { name, year, departmentId, students: ["uid1",...] }
    final groupDocs = await Future.wait(
      myGroupIds.map((id) => fs.collection('groups').doc(id).get()),
    );

    // Step 3: build groupId → studentUids map from groups.students[]
    final Map<String, Set<String>> studentUidsByGroup = {};
    final Set<String> allStudentUids = {};
    for (final gDoc in groupDocs) {
      if (!gDoc.exists) continue;
      final uids = Set<String>.from(
          List<dynamic>.from(gDoc.data()?['students'] ?? []));
      studentUidsByGroup[gDoc.id] = uids;
      allStudentUids.addAll(uids);
    }
    if (allStudentUids.isEmpty) { setState(() => _isLoading = false); return; }

    // Step 4: fetch student docs in batches of 10 (Firestore whereIn limit)
    final List<QueryDocumentSnapshot<Map<String, dynamic>>> studentDocs = [];
    final uidList = allStudentUids.toList();
    for (int i = 0; i < uidList.length; i += 10) {
      final batch = uidList.sublist(
          i, (i + 10) > uidList.length ? uidList.length : (i + 10));
      final snap = await fs
          .collection('students')
          .where(FieldPath.documentId, whereIn: batch)
          .get();
      studentDocs.addAll(snap.docs);
    }

    // Step 5: fetch classes for each group (classes.groupid == group doc ID)
    final List<QueryDocumentSnapshot<Map<String, dynamic>>> classDocs = [];
    for (final groupId in myGroupIds) {
      final snap = await fs
          .collection('classes')
          .where('groupid', isEqualTo: groupId)
          .get();
      classDocs.addAll(snap.docs);
    }

    // ── Classes by day-of-week (scoped)
    final dowCounts = List.filled(7, 0);
    for (final c in classDocs) {
      final ts = c.data()['date'];
      if (ts is Timestamp) {
        dowCounts[ts.toDate().weekday - 1]++;
      }
    }

    // ── Build attended-ID sets per class
    final Map<String, Set<String>> attendedByClass = {};
    for (final c in classDocs) {
      final raw = c.data()['attended'];
      final Set<String> ids = {};
      if (raw is List) {
        for (final item in raw) {
          if (item is String) ids.add(item);
          else if (item is DocumentReference) ids.add(item.id);
        }
      }
      attendedByClass[c.id] = ids;
    }

    // ── Per-student attendance
    // Group membership comes from groups.students[], not from student doc field
    final List<_StudentAtt> atts = [];
    for (final s in studentDocs) {
      final sName = (s.data()['name'] as String?) ?? '—';

      // Find which group this student belongs to
      final sGroup = studentUidsByGroup.entries
          .firstWhere(
            (e) => e.value.contains(s.id),
            orElse: () => MapEntry('', {}),
          )
          .key;

      // Only count classes for that specific group
      final studentClasses =
          classDocs.where((c) => c.data()['groupid'] == sGroup).toList();

      int attended = 0;
      for (final c in studentClasses) {
        if (attendedByClass[c.id]?.contains(s.id) ?? false) attended++;
      }

      final total = studentClasses.length;
      final pct   = total == 0 ? 0.0 : (attended / total) * 100;

      atts.add(_StudentAtt(
        id:       s.id,
        name:     sName,
        group:    sGroup,
        pct:      pct,
        attended: attended,
        total:    total,
      ));
    }

    // ── Per-group average attendance
    final List<_GroupAtt> groups = [];
    for (final gDoc in groupDocs) {
      if (!gDoc.exists) continue;
      final g = gDoc;
      final groupStudents = atts.where((a) => a.group == g.id).toList();
      final avg = groupStudents.isEmpty
          ? 0.0
          : groupStudents.map((a) => a.pct).reduce((a, b) => a + b) /
              groupStudents.length;
      final gData = g.data()!;
      groups.add(_GroupAtt(
        id:           g.id,
        name:         (gData['name'] as String?) ?? g.id,
        avgPct:       avg,
        studentCount: groupStudents.length,
        classCount:   classDocs.where((c) => c.data()['groupid'] == g.id).length,
      ));
    }

    final sortedGroups =
        groups..sort((a, b) => b.avgPct.compareTo(a.avgPct));
    final sortedAtts   =
        [...atts]..sort((a, b) => b.pct.compareTo(a.pct));
    final sortedBottom = [...atts]..sort((a, b) => a.pct.compareTo(b.pct));

    if (mounted) {
      setState(() {
        classesByDow      = dowCounts;
        studentAttendances = sortedAtts;
        groupAttendances   = sortedGroups;
        _allGroups         = sortedGroups;
        topAbsentees       = sortedBottom.take(8).toList();
        totalStudents      = atts.length;
        totalClasses       = classDocs.length;
        totalGroups        = groups.length;
        goodCount          = atts.where((a) => a.pct >= 75).length;
        atRiskCount        = atts.where((a) => a.pct >= 50 && a.pct < 75).length;
        criticalCount      = atts.where((a) => a.pct < 50).length;
        _isLoading         = false;
      });
    }
  }

  // ── Filtered student list by selected group ──────────────────
  List<_StudentAtt> get _filteredStudents {
    if (_selectedGroupId == null) return studentAttendances;
    return studentAttendances
        .where((s) => s.group == _selectedGroupId)
        .toList();
  }

  // ── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : totalStudents == 0
              ? _buildEmpty()
              : Column(
                  children: [
                    _buildHeader(),
                    _buildTabBar(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildOverviewTab(),
                          _buildStudentsTab(),
                          _buildGroupsTab(),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF4F6EF7).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bar_chart_rounded,
                  color: Color(0xFF4F6EF7), size: 40),
            ),
            const SizedBox(height: 20),
            const Text('No data yet',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1F3C))),
            const SizedBox(height: 8),
            const Text(
              'No groups or students have been assigned to you yet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF8A9BB5), fontSize: 14),
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      decoration: const BoxDecoration(color: Color(0xFFF4F6FB)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F6EF7).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.bar_chart_rounded,
                    color: Color(0xFF4F6EF7), size: 22),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('My Analytics',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1F3C))),
                  Text('Your groups & students',
                      style:
                          TextStyle(fontSize: 12, color: Color(0xFF8A9BB5))),
                ],
              ),
              const Spacer(),
              GestureDetector(
                onTap: _loadData,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 6)
                    ],
                  ),
                  child: const Icon(Icons.refresh_rounded,
                      color: Color(0xFF4F6EF7), size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatChip(
                  label: 'My Students',
                  value: '$totalStudents',
                  icon: Icons.groups_rounded,
                  color: const Color(0xFF4F6EF7)),
              const SizedBox(width: 8),
              _StatChip(
                  label: 'Classes',
                  value: '$totalClasses',
                  icon: Icons.class_rounded,
                  color: const Color(0xFF22C55E)),
              const SizedBox(width: 8),
              _StatChip(
                  label: 'My Groups',
                  value: '$totalGroups',
                  icon: Icons.folder_shared_rounded,
                  color: const Color(0xFFF59E0B)),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // ── Tab Bar ──────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      color: const Color(0xFFF4F6FB),
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF4F6EF7),
        unselectedLabelColor: const Color(0xFF8A9BB5),
        indicatorColor: const Color(0xFF4F6EF7),
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle:
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Students'),
          Tab(text: 'Groups'),
        ],
      ),
    );
  }

  // ── OVERVIEW TAB ─────────────────────────────────────────────
  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
              title: 'Attendance Distribution',
              icon: Icons.pie_chart_rounded),
          const SizedBox(height: 12),
          _AttendancePieCard(
            good: goodCount,
            atRisk: atRiskCount,
            critical: criticalCount,
          ),
          const SizedBox(height: 20),
          _SectionTitle(
              title: 'Classes by Day of Week',
              icon: Icons.calendar_today_rounded),
          const SizedBox(height: 12),
          _ClassesByDowChart(counts: classesByDow),
          const SizedBox(height: 20),
          _SectionTitle(
              title: 'Lowest Attendance',
              icon: Icons.warning_amber_rounded),
          const SizedBox(height: 12),
          if (topAbsentees.isEmpty)
            const _EmptyState(message: 'No attendance data yet')
          else
            ...topAbsentees.map((s) => _AttendanceListTile(att: s)),
        ],
      ),
    );
  }

  // ── STUDENTS TAB ─────────────────────────────────────────────
  Widget _buildStudentsTab() {
    final filtered = _filteredStudents;
    return Column(
      children: [
        // Group filter chips
        if (_allGroups.length > 1)
          _buildGroupFilterRow(),
        Expanded(
          child: filtered.isEmpty
              ? const _EmptyState(message: 'No student data')
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionTitle(
                          title: 'Student Attendance',
                          icon: Icons.bar_chart_rounded),
                      const SizedBox(height: 12),
                      _StudentBarChart(students: filtered),
                      const SizedBox(height: 20),
                      _SectionTitle(
                          title: 'All Students',
                          icon: Icons.list_rounded),
                      const SizedBox(height: 12),
                      ...filtered.map((s) =>
                          _AttendanceListTile(att: s, showGroup: true)),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildGroupFilterRow() {
    return Container(
      color: const Color(0xFFF4F6FB),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterChip(
              label: 'All Groups',
              selected: _selectedGroupId == null,
              onTap: () => setState(() => _selectedGroupId = null),
            ),
            const SizedBox(width: 8),
            ..._allGroups.map((g) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _FilterChip(
                    label: g.name,
                    selected: _selectedGroupId == g.id,
                    onTap: () =>
                        setState(() => _selectedGroupId = g.id),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  // ── GROUPS TAB ───────────────────────────────────────────────
  Widget _buildGroupsTab() {
    if (groupAttendances.isEmpty) {
      return const _EmptyState(message: 'No group data');
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
              title: 'Average Attendance per Group',
              icon: Icons.groups_rounded),
          const SizedBox(height: 12),
          _GroupBarChart(groups: groupAttendances),
          const SizedBox(height: 20),
          _SectionTitle(
              title: 'Group Breakdown',
              icon: Icons.list_alt_rounded),
          const SizedBox(height: 12),
          ...groupAttendances.map((g) => _GroupTile(group: g)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────────────────────

class _StudentAtt {
  final String id, name, group;
  final double pct;
  final int attended, total;
  const _StudentAtt({
    required this.id,
    required this.name,
    required this.group,
    required this.pct,
    required this.attended,
    required this.total,
  });
}

class _GroupAtt {
  final String id, name;
  final double avgPct;
  final int studentCount;
  final int classCount;
  const _GroupAtt({
    required this.id,
    required this.name,
    required this.avgPct,
    required this.studentCount,
    required this.classCount,
  });
}

// ─────────────────────────────────────────────────────────────
// REUSABLE WIDGETS
// ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Text(message,
            style: const TextStyle(color: Color(0xFF8A9BB5), fontSize: 14)),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF4F6EF7)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05), blurRadius: 4)
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF8A9BB5),
            fontWeight:
                selected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF4F6EF7)),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF1A1F3C))),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04), blurRadius: 6)
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: color)),
            Text(label,
                style: const TextStyle(
                    color: Color(0xFF8A9BB5), fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

// ── Attendance Pie Chart ─────────────────────────────────────
class _AttendancePieCard extends StatelessWidget {
  final int good, atRisk, critical;
  const _AttendancePieCard({
    required this.good,
    required this.atRisk,
    required this.critical,
  });

  @override
  Widget build(BuildContext context) {
    final total = good + atRisk + critical;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: total == 0
          ? const Center(child: Text('No data yet'))
          : Column(
              children: [
                SizedBox(
                  height: 200,
                  child: CustomPaint(
                    painter: _PieChartPainter(
                      sections: [
                        _PieSection(
                            value: good.toDouble(),
                            color: const Color(0xFF22C55E)),
                        _PieSection(
                            value: atRisk.toDouble(),
                            color: const Color(0xFFF59E0B)),
                        _PieSection(
                            value: critical.toDouble(),
                            color: const Color(0xFFEF4444)),
                      ],
                      total: total.toDouble(),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('$total',
                              style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1F3C))),
                          const Text('students',
                              style: TextStyle(
                                  color: Color(0xFF8A9BB5),
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _PieLegend(
                        color: const Color(0xFF22C55E),
                        label: 'Good (≥75%)',
                        count: good),
                    _PieLegend(
                        color: const Color(0xFFF59E0B),
                        label: 'At Risk',
                        count: atRisk),
                    _PieLegend(
                        color: const Color(0xFFEF4444),
                        label: 'Critical',
                        count: critical),
                  ],
                ),
              ],
            ),
    );
  }
}

class _PieLegend extends StatelessWidget {
  final Color color;
  final String label;
  final int count;
  const _PieLegend(
      {required this.color, required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 10,
                height: 10,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFF8A9BB5))),
          ],
        ),
        const SizedBox(height: 4),
        Text('$count',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: color)),
      ],
    );
  }
}

// ── Pie Painter ──────────────────────────────────────────────
class _PieSection {
  final double value;
  final Color color;
  const _PieSection({required this.value, required this.color});
}

class _PieChartPainter extends CustomPainter {
  final List<_PieSection> sections;
  final double total;
  const _PieChartPainter({required this.sections, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 10;
    const innerRadius = 0.55;

    double startAngle = -math.pi / 2;
    for (final section in sections) {
      if (section.value == 0) continue;
      final sweep = (section.value / total) * 2 * math.pi;
      final paint = Paint()
        ..color = section.color
        ..style = PaintingStyle.fill;

      final path = Path()
        ..moveTo(
          center.dx + radius * innerRadius * math.cos(startAngle),
          center.dy + radius * innerRadius * math.sin(startAngle),
        )
        ..arcTo(
          Rect.fromCircle(center: center, radius: radius * innerRadius),
          startAngle, sweep, false,
        )
        ..lineTo(
          center.dx + radius * math.cos(startAngle + sweep),
          center.dy + radius * math.sin(startAngle + sweep),
        )
        ..arcTo(
          Rect.fromCircle(center: center, radius: radius),
          startAngle + sweep, -sweep, false,
        )
        ..close();

      canvas.drawPath(path, paint);
      final gapPaint = Paint()
        ..color = const Color(0xFFF4F6FB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawPath(path, gapPaint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ── Classes by Day of Week ────────────────────────────────────
class _ClassesByDowChart extends StatelessWidget {
  final List<int> counts;
  const _ClassesByDowChart({required this.counts});

  @override
  Widget build(BuildContext context) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final maxVal = counts.reduce(math.max).clamp(1, 9999);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final heightRatio = counts[i] / maxVal;
                const barColor = Color(0xFF4F6EF7);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (counts[i] > 0)
                          Text('${counts[i]}',
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF4F6EF7),
                                  fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration:
                              Duration(milliseconds: 400 + i * 60),
                          curve: Curves.easeOut,
                          height: heightRatio * 110,
                          decoration: BoxDecoration(
                            color: barColor
                                .withOpacity(0.2 + heightRatio * 0.8),
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(7, (i) {
              return Expanded(
                child: Text(days[i],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF8A9BB5))),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ── Student Bar Chart ─────────────────────────────────────────
class _StudentBarChart extends StatelessWidget {
  final List<_StudentAtt> students;
  const _StudentBarChart({required this.students});

  @override
  Widget build(BuildContext context) {
    final display = students.take(10).toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            display.length < students.length
                ? 'Top ${display.length} students (highest first)'
                : 'All ${display.length} students',
            style: const TextStyle(
                fontSize: 12, color: Color(0xFF8A9BB5)),
          ),
          const SizedBox(height: 14),
          ...display.map((s) {
            final color = s.pct >= 75
                ? const Color(0xFF22C55E)
                : s.pct >= 50
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFFEF4444);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      s.name.length > 10
                          ? '${s.name.substring(0, 9)}…'
                          : s.name,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF1A1F3C)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: s.pct / 100,
                        backgroundColor: color.withOpacity(0.12),
                        valueColor: AlwaysStoppedAnimation(color),
                        minHeight: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '${s.pct.toStringAsFixed(0)}%',
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Group Bar Chart ───────────────────────────────────────────
class _GroupBarChart extends StatelessWidget {
  final List<_GroupAtt> groups;
  const _GroupBarChart({required this.groups});

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) return const SizedBox.shrink();
    final maxVal =
        groups.map((g) => g.avgPct).reduce(math.max).clamp(1.0, 100.0);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: groups.map((g) {
                final heightRatio = g.avgPct / maxVal;
                final color = g.avgPct >= 75
                    ? const Color(0xFF22C55E)
                    : g.avgPct >= 50
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFFEF4444);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${g.avgPct.toStringAsFixed(0)}%',
                          style: TextStyle(
                              fontSize: 10,
                              color: color,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOut,
                          height: heightRatio * 120,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: groups.map((g) {
              return Expanded(
                child: Text(
                  g.name.length > 6 ? g.name.substring(0, 6) : g.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 10, color: Color(0xFF8A9BB5)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Attendance List Tile ──────────────────────────────────────
class _AttendanceListTile extends StatelessWidget {
  final _StudentAtt att;
  final bool showGroup;
  const _AttendanceListTile(
      {required this.att, this.showGroup = false});

  Color get _color {
    if (att.pct >= 75) return const Color(0xFF22C55E);
    if (att.pct >= 50) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  String get _label {
    if (att.pct >= 75) return 'Good';
    if (att.pct >= 50) return 'At Risk';
    return 'Critical';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04), blurRadius: 6)
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: _color.withOpacity(0.12),
            child: Text(
              att.name.isNotEmpty ? att.name[0].toUpperCase() : '?',
              style: TextStyle(
                  color: _color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(att.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Color(0xFF1A1F3C))),
                    ),
                    if (showGroup)
                      Text(att.group,
                          style: const TextStyle(
                              color: Color(0xFF8A9BB5), fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: att.pct / 100,
                    backgroundColor: _color.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation(_color),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${att.attended}/${att.total} classes',
                  style: const TextStyle(
                      color: Color(0xFF8A9BB5), fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${att.pct.toStringAsFixed(0)}%',
                style: TextStyle(
                    color: _color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(_label,
                    style: TextStyle(
                        color: _color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Group Tile ────────────────────────────────────────────────
class _GroupTile extends StatelessWidget {
  final _GroupAtt group;
  const _GroupTile({required this.group});

  Color get _color {
    if (group.avgPct >= 75) return const Color(0xFF22C55E);
    if (group.avgPct >= 50) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04), blurRadius: 6)
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child:
                Icon(Icons.groups_rounded, color: _color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(group.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF1A1F3C))),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: group.avgPct / 100,
                    backgroundColor: _color.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation(_color),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${group.studentCount} students · ${group.classCount} classes',
                  style: const TextStyle(
                      color: Color(0xFF8A9BB5), fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Text(
            '${group.avgPct.toStringAsFixed(1)}%',
            style: TextStyle(
                color: _color,
                fontWeight: FontWeight.bold,
                fontSize: 18),
          ),
        ],
      ),
    );
  }
}