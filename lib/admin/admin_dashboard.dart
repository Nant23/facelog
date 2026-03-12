import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'admin_students_page.dart';
import 'add_classroom_page.dart';
import 'create_subject_page.dart';
import 'add_teacher_page.dart';
import '../login_page.dart';

/// =====================================================
/// ADMIN DASHBOARD — Main entry point with Drawer nav
/// =====================================================
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.dashboard_rounded, label: 'Dashboard'),
    _NavItem(icon: Icons.groups_rounded, label: 'Students'),
    _NavItem(icon: Icons.class_rounded, label: 'Classrooms'),
    _NavItem(icon: Icons.menu_book_rounded, label: 'Subjects'),
    _NavItem(icon: Icons.person_add_rounded, label: 'Teachers'),
  ];

  // Index 0 = overview home, rest map to pages
  final List<Widget> _pages = [
    const _AdminHomePage(),
    const AdminStudentsPage(),
    const AddClassroomPage(),
    const CreateSubjectPage(),
    AddTeacherPage(),
  ];

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
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF4F6EF7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.face_retouching_natural, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'FaceLog Admin',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
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
      drawer: Drawer(
        backgroundColor: const Color(0xFF1A1F3C),
        child: Column(
          children: [
            const SizedBox(height: 60),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F6EF7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.face_retouching_natural, color: Colors.white, size: 34),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Admin Panel',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'admin@facelog.app',
                    style: TextStyle(color: Color(0xFF8A9BB5), fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Divider(color: Color(0xFF2A3060), thickness: 1),
            const SizedBox(height: 10),
            // Nav Items
            Expanded(
              child: ListView.builder(
                itemCount: _navItems.length,
                itemBuilder: (context, index) {
                  final item = _navItems[index];
                  final isSelected = _currentIndex == index;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          setState(() => _currentIndex = index);
                          Navigator.pop(context);
                        },
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
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ]
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
            // Logout
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Logout failed: $e')),
                      );
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
        items: _navItems,
        onTap: (i) => setState(() => _currentIndex = i),
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

// ─── Bottom Navigation ────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.currentIndex, required this.items, required this.onTap});

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
        children: List.generate(items.length, (i) {
          final selected = i == currentIndex;
          return GestureDetector(
            onTap: () => onTap(i),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF4F6EF7).withOpacity(0.18) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    items[i].icon,
                    color: selected ? const Color(0xFF4F6EF7) : const Color(0xFF8A9BB5),
                    size: 22,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    items[i].label,
                    style: TextStyle(
                      color: selected ? const Color(0xFF4F6EF7) : const Color(0xFF8A9BB5),
                      fontSize: 10,
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
  const _AdminHomePage();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting
          Text(
            'Good morning, Admin 👋',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1F3C),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Here\'s what\'s happening today',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const SizedBox(height: 24),

          // Stats Row
          Row(
            children: const [
              Expanded(child: _StatCard(label: 'Students', value: '—', icon: Icons.groups_rounded, color: Color(0xFF4F6EF7))),
              SizedBox(width: 14),
              Expanded(child: _StatCard(label: 'Teachers', value: '—', icon: Icons.person_rounded, color: Color(0xFF22C55E))),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: const [
              Expanded(child: _StatCard(label: 'Classes Today', value: '—', icon: Icons.class_rounded, color: Color(0xFFF59E0B))),
              SizedBox(width: 14),
              Expanded(child: _StatCard(label: 'Subjects', value: '—', icon: Icons.menu_book_rounded, color: Color(0xFFEC4899))),
            ],
          ),

          const SizedBox(height: 28),

          // Quick Actions
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1F3C)),
          ),
          const SizedBox(height: 14),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 2.2,
            children: [
              _QuickAction(icon: Icons.person_add_rounded, label: 'Add Teacher', color: const Color(0xFF4F6EF7), onTap: () => _navigate(context, 4)),
              _QuickAction(icon: Icons.class_rounded, label: 'Add Class', color: const Color(0xFF22C55E), onTap: () => _navigate(context, 2)),
              _QuickAction(icon: Icons.menu_book_rounded, label: 'New Subject', color: const Color(0xFFF59E0B), onTap: () => _navigate(context, 3)),
              _QuickAction(icon: Icons.groups_rounded, label: 'Students', color: const Color(0xFFEC4899), onTap: () => _navigate(context, 1)),
            ],
          ),

          const SizedBox(height: 28),

          const Text(
            'System Overview',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1F3C)),
          ),
          const SizedBox(height: 14),
          _InfoCard(
            icon: Icons.info_outline_rounded,
            title: 'Attendance Tracking Active',
            subtitle: 'Face recognition is running for enrolled classes.',
            color: const Color(0xFF4F6EF7),
          ),
          const SizedBox(height: 10),
          _InfoCard(
            icon: Icons.shield_rounded,
            title: 'Admin Access',
            subtitle: 'You have full access to manage students, teachers, and classes.',
            color: const Color(0xFF22C55E),
          ),
        ],
      ),
    );
  }

  void _navigate(BuildContext context, int index) {
    // Find ancestor AdminDashboard state and switch tab
    final state = context.findAncestorStateOfType<_AdminDashboardState>();
    state?.setState(() => state._currentIndex = index);
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
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
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1F3C))),
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
        ],
      ),
    );
  }
}

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

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  const _InfoCard({required this.icon, required this.title, required this.subtitle, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1A1F3C))),
                const SizedBox(height: 3),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
