import 'package:flutter/material.dart';
import 'student_home.dart';
import 'student_attendance_request.dart';
import 'student_reports_page.dart';
import 'student_profile_page.dart';

class StudentMainPage extends StatefulWidget {
  const StudentMainPage({super.key});

  @override
  State<StudentMainPage> createState() => _StudentMainPageState();
}

class _StudentMainPageState extends State<StudentMainPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    StudentHome(),
    AttendanceRequestPage(),
    StudentReportsPage(),
    StudentProfilePage(),
  ];

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.dashboard_rounded, label: 'Home'),
    _NavItem(icon: Icons.how_to_reg_rounded, label: 'Request'),
    _NavItem(icon: Icons.bar_chart_rounded, label: 'Reports'),
    _NavItem(icon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: KeyedSubtree(
          key: ValueKey(_currentIndex),
          child: _pages[_currentIndex],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1F3C),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(color: Color(0x33000000), blurRadius: 20, offset: Offset(0, -4)),
          ],
        ),
        padding: const EdgeInsets.only(top: 10, bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_navItems.length, (i) {
            final selected = i == _currentIndex;
            return GestureDetector(
              onTap: () => setState(() => _currentIndex = i),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF4F6EF7).withOpacity(0.18)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _navItems[i].icon,
                      color: selected
                          ? const Color(0xFF4F6EF7)
                          : const Color(0xFF8A9BB5),
                      size: 22,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _navItems[i].label,
                      style: TextStyle(
                        color: selected
                            ? const Color(0xFF4F6EF7)
                            : const Color(0xFF8A9BB5),
                        fontSize: 10,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
