import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class AddTeacherPage extends StatefulWidget {
  AddTeacherPage({super.key});

  @override
  State<AddTeacherPage> createState() => _AddTeacherPageState();
}

class _AddTeacherPageState extends State<AddTeacherPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscurePassword = true;

  // Department selection — stores the department code e.g. "cs"
  String? _selectedDepartmentCode;

  // Groups multi-selection — stores group doc IDs e.g. ["cs_2022_a", "cs_2026_b"]
  final List<String> _selectedGroups = [];

  void _resetForm() {
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
    setState(() {
      _selectedDepartmentCode = null;
      _selectedGroups.clear();
    });
  }

  Future<void> _addTeacher() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDepartmentCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a department'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final secondaryApp = await Firebase.initializeApp(
        name: 'secondaryApp',
        options: Firebase.app().options,
      );

      final credential = await FirebaseAuth.instanceFor(app: secondaryApp)
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final uid = credential.user!.uid;

      await FirebaseAuth.instanceFor(app: secondaryApp).signOut();
      await secondaryApp.delete();

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'email': _emailController.text.trim(),
        'name': _nameController.text.trim(),
        'role': 'teacher',
        'createdAt': FieldValue.serverTimestamp(),
      });

      final snapshot = await FirebaseFirestore.instance.collection('teachers').get();
      final teacherId = 'TCH${(snapshot.docs.length + 1).toString().padLeft(3, '0')}';

      await FirebaseFirestore.instance.collection('teachers').doc(uid).set({
        'teacherId': teacherId,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'department': _selectedDepartmentCode,
        'groups_taken': _selectedGroups,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 10),
              Text('Teacher "${_nameController.text.trim()}" added!'),
            ]),
            backgroundColor: const Color(0xFF22C55E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        _resetForm();
      }
    } on FirebaseAuthException catch (e) {
      try { await Firebase.app('secondaryApp').delete(); } catch (_) {}
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Error adding teacher'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Department Dropdown ────────────────────────────────────────────────────
  Widget _buildDepartmentDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('departments').snapshots(),
      builder: (context, snapshot) {
        final departments = snapshot.data?.docs ?? [];

        return DropdownButtonFormField<String>(
          value: _selectedDepartmentCode,
          decoration: InputDecoration(
            labelText: 'Department',
            prefixIcon: const Icon(Icons.school_outlined, color: Color(0xFF8A9BB5)),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF4F6EF7), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
          ),
          hint: snapshot.connectionState == ConnectionState.waiting
              ? const Text('Loading...')
              : const Text('Select department'),
          items: departments.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final code = data['code'] as String? ?? doc.id;
            final name = data['name'] as String? ?? doc.id;
            return DropdownMenuItem<String>(
              value: code,
              child: Text('$name  ($code)'),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedDepartmentCode = value;
              // Clear groups when department changes
              _selectedGroups.clear();
            });
          },
          validator: (v) => v == null ? 'Please select a department' : null,
        );
      },
    );
  }

  // ─── Groups Multi-Select ────────────────────────────────────────────────────
  Widget _buildGroupsSelector() {
    // Placeholder when no department is selected
    if (_selectedDepartmentCode == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.group_outlined, color: Colors.grey.shade400, size: 20),
            const SizedBox(width: 10),
            Text(
              'Select a department to see groups',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('groups')
          .where('departmentId', isEqualTo: _selectedDepartmentCode)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final groups = snapshot.data?.docs ?? [];

        if (groups.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.group_off_outlined, color: Colors.grey.shade400, size: 20),
                const SizedBox(width: 10),
                Text(
                  'No groups found for this department',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                ),
              ],
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                child: Row(
                  children: [
                    const Icon(Icons.group_outlined, color: Color(0xFF8A9BB5), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Assign Groups',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    if (_selectedGroups.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F6EF7).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_selectedGroups.length} selected',
                          style: const TextStyle(
                            color: Color(0xFF4F6EF7),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Group rows
              ...groups.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final groupId = doc.id;
                final groupName = data['name'] as String? ?? groupId;
                final year = data['year']?.toString() ?? '';
                final isSelected = _selectedGroups.contains(groupId);

                return InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedGroups.remove(groupId);
                      } else {
                        _selectedGroups.add(groupId);
                      }
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    child: Row(
                      children: [
                        // Animated checkbox
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF4F6EF7) : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF4F6EF7) : Colors.grey.shade300,
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, color: Colors.white, size: 14)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        // Group name
                        Expanded(
                          child: Text(
                            groupName,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: isSelected ? const Color(0xFF1A1F3C) : Colors.grey.shade700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        // Year badge
                        if (year.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              year,
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F6EF7), Color(0xFF7B94FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.person_add_rounded, color: Colors.white, size: 28),
                    ),
                    SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add New Teacher',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Creates a login account for the teacher',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),
              const Text(
                'Teacher Details',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A1F3C)),
              ),
              const SizedBox(height: 14),

              // Full Name
              _buildField(
                controller: _nameController,
                label: 'Full Name',
                icon: Icons.person_outline_rounded,
                validator: (v) => (v == null || v.isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 14),

              // Email
              _buildField(
                controller: _emailController,
                label: 'Email Address',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Email is required';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Password
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Temporary Password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF8A9BB5)),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: const Color(0xFF8A9BB5),
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF4F6EF7), width: 2),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Password is required';
                  if (v.length < 6) return 'At least 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Department dropdown (live from Firestore)
              _buildDepartmentDropdown(),
              const SizedBox(height: 14),

              // Groups multi-select (filtered by selected department)
              _buildGroupsSelector(),
              const SizedBox(height: 14),

              // Info note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F6EF7).withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF4F6EF7).withOpacity(0.15)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: Color(0xFF4F6EF7), size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'The teacher will use this email & password to log in. Ask them to change the password after first login.',
                        style: TextStyle(color: Color(0xFF4F6EF7), fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _addTeacher,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F6EF7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_add_rounded),
                            SizedBox(width: 8),
                            Text('Add Teacher', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 30),

              // Existing teachers list
              const Text(
                'Current Teachers',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A1F3C)),
              ),
              const SizedBox(height: 12),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('teachers').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  if (snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text('No teachers yet', style: TextStyle(color: Colors.grey.shade400)),
                    );
                  }

                  return Column(
                    children: snapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final groups = List<String>.from(data['groups_taken'] ?? []);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: const Color(0xFF22C55E).withOpacity(0.12),
                              child: Text(
                                (data['name'] ?? '?')[0].toUpperCase(),
                                style: const TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(data['name'] ?? '—', style: const TextStyle(fontWeight: FontWeight.w600)),
                                  Text(
                                    data['email'] ?? '—',
                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                  ),
                                  if (groups.isNotEmpty) ...[
                                    const SizedBox(height: 5),
                                    Wrap(
                                      spacing: 4,
                                      runSpacing: 4,
                                      children: groups
                                          .map((g) => Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF4F6EF7).withOpacity(0.08),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  g,
                                                  style: const TextStyle(fontSize: 10, color: Color(0xFF4F6EF7)),
                                                ),
                                              ))
                                          .toList(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF22C55E).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    data['teacherId'] ?? '—',
                                    style: const TextStyle(
                                      color: Color(0xFF22C55E),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                if (data['department'] != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    data['department'].toString().toUpperCase(),
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF8A9BB5)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF4F6EF7), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
      ),
      validator: validator,
    );
  }
}