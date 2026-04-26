import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'admin_students_page.dart';
import 'add_classroom_page.dart';
import 'admin_classes_page.dart';
import 'create_subject_page.dart';
import 'add_teacher_page.dart';
import 'admin_analytics_page.dart';
import 'admin_teachers_page.dart';
import '../login_page.dart';

// ─── Index map (must stay in sync with _pages) ────────────
// 0 = Dashboard
// 1 = Students
// 2 = Analytics
// 3 = Classes
// 4 = Add Class
// 5 = Subjects
// 6 = Teachers list

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;

  // Only 4 items appear in the bottom bar
  static const List<_NavItem> _bottomNavItems = [
    _NavItem(icon: Icons.dashboard_rounded,  label: 'Dashboard'),
    _NavItem(icon: Icons.groups_rounded,     label: 'Students'),
    _NavItem(icon: Icons.bar_chart_rounded,  label: 'Analytics'),
    _NavItem(icon: Icons.class_rounded,      label: 'Classes'),
  ];

  // All items appear in the drawer — indices match _pages exactly
  static const List<_NavItem> _allNavItems = [
    _NavItem(icon: Icons.dashboard_rounded,  label: 'Dashboard'),   // 0
    _NavItem(icon: Icons.groups_rounded,     label: 'Students'),    // 1
    _NavItem(icon: Icons.bar_chart_rounded,  label: 'Analytics'),   // 2
    _NavItem(icon: Icons.class_rounded,      label: 'Classes'),     // 3
    _NavItem(icon: Icons.add_box_rounded,    label: 'Add Class'),   // 4
    _NavItem(icon: Icons.menu_book_rounded,  label: 'Subjects'),    // 5
    _NavItem(icon: Icons.person_rounded,     label: 'Teachers'),    // 6
  ];

  late final List<Widget> _pages = [
    _AdminHomePage(onNavigate: _setIndex),  // 0
    const AdminStudentsPage(),              // 1
    const AdminAnalyticsPage(),             // 2
    const AdminClassesPage(),               // 3
    const AddClassroomPage(),               // 4
    const CreateSubjectPage(),              // 5
    const AdminTeachersPage(),
    AddTeacherPage(),            // 6
  ];

  void _setIndex(int index) => setState(() => _currentIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1F3C),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              //padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 255, 255, 255),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Image.asset(
                'assets/images/facelog_logo.png',
                fit: BoxFit.fill,
                width: 30,
                height: 30,
              )
            ),
            const SizedBox(width: 10),
            const Text(
              'FaceLog Admin',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, letterSpacing: 0.3),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF4F6EF7),
              child: Text('A', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        ],
      ),
      drawer: _AppDrawer(
        currentIndex: _currentIndex,
        navItems: _allNavItems,
        onNavigate: (i) {
          _setIndex(i);
          Navigator.pop(context);
        },
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: KeyedSubtree(
          key: ValueKey(_currentIndex),
          child: _pages[_currentIndex],
        ),
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        bottomItems: _bottomNavItems,
        onTap: _setIndex,
      ),
    );
  }
}

