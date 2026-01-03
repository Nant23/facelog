import 'package:flutter/material.dart';

class AttendanceRequestPage extends StatefulWidget {
  const AttendanceRequestPage({super.key});

  @override
  State<AttendanceRequestPage> createState() => _AttendanceRequestPageState();
}

class _AttendanceRequestPageState extends State<AttendanceRequestPage> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedClass;
  DateTime? _selectedDate;
  final TextEditingController _reasonController = TextEditingController();

  final List<String> _classes = [
    "Mathematics 101",
    "Chemistry Lab",
    "Physics 102",
    "English 201"
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  // ------------ PICK DATE FUNCTION ------------
  Future<void> _pickDate() async {
    DateTime initialDate = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? initialDate,
      firstDate: DateTime(initialDate.year, initialDate.month, initialDate.day),
      lastDate: DateTime(initialDate.year + 1),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // ------------ SUBMIT FUNCTION ------------
  void _submitRequest() {
    if (_formKey.currentState!.validate()) {
      String className = _selectedClass!;
      String date = _selectedDate!.toLocal().toString().split(' ')[0];
      String reason = _reasonController.text.trim();

      // Here you can send this data to Firebase or API
      print("Class: $className");
      print("Date: $date");
      print("Reason: $reason");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Leave request submitted successfully!")),
      );

      // Clear the form
      setState(() {
        _selectedClass = null;
        _selectedDate = null;
        _reasonController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendance Leave Request"),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Select Class",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedClass,
                hint: const Text("Choose a class"),
                items: _classes
                    .map((cls) => DropdownMenuItem(
                          value: cls,
                          child: Text(cls),
                        ))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedClass = val;
                  });
                },
                validator: (value) =>
                    value == null ? "Please select a class" : null,
              ),

              const SizedBox(height: 20),

              const Text(
                "Select Date",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDate == null
                            ? "Pick a date"
                            : _selectedDate!
                                .toLocal()
                                .toString()
                                .split(' ')[0],
                        style: TextStyle(
                            fontSize: 16,
                            color: _selectedDate == null
                                ? Colors.grey
                                : Colors.black),
                      ),
                      const Icon(Icons.calendar_today, color: Colors.blue),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "Reason",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _reasonController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: "Enter your reason for leave",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? "Please enter a reason" : null,
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submitRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    "Submit Request",
                    style: TextStyle(fontSize: 18, color: Colors.white),
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
