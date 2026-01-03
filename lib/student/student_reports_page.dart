import 'package:flutter/material.dart';

class StudentReportsPage extends StatelessWidget {
  const StudentReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          "Reports",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.black),
        ),
      ),
      body: const Center(
        child: Text("Student Reports"),
      ),
    );
  }
}
