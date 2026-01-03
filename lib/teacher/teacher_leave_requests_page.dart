import 'package:flutter/material.dart';

class TeacherLeaveRequestsPage extends StatefulWidget {
  const TeacherLeaveRequestsPage({super.key});

  @override
  State<TeacherLeaveRequestsPage> createState() =>
      _TeacherLeaveRequestsPageState();
}

// ------------ MOCK DATA CLASS ------------
class LeaveRequest {
  final String studentName;
  final String studentClass;
  final String date;
  final String reason;
  String status;

  LeaveRequest({
    required this.studentName,
    required this.studentClass,
    required this.date,
    required this.reason,
    this.status = "Pending",
  });
}

class _TeacherLeaveRequestsPageState extends State<TeacherLeaveRequestsPage> {
  // Mock list of leave requests
  List<LeaveRequest> leaveRequests = [
    LeaveRequest(
      studentName: "John Doe",
      studentClass: "Mathematics 101",
      date: "2026-01-05",
      reason: "Medical appointment",
    ),
    LeaveRequest(
      studentName: "Jane Smith",
      studentClass: "Chemistry Lab",
      date: "2026-01-06",
      reason: "Family emergency",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Leave Requests"),
        backgroundColor: Colors.blue,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: leaveRequests.length,
        itemBuilder: (context, index) {
          LeaveRequest request = leaveRequests[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RequestDetailsPage(
                    request: request,
                    onUpdateStatus: (status) {
                      setState(() {
                        leaveRequests[index].status = status;
                      });
                    },
                  ),
                ),
              );
            },
            child: Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: const Icon(Icons.person, color: Colors.blue),
                ),
                title: Text(request.studentName),
                subtitle: Text("${request.studentClass} • ${request.date}"),
                trailing: Text(
                  request.status,
                  style: TextStyle(
                      color: request.status == "Pending"
                          ? Colors.orange
                          : (request.status == "Approved"
                              ? Colors.green
                              : Colors.red),
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ------------ REQUEST DETAILS PAGE ------------
class RequestDetailsPage extends StatelessWidget {
  final LeaveRequest request;
  final Function(String) onUpdateStatus;

  const RequestDetailsPage({
    super.key,
    required this.request,
    required this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Request Details"),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Student Name:",
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 4),
            Text(
              request.studentName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            Text(
              "Class:",
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 4),
            Text(
              request.studentClass,
              style: const TextStyle(fontSize: 18),
            ),

            const SizedBox(height: 20),

            Text(
              "Date of Leave:",
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 4),
            Text(
              request.date,
              style: const TextStyle(fontSize: 18),
            ),

            const SizedBox(height: 20),

            Text(
              "Reason:",
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 4),
            Text(
              request.reason,
              style: const TextStyle(fontSize: 18),
            ),

            const Spacer(),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: request.status == "Pending"
                        ? () {
                            onUpdateStatus("Approved");
                            Navigator.pop(context);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    child: const Text(
                      "Approve",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: request.status == "Pending"
                        ? () {
                            onUpdateStatus("Declined");
                            Navigator.pop(context);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    child: const Text(
                      "Decline",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
