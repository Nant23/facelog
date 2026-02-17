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

  Future<void> addClass() async {
    if (selectedGroupId == null ||
        selectedSubjectId == null ||
        selectedLocationId == null ||
        selectedTeacherId == null ||
        selectedDate == null) {
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
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Class Added Successfully")),
    );

    //Navigator.pop(context);
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Classroom")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [

              /// GROUP DROPDOWN
              StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('groups').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const CircularProgressIndicator();

                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: "Select Group",
                      border: OutlineInputBorder(),
                    ),
                    value: selectedGroupId,
                    items: snapshot.data!.docs.map((doc) {
                      return DropdownMenuItem<String>(
                        value: doc.id,
                        child: Text(doc['name']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedGroupId = value;
                      });
                    },
                  );
                },
              ),

              const SizedBox(height: 15),

              /// SUBJECT DROPDOWN
              StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('subjects').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const CircularProgressIndicator();

                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: "Select Subject",
                      border: OutlineInputBorder(),
                    ),
                    value: selectedSubjectId,
                    items: snapshot.data!.docs.map((doc) {
                      return DropdownMenuItem<String>(
                        value: doc.id,
                        child: Text(doc['name']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedSubjectId = value;
                      });
                    },
                  );
                },
              ),

              const SizedBox(height: 15),

              /// LOCATION DROPDOWN
              StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('locations').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const CircularProgressIndicator();

                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: "Select Location",
                      border: OutlineInputBorder(),
                    ),
                    value: selectedLocationId,
                    items: snapshot.data!.docs.map((doc) {
                      return DropdownMenuItem<String>(
                        value: doc.id,
                        child: Text(doc['name']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedLocationId = value;
                      });
                    },
                  );
                },
              ),

              const SizedBox(height: 15),

              /// TEACHER DROPDOWN
              StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('teachers').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const CircularProgressIndicator();

                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: "Assign Teacher",
                      border: OutlineInputBorder(),
                    ),
                    value: selectedTeacherId,
                    items: snapshot.data!.docs.map((doc) {
                      return DropdownMenuItem<String>(
                        value: doc['teacherId'], // use teacherId field
                        child: Text(doc['name']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedTeacherId = value;
                      });
                    },
                  );
                },
              ),

              const SizedBox(height: 20),

              /// DATE TIME PICKER
              ElevatedButton(
                onPressed: pickDateTime,
                child: Text(
                  selectedDate == null
                      ? "Pick Date & Time"
                      : DateFormat('yyyy-MM-dd HH:mm').format(selectedDate!),
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: addClass,
                child: const Text("Add Classroom"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
