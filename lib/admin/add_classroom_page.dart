import 'package:flutter/material.dart';

class AddClassroomPage extends StatelessWidget {
  AddClassroomPage({super.key});

  final TextEditingController classNameController = TextEditingController();
  final TextEditingController sectionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Classroom"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: classNameController,
              decoration: const InputDecoration(
                labelText: "Class Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: sectionController,
              decoration: const InputDecoration(
                labelText: "Section",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // TODO: Connect to Firebase
              },
              child: const Text("Add Classroom"),
            ),
          ],
        ),
      ),
    );
  }
}
