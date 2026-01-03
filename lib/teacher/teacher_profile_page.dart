import 'package:flutter/material.dart';
import 'teacher_leave_requests_page.dart';

class TeacherProfilePage extends StatelessWidget {
  const TeacherProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          "Profile",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(Icons.edit, color: Colors.black),
          )
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            _profileHeader(),
            const SizedBox(height: 25),
            _infoCard(),
            const SizedBox(height: 20),
            _settingsCard(context),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
  // Profile Header
  // --------------------------------------------------
  Widget _profileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF478AFF), Color(0xFF6A4BFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: const [
          CircleAvatar(
            radius: 45,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.person,
              size: 50,
              color: Color(0xFF478AFF),
            ),
          ),
          SizedBox(height: 12),
          Text(
            "Ananta Gurung",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            "Teacher",
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // Information Card
  // --------------------------------------------------
  Widget _infoCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _infoRow(Icons.email, "Email", "ananta@gmail.com"),
          const Divider(),
          _infoRow(Icons.school, "Department", "Science"),
          const Divider(),
          _infoRow(Icons.badge, "Employee ID", "TCH-1021"),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // Settings & Actions
  // --------------------------------------------------
  Widget _settingsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _actionTile(
            icon: Icons.assignment_outlined,
            label: "View Leave Requests",
            color: Colors.blue,
            onTap: () {
              // Navigate to teacher leave requests page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TeacherLeaveRequestsPage(),
                ),
              );
            },
          ),
          const Divider(),
          _actionTile(
            icon: Icons.lock_outline,
            label: "Change Password",
            onTap: () {},
          ),
          const Divider(),
          _actionTile(
            icon: Icons.notifications_none,
            label: "Notifications",
            onTap: () {},
          ),
          const Divider(),
          _actionTile(
            icon: Icons.logout,
            label: "Logout",
            color: Colors.red,
            onTap: () {
              // TODO: Firebase logout
            },
          ),
        ],
      ),
    );
  }


  static Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.black54),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(color: Colors.black54),
        ),
      ],
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String label,
    Color color = Colors.black,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: TextStyle(color: color),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
