import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditStudentPage extends StatefulWidget {
  final String studentId;
  const EditStudentPage({super.key, required this.studentId});

  @override
  State<EditStudentPage> createState() => _EditStudentPageState();
}

class _EditStudentPageState extends State<EditStudentPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _selectedDepartmentCode;
  String? _selectedGroup;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    final doc = await _firestore.collection('students').doc(widget.studentId).get();
    final data = doc.data()!;
    setState(() {
      _nameController.text = data['name'];
      _selectedDepartmentCode = data['department'];
      _selectedGroup = data['group'];
      _isLoading = false;
    });
  }

  Future<void> _updateStudent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final studentRef = _firestore.collection('students').doc(widget.studentId);
      final oldDoc = await studentRef.get();
      final oldGroupId = oldDoc['group'];
      final newGroupId = _selectedGroup;

      final batch = _firestore.batch();

      batch.update(studentRef, {
        'name': _nameController.text.trim(),
        'department': _selectedDepartmentCode,
        'group': newGroupId,
      });

      if (oldGroupId != newGroupId) {
        batch.update(_firestore.collection('groups').doc(oldGroupId), {
          'students': FieldValue.arrayRemove([widget.studentId]),
        });
        batch.update(_firestore.collection('groups').doc(newGroupId), {
          'students': FieldValue.arrayUnion([widget.studentId]),
        });
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text('Student updated successfully'),
            ]),
            backgroundColor: const Color(0xFF22C55E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1F3C),
        foregroundColor: Colors.white,
        title: const Text('Edit Student'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name Field
              const Text('Student Name', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF8A9BB5))),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Enter full name',
                  prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFF8A9BB5)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF4F6EF7), width: 2),
                  ),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Name is required' : null,
              ),

              const SizedBox(height: 20),

              // Department Dropdown
              const Text('Department', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF8A9BB5))),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('departments').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                  return DropdownButtonFormField<String>(
                    value: _selectedDepartmentCode,
                    decoration: InputDecoration(
                      hintText: 'Select Department',
                      prefixIcon: const Icon(Icons.school_rounded, color: Color(0xFF8A9BB5)),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF4F6EF7), width: 2),
                      ),
                    ),
                    items: snapshot.data!.docs.map((doc) {
                      return DropdownMenuItem<String>(
                        value: doc['code'],
                        child: Text(doc['name']),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() {
                      _selectedDepartmentCode = value;
                      _selectedGroup = null;
                    }),
                    validator: (v) => v == null ? 'Select a department' : null,
                  );
                },
              ),

              const SizedBox(height: 20),

              // Group Dropdown (filtered)
              if (_selectedDepartmentCode != null) ...[
                const Text('Group', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF8A9BB5))),
                const SizedBox(height: 8),
                StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('groups')
                      .where('departmentId', isEqualTo: _selectedDepartmentCode)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                    return DropdownButtonFormField<String>(
                      value: _selectedGroup,
                      decoration: InputDecoration(
                        hintText: 'Select Group',
                        prefixIcon: const Icon(Icons.groups_rounded, color: Color(0xFF8A9BB5)),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF4F6EF7), width: 2),
                        ),
                      ),
                      items: snapshot.data!.docs.map((doc) {
                        return DropdownMenuItem<String>(
                          value: doc.id,
                          child: Text(doc['name']),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedGroup = value),
                      validator: (v) => v == null ? 'Select a group' : null,
                    );
                  },
                ),
                const SizedBox(height: 30),
              ] else
                const SizedBox(height: 30),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _updateStudent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F6EF7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save_rounded),
                            SizedBox(width: 8),
                            Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
