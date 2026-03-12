import 'package:flutter/material.dart';

class TeacherLeaveRequestsPage extends StatefulWidget {
  const TeacherLeaveRequestsPage({super.key});

  @override
  State<TeacherLeaveRequestsPage> createState() => _TeacherLeaveRequestsPageState();
}

class _LeaveRequest {
  final String studentName;
  final String studentClass;
  final String date;
  final String reason;
  String status;

  _LeaveRequest({
    required this.studentName,
    required this.studentClass,
    required this.date,
    required this.reason,
    this.status = 'Pending',
  });
}

class _TeacherLeaveRequestsPageState extends State<TeacherLeaveRequestsPage> {
  List<_LeaveRequest> leaveRequests = [
    _LeaveRequest(studentName: 'John Doe', studentClass: 'Mathematics 101', date: '2026-01-05', reason: 'Medical appointment'),
    _LeaveRequest(studentName: 'Jane Smith', studentClass: 'Chemistry Lab', date: '2026-01-06', reason: 'Family emergency'),
    _LeaveRequest(studentName: 'Ali Hassan', studentClass: 'Physics', date: '2026-01-07', reason: 'Travel abroad'),
  ];

  String _filter = 'All';

  List<_LeaveRequest> get _filtered {
    if (_filter == 'All') return leaveRequests;
    return leaveRequests.where((r) => r.status == _filter).toList();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Approved': return const Color(0xFF22C55E);
      case 'Declined': return const Color(0xFFEF4444);
      default: return const Color(0xFFF59E0B);
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Approved': return Icons.check_circle_rounded;
      case 'Declined': return Icons.cancel_rounded;
      default: return Icons.hourglass_top_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = leaveRequests.where((r) => r.status == 'Pending').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: Column(
        children: [
          // ── Header ────────────────────────────────────────
          Container(
            color: const Color(0xFF1A1F3C),
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(width: 8),
                    const Text('Leave Requests', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    if (pendingCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$pendingCount pending',
                          style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'Pending', 'Approved', 'Declined'].map((f) {
                      final selected = _filter == f;
                      return GestureDetector(
                        onTap: () => setState(() => _filter = f),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected ? const Color(0xFF4F6EF7) : Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected ? const Color(0xFF4F6EF7) : Colors.white.withOpacity(0.15),
                            ),
                          ),
                          child: Text(f, style: TextStyle(color: selected ? Colors.white : const Color(0xFF8A9BB5), fontSize: 13, fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // ── List ──────────────────────────────────────────
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inbox_rounded, size: 56, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('No $_filter requests', style: TextStyle(color: Colors.grey.shade400, fontSize: 15)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      final request = _filtered[index];
                      final realIndex = leaveRequests.indexOf(request);
                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => _RequestDetailsPage(
                              request: request,
                              onUpdateStatus: (status) {
                                setState(() => leaveRequests[realIndex].status = status);
                              },
                            ),
                          ),
                        ),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: const Color(0xFF4F6EF7).withOpacity(0.1),
                                child: Text(
                                  request.studentName[0].toUpperCase(),
                                  style: const TextStyle(color: Color(0xFF4F6EF7), fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(request.studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A1F3C))),
                                    const SizedBox(height: 2),
                                    Text(request.studentClass, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                    const SizedBox(height: 2),
                                    Text(request.date, style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _statusColor(request.status).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(_statusIcon(request.status), color: _statusColor(request.status), size: 13),
                                    const SizedBox(width: 4),
                                    Text(request.status, style: TextStyle(color: _statusColor(request.status), fontSize: 12, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Request Details Page ─────────────────────────────────
class _RequestDetailsPage extends StatelessWidget {
  final _LeaveRequest request;
  final Function(String) onUpdateStatus;

  const _RequestDetailsPage({required this.request, required this.onUpdateStatus});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1F3C),
        foregroundColor: Colors.white,
        title: const Text('Request Details'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Student avatar + name
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: const Color(0xFF4F6EF7).withOpacity(0.12),
                          child: Text(
                            request.studentName[0].toUpperCase(),
                            style: const TextStyle(color: Color(0xFF4F6EF7), fontSize: 28, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(request.studentName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1F3C))),
                        const SizedBox(height: 6),
                        Text(request.studentClass, style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Details
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _DetailRow(icon: Icons.calendar_today_rounded, label: 'Date of Leave', value: request.date),
                        const Divider(height: 24, color: Color(0xFFF0F2F8)),
                        _DetailRow(icon: Icons.info_outline_rounded, label: 'Reason', value: request.reason),
                        const Divider(height: 24, color: Color(0xFFF0F2F8)),
                        _DetailRow(
                          icon: Icons.flag_rounded,
                          label: 'Status',
                          value: request.status,
                          valueColor: request.status == 'Approved'
                              ? const Color(0xFF22C55E)
                              : request.status == 'Declined'
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFFF59E0B),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Action Buttons ────────────────────────────────
          if (request.status == 'Pending')
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        onUpdateStatus('Approved');
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Approve', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF22C55E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        onUpdateStatus('Declined');
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Decline', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F6FB),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'This request has already been ${request.status.toLowerCase()}.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color? valueColor;
  const _DetailRow({required this.icon, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF4F6EF7).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF4F6EF7), size: 18),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
            Text(value, style: TextStyle(color: valueColor ?? const Color(0xFF1A1F3C), fontWeight: FontWeight.w600, fontSize: 15)),
          ],
        ),
      ],
    );
  }
}
