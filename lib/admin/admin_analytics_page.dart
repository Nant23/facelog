import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;

class AdminAnalyticsPage extends StatefulWidget {
  const AdminAnalyticsPage({super.key});

  @override
  State<AdminAnalyticsPage> createState() => _AdminAnalyticsPageState();
}

class _AdminAnalyticsPageState extends State<AdminAnalyticsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  // ── Computed data ──────────────────────────────────────────
  int totalStudents = 0;
  int totalClasses = 0;
  int totalTeachers = 0;

  // Attendance distribution: good / at-risk / critical
  int goodCount = 0;
  int atRiskCount = 0;
  int criticalCount = 0;

  // Per-student attendance list (for bar chart)
  List<_StudentAtt> studentAttendances = [];

  // Per-group average attendance
  List<_GroupAtt> groupAttendances = [];

  // Classes per day of week
  List<int> classesByDow = List.filled(7, 0); // 0=Mon … 6=Sun

  // Top absentees
  List<_StudentAtt> topAbsentees = [];

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

  // ── Data loading ────────────────────────────────────────────
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final fs = FirebaseFirestore.instance;

    final studentsSnap = await fs.collection('students').get();
    final classesSnap  = await fs.collection('classes').get();
    final teachersSnap = await fs.collection('teachers').get();
    final groupsSnap   = await fs.collection('groups').get();

    final studentDocs = studentsSnap.docs;
    final classDocs   = classesSnap.docs;

    totalStudents = studentDocs.length;
    totalClasses  = classDocs.length;
    totalTeachers = teachersSnap.docs.length;

    // ── Classes by day-of-week
    final dowCounts = List.filled(7, 0);
    for (final c in classDocs) {
      final ts = c.data()['date'];
      if (ts is Timestamp) {
        dowCounts[ts.toDate().weekday - 1]++;
      }
    }
    classesByDow = dowCounts;

    // ── Pre-build attended ID sets per class (handles both
    //    plain String IDs and DocumentReference values)
    final Map<String, Set<String>> attendedByClass = {};
    for (final c in classDocs) {
      final raw = c.data()['attended'];
      final Set<String> ids = {};
      if (raw is List) {
        for (final item in raw) {
          if (item is String) {
            ids.add(item);
          } else if (item is DocumentReference) {
            ids.add(item.id);
          }
        }
      }
      attendedByClass[c.id] = ids;
    }

    // ── Per-student attendance across ALL classes
    final List<_StudentAtt> atts = [];
    for (final s in studentDocs) {
      final data  = s.data();
      final sName = (data['name']  as String?) ?? '—';
      final sGroup = (data['group'] as String?) ?? '';

      int attended = 0;
      for (final c in classDocs) {
        if (attendedByClass[c.id]?.contains(s.id) ?? false) {
          attended++;
        }
      }

      final total = classDocs.length;
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

    goodCount     = atts.where((a) => a.pct >= 75).length;
    atRiskCount   = atts.where((a) => a.pct >= 50 && a.pct < 75).length;
    criticalCount = atts.where((a) => a.pct < 50).length;

    studentAttendances = atts..sort((a, b) => b.pct.compareTo(a.pct));

    topAbsentees = [...atts]..sort((a, b) => a.pct.compareTo(b.pct));
    if (topAbsentees.length > 8) topAbsentees = topAbsentees.sublist(0, 8);

    // ── Per-group average attendance
    final List<_GroupAtt> groups = [];
    for (final g in groupsSnap.docs) {
      final groupStudents = atts.where((a) => a.group == g.id).toList();
      final avg = groupStudents.isEmpty
          ? 0.0
          : groupStudents.map((a) => a.pct).reduce((a, b) => a + b) /
              groupStudents.length;
      final gData = g.data();
      groups.add(_GroupAtt(
        id:           g.id,
        name:         (gData['name'] as String?) ?? g.id,
        avgPct:       avg,
        studentCount: groupStudents.length,
      ));
    }
    groupAttendances = groups..sort((a, b) => b.avgPct.compareTo(a.avgPct));

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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

  // ── Header ─────────────────────────────────────────────────
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
                  Text('Analytics',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1F3C))),
                  Text('Attendance insights & trends',
                      style: TextStyle(fontSize: 12, color: Color(0xFF8A9BB5))),
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
                  label: 'Students',
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
                  label: 'Teachers',
                  value: '$totalTeachers',
                  icon: Icons.person_rounded,
                  color: const Color(0xFFF59E0B)),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // ── Tab Bar ─────────────────────────────────────────────────
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

  // ── OVERVIEW TAB ────────────────────────────────────────────
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
          ...topAbsentees.map((s) => _AttendanceListTile(att: s)),
        ],
      ),
    );
  }

  // ── STUDENTS TAB ────────────────────────────────────────────
  Widget _buildStudentsTab() {
    if (studentAttendances.isEmpty) {
      return const Center(child: Text('No student data'));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
              title: 'Student Attendance Bars',
              icon: Icons.bar_chart_rounded),
          const SizedBox(height: 12),
          _StudentBarChart(students: studentAttendances),
          const SizedBox(height: 20),
          _SectionTitle(
              title: 'All Students', icon: Icons.list_rounded),
          const SizedBox(height: 12),
          ...studentAttendances
              .map((s) => _AttendanceListTile(att: s, showGroup: true)),
        ],
      ),
    );
  }

  // ── GROUPS TAB ───────────────────────────────────────────────
  Widget _buildGroupsTab() {
    if (groupAttendances.isEmpty) {
      return const Center(child: Text('No group data'));
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
              title: 'Group Breakdown', icon: Icons.list_alt_rounded),
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
  const _GroupAtt({
    required this.id,
    required this.name,
    required this.avgPct,
    required this.studentCount,
  });
}

// ─────────────────────────────────────────────────────────────
// REUSABLE WIDGETS
// ─────────────────────────────────────────────────────────────

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
  const _PieLegend({
    required this.color,
    required this.label,
    required this.count,
  });

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

// ── Pie chart painter ────────────────────────────────────────
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
          startAngle,
          sweep,
          false,
        )
        ..lineTo(
          center.dx + radius * math.cos(startAngle + sweep),
          center.dy + radius * math.sin(startAngle + sweep),
        )
        ..arcTo(
          Rect.fromCircle(center: center, radius: radius),
          startAngle + sweep,
          -sweep,
          false,
        )
        ..close();

      canvas.drawPath(path, paint);

      // Gap between segments
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

// ── Classes by Day of Week Bar Chart ────────────────────────
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
                          Text(
                            '${counts[i]}',
                            style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF4F6EF7),
                                fontWeight: FontWeight.bold),
                          ),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: Duration(milliseconds: 400 + i * 60),
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

// ── Student Attendance Bar Chart ─────────────────────────────
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
            style:
                const TextStyle(fontSize: 12, color: Color(0xFF8A9BB5)),
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

// ── Group Bar Chart ──────────────────────────────────────────
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

// ── Attendance List Tile ─────────────────────────────────────
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
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
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

// ── Group Tile ───────────────────────────────────────────────
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
            child: Icon(Icons.groups_rounded, color: _color, size: 20),
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
                Text('${group.studentCount} students',
                    style: const TextStyle(
                        color: Color(0xFF8A9BB5), fontSize: 11)),
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