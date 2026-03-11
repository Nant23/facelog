import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AddClassroomPage extends StatefulWidget {
  const AddClassroomPage({super.key});

  @override
  State<AddClassroomPage> createState() => _AddClassroomPageState();
}

class _AddClassroomPageState extends State<AddClassroomPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? selectedGroupId;
  String? selectedSubjectId;
  String? selectedLocationId;
  String? selectedTeacherId;
  DateTime? selectedDate;
  Duration? selectedDuration;

  bool _isLoading = false;

  Future<String> _generateClassId() async {
    final snapshot = await _firestore.collection('classes').get();
    if (snapshot.docs.isEmpty) return "class001";
    List<int> numbers = snapshot.docs.map((doc) {
      return int.tryParse(doc.id.replaceAll("class", "")) ?? 0;
    }).toList()
      ..sort();
    return "class${(numbers.last + 1).toString().padLeft(3, '0')}";
  }

  Future<void> _addClass() async {
    if (selectedGroupId == null || selectedSubjectId == null ||
        selectedLocationId == null || selectedTeacherId == null ||
        selectedDate == null || selectedDuration == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.warning_amber_rounded, color: Colors.white),
            SizedBox(width: 10),
            Text('Please fill all fields'),
          ]),
          backgroundColor: const Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final classId = await _generateClassId();
      await _firestore.collection('classes').doc(classId).set({
        'attended': [],
        'date': Timestamp.fromDate(selectedDate!),
        'groupid': selectedGroupId,
        'location': selectedLocationId,
        'subject': selectedSubjectId,
        'teacherId': selectedTeacherId,
        'duration': selectedDuration!.inMinutes,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text('Class Added Successfully'),
            ]),
            backgroundColor: const Color(0xFF22C55E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        setState(() {
          selectedGroupId = null;
          selectedSubjectId = null;
          selectedLocationId = null;
          selectedTeacherId = null;
          selectedDate = null;
          selectedDuration = null;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF4F6EF7)),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF4F6EF7)),
        ),
        child: child!,
      ),
    );
    if (time == null) return;

    setState(() {
      selectedDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Widget _buildDropdown<T>({
    required String label,
    required IconData icon,
    required Stream<QuerySnapshot> stream,
    required T? selectedValue,
    required Function(T?) onChanged,
    bool useTeacherId = false,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            height: 56,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        return DropdownButtonFormField<T>(
          value: selectedValue,
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
          ),
          items: snapshot.data!.docs.map((doc) {
            return DropdownMenuItem<T>(
              value: (useTeacherId ? doc['teacherId'] : doc.id) as T,
              child: Text(doc['name']),
            );
          }).toList(),
          onChanged: onChanged,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF22C55E), Color(0xFF4ADE80)],
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
                    child: Icon(Icons.class_rounded, color: Colors.white, size: 28),
                  ),
                  SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Schedule a Class', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('Assign group, subject, teacher & time', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text('Class Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A1F3C))),
            const SizedBox(height: 14),

            _buildDropdown<String>(
              label: 'Select Group',
              icon: Icons.groups_rounded,
              stream: _firestore.collection('groups').snapshots(),
              selectedValue: selectedGroupId,
              onChanged: (v) => setState(() => selectedGroupId = v),
            ),
            const SizedBox(height: 12),

            _buildDropdown<String>(
              label: 'Select Subject',
              icon: Icons.menu_book_rounded,
              stream: _firestore.collection('subjects').snapshots(),
              selectedValue: selectedSubjectId,
              onChanged: (v) => setState(() => selectedSubjectId = v),
            ),
            const SizedBox(height: 12),

            _buildDropdown<String>(
              label: 'Select Location / Room',
              icon: Icons.location_on_rounded,
              stream: _firestore.collection('locations').snapshots(),
              selectedValue: selectedLocationId,
              onChanged: (v) => setState(() => selectedLocationId = v),
            ),
            const SizedBox(height: 12),

            _buildDropdown<String>(
              label: 'Assign Teacher',
              icon: Icons.person_rounded,
              stream: _firestore.collection('teachers').snapshots(),
              selectedValue: selectedTeacherId,
              useTeacherId: true,
              onChanged: (v) => setState(() => selectedTeacherId = v),
            ),
            const SizedBox(height: 12),

            // Duration Dropdown
            DropdownButtonFormField<Duration>(
              value: selectedDuration,
              decoration: InputDecoration(
                labelText: 'Class Duration',
                prefixIcon: const Icon(Icons.timer_rounded, color: Color(0xFF8A9BB5)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF4F6EF7), width: 2),
                ),
              ),
              items: const [
                DropdownMenuItem(value: Duration(minutes: 30), child: Text("30 minutes")),
                DropdownMenuItem(value: Duration(minutes: 45), child: Text("45 minutes")),
                DropdownMenuItem(value: Duration(hours: 1), child: Text("1 hour")),
                DropdownMenuItem(value: Duration(hours: 1, minutes: 30), child: Text("1 hour 30 minutes")),
                DropdownMenuItem(value: Duration(hours: 2), child: Text("2 hours")),
              ],
              onChanged: (v) => setState(() => selectedDuration = v),
            ),
            const SizedBox(height: 12),

            // Date & Time picker
            GestureDetector(
              onTap: _pickDateTime,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: selectedDate != null
                      ? Border.all(color: const Color(0xFF4F6EF7), width: 2)
                      : null,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, color: Color(0xFF8A9BB5)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        selectedDate == null
                            ? 'Pick Date & Time'
                            : DateFormat('EEE, MMM d, yyyy  •  HH:mm').format(selectedDate!),
                        style: TextStyle(
                          fontSize: 15,
                          color: selectedDate == null ? const Color(0xFF8A9BB5) : const Color(0xFF1A1F3C),
                          fontWeight: selectedDate != null ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, color: Color(0xFF8A9BB5)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _addClass,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_rounded),
                          SizedBox(width: 8),
                          Text('Add Classroom', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
