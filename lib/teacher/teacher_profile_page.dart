import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'teacher_leave_requests_page.dart';
import '../login_page.dart';

class TeacherProfilePage extends StatefulWidget {
  const TeacherProfilePage({super.key});

  @override
  State<TeacherProfilePage> createState() => _TeacherProfilePageState();
}

class _TeacherProfilePageState extends State<TeacherProfilePage> {
  String name = '', email = '', department = '', teacherId = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTeacherData();
  }

  Future<void> _fetchTeacherData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final doc = await FirebaseFirestore.instance.collection('teachers').doc(uid).get();
      if (doc.exists) {
        setState(() {
          name = doc['name'] ?? '';
          email = doc['email'] ?? '';
          department = doc['department'] ?? '';
          teacherId = doc['teacherId'] ?? '';
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // ── Profile Hero ───────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(top: 56, bottom: 28, left: 24, right: 24),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1A1F3C),
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
                    ),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                color: const Color(0xFF4F6EF7),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withOpacity(0.2), width: 3),
                              ),
                              child: Center(
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : 'T',
                                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: GestureDetector(
                                onTap: () {},
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF22C55E),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFF1A1F3C), width: 2),
                                  ),
                                  child: const Icon(Icons.edit_rounded, color: Colors.white, size: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        const Text('Teacher', style: TextStyle(color: Color(0xFF8A9BB5), fontSize: 13)),
                        const SizedBox(height: 12),
                        if (teacherId.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4F6EF7).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(teacherId, style: const TextStyle(color: Color(0xFF4F6EF7), fontWeight: FontWeight.w600, fontSize: 13)),
                          ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // ── Info Card ──────────────────────────
                        _SectionCard(
                          children: [
                            _InfoRow(icon: Icons.email_outlined, label: 'Email', value: email),
                            const _Divider(),
                            _InfoRow(icon: Icons.school_rounded, label: 'Department', value: department.isNotEmpty ? department : 'Not set'),
                            const _Divider(),
                            _InfoRow(icon: Icons.badge_rounded, label: 'Teacher ID', value: teacherId.isNotEmpty ? teacherId : 'Not set'),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // ── Actions Card ───────────────────────
                        _SectionCard(
                          children: [
                            _ActionTile(
                              icon: Icons.assignment_outlined,
                              label: 'Leave Requests',
                              color: const Color(0xFF4F6EF7),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const TeacherLeaveRequestsPage()),
                              ),
                            ),
                            const _Divider(),
                            _ActionTile(
                              icon: Icons.lock_outline_rounded,
                              label: 'Change Password',
                              color: const Color(0xFF1A1F3C),
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Coming soon')),
                                );
                              },
                            ),
                            const _Divider(),
                            _ActionTile(
                              icon: Icons.notifications_outlined,
                              label: 'Notifications',
                              color: const Color(0xFF1A1F3C),
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Coming soon')),
                                );
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // ── Logout ─────────────────────────────
                        GestureDetector(
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
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withOpacity(0.07),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.2)),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 20),
                                SizedBox(width: 10),
                                Text('Sign Out', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w600, fontSize: 15)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF4F6EF7).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF4F6EF7), size: 18),
          ),
          const SizedBox(width: 14),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF1A1F3C), fontSize: 14)),
          const Spacer(),
          Text(value, style: const TextStyle(color: Color(0xFF8A9BB5), fontSize: 14)),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 14),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500, fontSize: 14)),
            const Spacer(),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade300, size: 20),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, color: Color(0xFFF0F2F8), indent: 44);
  }
}
