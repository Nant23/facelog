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
  Duration? selectedDuration; // ✅ NEW

  /// ================== GENERATE CLASS ID ==================
  Future<String> generateNextClassId() async {
    final snapshot = await _firestore.collection('classes').get();

    if (snapshot.docs.isEmpty) {
      return "class001";
    }

    List<int> numbers = snapshot.docs.map((doc) {
      String id = doc.id.replaceAll("class", "");
      return int.tryParse(id) ?? 0;
    }).toList();

    numbers.sort();
    int nextNumber = numbers.last + 1;

    return "class${nextNumber.toString().padLeft(3, '0')}";
  }

  /// ================== ADD CLASS ==================
  Future<void> addClass() async {
    if (selectedGroupId == null ||
        selectedSubjectId == null ||
        selectedLocationId == null ||
        selectedTeacherId == null ||
        selectedDate == null ||
        selectedDuration == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    String newClassId = await generateNextClassId();

    await _firestore.collection('classes').doc(newClassId).set({
      'attended': [],
      'date': Timestamp.fromDate(selectedDate!),
      'groupid': selectedGroupId,
      'location': selectedLocationId,
      'subject': selectedSubjectId,
      'teacherId': selectedTeacherId,
      'duration': selectedDuration!.inMinutes, // ✅ STORED IN MINUTES
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Class Added Successfully")),
    );

    setState(() {
      selectedGroupId = null;
      selectedSubjectId = null;
      selectedLocationId = null;
      selectedTeacherId = null;
      selectedDate = null;
      selectedDuration = null; // ✅ RESET
    });
  }

  /// ================== DATE & TIME PICKER ==================
  Future<void> pickDateTime() async {
    DateTime? date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
    );

    if (date == null) return;

    TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time == null) return;

    setState(() {
      selectedDate = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  /// ================== REUSABLE DROPDOWN ==================
  Widget buildDropdown({
    required String label,
    required IconData icon,
    required Stream<QuerySnapshot> stream,
    required String? selectedValue,
    required Function(String?) onChanged,
    bool isTeacher = false,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return DropdownButtonFormField<String>(
          value: selectedValue,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          items: snapshot.data!.docs.map((doc) {
            return DropdownMenuItem<String>(
              value: isTeacher ? doc['teacherId'] : doc.id,
              child: Text(doc['name']),
            );
          }).toList(),
          onChanged: onChanged,
        );
      },
    );
  }

  /// ================== UI ==================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Add Classroom"),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Create New Class",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  buildDropdown(
                    label: "Select Group",
                    icon: Icons.group,
                    stream: _firestore.collection('groups').snapshots(),
                    selectedValue: selectedGroupId,
                    onChanged: (value) {
                      setState(() => selectedGroupId = value);
                    },
                  ),

                  const SizedBox(height: 15),

                  buildDropdown(
                    label: "Select Subject",
                    icon: Icons.book,
                    stream: _firestore.collection('subjects').snapshots(),
                    selectedValue: selectedSubjectId,
                    onChanged: (value) {
                      setState(() => selectedSubjectId = value);
                    },
                  ),

                  const SizedBox(height: 15),

                  buildDropdown(
                    label: "Select Location",
                    icon: Icons.location_on,
                    stream: _firestore.collection('locations').snapshots(),
                    selectedValue: selectedLocationId,
                    onChanged: (value) {
                      setState(() => selectedLocationId = value);
                    },
                  ),

                  const SizedBox(height: 15),

                  buildDropdown(
                    label: "Assign Teacher",
                    icon: Icons.person,
                    stream: _firestore.collection('teachers').snapshots(),
                    selectedValue: selectedTeacherId,
                    isTeacher: true,
                    onChanged: (value) {
                      setState(() => selectedTeacherId = value);
                    },
                  ),

                  const SizedBox(height: 15),

                  /// ================== DURATION DROPDOWN ==================
                  DropdownButtonFormField<Duration>(
                    value: selectedDuration,
                    decoration: InputDecoration(
                      labelText: "Class Duration",
                      prefixIcon: const Icon(Icons.timer),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: Duration(minutes: 30),
                          child: Text("30 minutes")),
                      DropdownMenuItem(
                          value: Duration(minutes: 45),
                          child: Text("45 minutes")),
                      DropdownMenuItem(
                          value: Duration(hours: 1),
                          child: Text("1 hour")),
                      DropdownMenuItem(
                          value: Duration(hours: 1, minutes: 30),
                          child: Text("1 hour 30 minutes")),
                      DropdownMenuItem(
                          value: Duration(hours: 2),
                          child: Text("2 hours")),
                    ],
                    onChanged: (value) {
                      setState(() => selectedDuration = value);
                    },
                  ),

                  const SizedBox(height: 20),

                  /// ================== DATE & TIME PICKER ==================
                  InkWell(
                    onTap: pickDateTime,
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 15, horizontal: 15),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              selectedDate == null
                                  ? "Pick Date & Time"
                                  : DateFormat('yyyy-MM-dd HH:mm')
                                      .format(selectedDate!),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// ================== ADD BUTTON ==================
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: addClass,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        "Add Classroom",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}