// ─── Drawer ───────────────────────────────────────────────
class _AppDrawer extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> navItems;
  final ValueChanged<int> onNavigate;
  const _AppDrawer({required this.currentIndex, required this.navItems, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF1A1F3C),
      child: Column(
        children: [
          const SizedBox(height: 60),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                Container(
                  //padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 255, 255, 255),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.asset(
                    'assets/images/facelog_logo.png',
                    fit: BoxFit.fill,
                    width: 50,
                    height: 50,
                  )
                ),
                const SizedBox(height: 12),
                const Text('Admin Panel', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const Text('admin@facelog.app', style: TextStyle(color: Color(0xFF8A9BB5), fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Divider(color: Color(0xFF2A3060), thickness: 1),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: navItems.length,
              itemBuilder: (context, index) {
                final item = navItems[index];
                final isSelected = currentIndex == index;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => onNavigate(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF4F6EF7) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(item.icon, color: isSelected ? Colors.white : const Color(0xFF8A9BB5), size: 22),
                            const SizedBox(width: 14),
                            Text(
                              item.label,
                              style: TextStyle(
                                color: isSelected ? Colors.white : const Color(0xFF8A9BB5),
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                fontSize: 15,
                              ),
                            ),
                            if (isSelected) ...[
                              const Spacer(),
                              Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(color: Color(0xFF2A3060)),
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, bottom: 20),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  try {
                    await FirebaseAuth.instance.signOut();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                      (route) => false,
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  child: const Row(
                    children: [
                      Icon(Icons.logout_rounded, color: Color(0xFFFF6B6B), size: 22),
                      SizedBox(width: 14),
                      Text('Sign Out', style: TextStyle(color: Color(0xFFFF6B6B), fontSize: 15, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Nav Item Model ───────────────────────────────────────
class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

// ─── Bottom Navigation (4 items only) ────────────────────
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> bottomItems;
  final ValueChanged<int> onTap;
  // bottom items 0-3 map directly to global page indices 0-3
  static const _globalIndices = [0, 1, 2, 3];

  const _BottomNav({required this.currentIndex, required this.bottomItems, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1F3C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 20, offset: Offset(0, -4))],
      ),
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(bottomItems.length, (i) {
          final globalIdx = _globalIndices[i];
          final selected = currentIndex == globalIdx;
          return GestureDetector(
            onTap: () => onTap(globalIdx),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF4F6EF7).withOpacity(0.18) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(bottomItems[i].icon, color: selected ? const Color(0xFF4F6EF7) : const Color(0xFF8A9BB5), size: 23),
                  const SizedBox(height: 4),
                  Text(
                    bottomItems[i].label,
                    style: TextStyle(
                      color: selected ? const Color(0xFF4F6EF7) : const Color(0xFF8A9BB5),
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─── Admin Home Overview Page ─────────────────────────────
class _AdminHomePage extends StatelessWidget {
  final ValueChanged<int> onNavigate;
  const _AdminHomePage({required this.onNavigate});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning, Admin';
    if (hour < 17) return 'Good afternoon, Admin';
    return 'Good evening, Admin';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Greeting ──────────────────────────────────
          Text(
            _greeting(),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1F3C),
            ),
          ),
          const SizedBox(height: 4),
          Text("Here's what's happening today", style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          const SizedBox(height: 24),

          // ── Live Stat Cards ────────────────────────────
          Row(
            children: [
              Expanded(child: _LiveStatCard(
                label: 'Students',
                icon: Icons.groups_rounded,
                color: const Color(0xFF4F6EF7),
                stream: FirebaseFirestore.instance.collection('students').snapshots(),
                onTap: () => onNavigate(1),  // → Students
              )),
              const SizedBox(width: 14),
              Expanded(child: _LiveStatCard(
                label: 'Teachers',
                icon: Icons.person_rounded,
                color: const Color(0xFF22C55E),
                stream: FirebaseFirestore.instance.collection('teachers').snapshots(),
                onTap: () => onNavigate(6),  // → Teachers list
              )),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _TodayClassesStatCard(onTap: () => onNavigate(3))),  // → Classes
              const SizedBox(width: 14),
              Expanded(child: _LiveStatCard(
                label: 'Subjects',
                icon: Icons.menu_book_rounded,
                color: const Color(0xFFEC4899),
                stream: FirebaseFirestore.instance.collection('subjects').snapshots(),
                onTap: () => onNavigate(5),  // → Subjects
              )),
            ],
          ),

          const SizedBox(height: 28),

          // ── Quick Actions ──────────────────────────────
          const Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1F3C))),
          const SizedBox(height: 14),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 2.2,
            children: [
              // Pushes directly to AddTeacherPage as a new screen
              _QuickAction(
                icon: Icons.person_add_rounded,
                label: 'Add Teacher',
                color: const Color(0xFF4F6EF7),
                onTap: () => onNavigate(7)
              ),
              _QuickAction(
                icon: Icons.add_box_rounded,
                label: 'Schedule Class',
                color: const Color(0xFF22C55E),
                onTap: () => onNavigate(4),  // → Add Class
              ),
              _QuickAction(
                icon: Icons.menu_book_rounded,
                label: 'New Subject',
                color: const Color(0xFFF59E0B),
                onTap: () => onNavigate(5),  // → Subjects
              ),
              _QuickAction(
                icon: Icons.groups_rounded,
                label: 'View Students',
                color: const Color(0xFFEC4899),
                onTap: () => onNavigate(1),  // → Students
              ),
            ],
          ),

          const SizedBox(height: 28),

          // ── Today's Classes Live Feed ──────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Today's Classes", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1F3C))),
              GestureDetector(
                onTap: () => onNavigate(3),  // → Classes
                child: const Text('See all →', style: TextStyle(fontSize: 13, color: Color(0xFF4F6EF7), fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _TodayClassesFeed(onViewAll: () => onNavigate(3)),  // → Classes

          const SizedBox(height: 28),

          // ── At-Risk Students Alert ─────────────────────
          const Text('Attendance Alerts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1F3C))),
          const SizedBox(height: 14),
          _AttendanceAlerts(onNavigate: () => onNavigate(1)),  // → Students

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ─── Live Stat Card ───────────────────────────────────────
class _LiveStatCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Stream<QuerySnapshot> stream;
  final VoidCallback onTap;
  const _LiveStatCard({required this.label, required this.icon, required this.color, required this.stream, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snapshot) {
          final count = snapshot.hasData ? snapshot.data!.docs.length.toString() : '—';
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: color.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(count, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1F3C))),
                    Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Today's Classes Stat Card ────────────────────────────
class _TodayClassesStatCard extends StatelessWidget {
  final VoidCallback onTap;
  const _TodayClassesStatCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    return GestureDetector(
      onTap: onTap,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('classes')
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
            .where('date', isLessThan: Timestamp.fromDate(todayEnd))
            .snapshots(),
        builder: (context, snapshot) {
          final count = snapshot.hasData ? snapshot.data!.docs.length.toString() : '—';
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: const Color(0xFFF59E0B).withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFFF59E0B).withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.class_rounded, color: Color(0xFFF59E0B), size: 22),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(count, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1F3C))),
                    Text('Today', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Today's Classes Mini Feed ────────────────────────────
class _TodayClassesFeed extends StatelessWidget {
  final VoidCallback onViewAll;
  const _TodayClassesFeed({required this.onViewAll});

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
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('classes')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
          .where('date', isLessThan: Timestamp.fromDate(todayEnd))
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        var docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Icon(Icons.event_busy_rounded, color: Colors.grey.shade300, size: 32),
                const SizedBox(width: 14),
                Text('No classes scheduled for today', style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
              ],
            ),
          );
        }

        docs = [...docs]..sort((a, b) {
          final aDate = ((a.data() as Map)['date'] as Timestamp).toDate();
          final bDate = ((b.data() as Map)['date'] as Timestamp).toDate();
          return aDate.compareTo(bDate);
        });

        final preview = docs.take(3).toList();

        return Column(
          children: [
            ...preview.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final state = _getState(data);
              final classStart = (data['date'] as Timestamp).toDate();
              final attendedCount = (data['attended'] as List?)?.length ?? 0;

              final stateColor = state == 'ongoing'
                  ? const Color(0xFF22C55E)
                  : state == 'scheduled'
                      ? const Color(0xFF4F6EF7)
                      : const Color(0xFF8A9BB5);

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: state == 'ongoing'
                      ? Border.all(color: const Color(0xFF22C55E).withOpacity(0.35), width: 1.5)
                      : null,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(color: stateColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: Icon(
                        state == 'ongoing'
                            ? Icons.radio_button_checked
                            : state == 'scheduled'
                                ? Icons.schedule_rounded
                                : Icons.check_circle_rounded,
                        color: stateColor, size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['subject'] ?? '—', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1A1F3C))),
                          const SizedBox(height: 2),
                          Text(
                            '${DateFormat('HH:mm').format(classStart)}  •  Group: ${data['groupid'] ?? '—'}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: stateColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: Text(
                            state[0].toUpperCase() + state.substring(1),
                            style: TextStyle(color: stateColor, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('$attendedCount present', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                      ],
                    ),
                  ],
                ),
              );
            }),
            if (docs.length > 3)
              GestureDetector(
                onTap: onViewAll,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F6EF7).withOpacity(0.07),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '+${docs.length - 3} more classes — tap to view all',
                    style: const TextStyle(color: Color(0xFF4F6EF7), fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ─── At-Risk Attendance Alerts ────────────────────────────
class _AttendanceAlerts extends StatelessWidget {
  final VoidCallback onNavigate;
  const _AttendanceAlerts({required this.onNavigate});

  Future<List<Map<String, dynamic>>> _fetchAtRisk() async {
    final studentsSnap = await FirebaseFirestore.instance.collection('students').get();
    final classesSnap = await FirebaseFirestore.instance.collection('classes').get();
    if (classesSnap.docs.isEmpty) return [];

    final total = classesSnap.docs.length;
    List<Map<String, dynamic>> atRisk = [];

    for (final studentDoc in studentsSnap.docs) {
      final attended = classesSnap.docs.where((c) {
        final list = c['attended'] as List? ?? [];
        return list.contains(studentDoc.id);
      }).length;
      final pct = (attended / total) * 100;
      if (pct < 75) {
        atRisk.add({'name': studentDoc['name'] ?? '—', 'pct': pct, 'id': studentDoc.id});
      }
    }

    atRisk.sort((a, b) => (a['pct'] as double).compareTo(b['pct'] as double));
    return atRisk.take(4).toList();
  }

  Color _color(double pct) {
    if (pct >= 50) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchAtRisk(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
        }

        final atRisk = snapshot.data!;

        if (atRisk.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFF22C55E).withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 22),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('All students on track', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1A1F3C))),
                      SizedBox(height: 2),
                      Text('Everyone is above 75% attendance.', style: TextStyle(fontSize: 12, color: Color(0xFF8A9BB5))),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 18),
                  const SizedBox(width: 10),
                  Text(
                    '${atRisk.length} student${atRisk.length > 1 ? 's' : ''} below 75% attendance',
                    style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            ...atRisk.map((s) {
              final pct = s['pct'] as double;
              final color = _color(pct);
              return GestureDetector(
                onTap: onNavigate,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: color.withOpacity(0.12),
                        child: Text((s['name'] as String)[0].toUpperCase(),
                            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s['name'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1A1F3C))),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: pct / 100,
                                backgroundColor: color.withOpacity(0.12),
                                valueColor: AlwaysStoppedAnimation(color),
                                minHeight: 5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('${pct.toStringAsFixed(0)}%',
                          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

// ─── Quick Action Button ──────────────────────────────────
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.09),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.18)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 10),
            Flexible(child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13))),
          ],
        ),
      ),
    );
  }
}
