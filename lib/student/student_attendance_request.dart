import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AttendanceRequestPage extends StatefulWidget {
  const AttendanceRequestPage({super.key});

  @override
  State<AttendanceRequestPage> createState() => _AttendanceRequestPageState();
}

class _AttendanceRequestPageState extends State<AttendanceRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  String? _selectedClassId;
  String? _selectedClassName;
  DateTime? _selectedDate;
  bool _isSubmitting = false;

  // Past submitted requests (from Firestore)
  Stream<QuerySnapshot> get _requestsStream => FirebaseFirestore.instance
      .collection('attendance_requests')
      .where('studentId', isEqualTo: uid)
      .orderBy('submittedAt', descending: true)
      .snapshots();

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme:
              const ColorScheme.light(primary: Color(0xFF4F6EF7)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate() || _selectedDate == null) {
      if (_selectedDate == null) {
        _showSnack('Please select a date', isError: true);
      }
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await FirebaseFirestore.instance
          .collection('attendance_requests')
          .add({
        'studentId': uid,
        'classId': _selectedClassId,
        'className': _selectedClassName,
        'date': Timestamp.fromDate(_selectedDate!),
        'reason': _reasonController.text.trim(),
        'status': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        _showSnack('Request submitted successfully!', isError: false);
        setState(() {
          _selectedClassId = null;
          _selectedClassName = null;
          _selectedDate = null;
          _reasonController.clear();
        });
      }
    } catch (e) {
      _showSnack('Failed to submit: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_rounded,
              color: Colors.white,
              size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(msg)),
        ]),
        backgroundColor:
            isError ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return const Color(0xFF22C55E);
      case 'rejected':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'approved':
        return Icons.check_circle_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      default:
        return Icons.hourglass_top_rounded;
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: const Color(0xFF1A1F3C),
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Attendance Request',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Submit a leave request for a missed class',
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Form Card ──────────────────────────
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 12),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SectionLabel('Select Class'),
                          const SizedBox(height: 8),

                          // Class dropdown from Firestore
                          FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('students')
                                .doc(uid)
                                .get(),
                            builder: (context, studentSnap) {
                              if (!studentSnap.hasData) {
                                return const Center(
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2));
                              }
                              final group =
                                  studentSnap.data!['group'] as String? ?? '';

                              return StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('classes')
                                    .where('groupid', isEqualTo: group)
                                    .snapshots(),
                                builder: (context, classSnap) {
                                  final docs =
                                      classSnap.data?.docs ?? [];

                                  return DropdownButtonFormField<String>(
                                    value: _selectedClassId,
                                    hint: const Text('Choose a class'),
                                    decoration: _dropDecoration(),
                                    items: docs.map((doc) {
                                      final data = doc.data()
                                          as Map<String, dynamic>;
                                      final date = (data['date']
                                              as Timestamp)
                                          .toDate();
                                      final label =
                                          '${data['subject']} — ${DateFormat('MMM d').format(date)}';
                                      return DropdownMenuItem<String>(
                                        value: doc.id,
                                        child: Text(label,
                                            overflow:
                                                TextOverflow.ellipsis),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      final doc = docs.firstWhere(
                                          (d) => d.id == val);
                                      final data = doc.data()
                                          as Map<String, dynamic>;
                                      setState(() {
                                        _selectedClassId = val;
                                        _selectedClassName =
                                            data['subject'];
                                      });
                                    },
                                    validator: (v) => v == null
                                        ? 'Please select a class'
                                        : null,
                                  );
                                },
                              );
                            },
                          ),

                          const SizedBox(height: 18),
                          const _SectionLabel('Select Date'),
                          const SizedBox(height: 8),

                          // Date picker
                          GestureDetector(
                            onTap: _pickDate,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF4F6FB),
                                borderRadius: BorderRadius.circular(14),
                                border: _selectedDate != null
                                    ? Border.all(
                                        color: const Color(0xFF4F6EF7),
                                        width: 2)
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    color: _selectedDate != null
                                        ? const Color(0xFF4F6EF7)
                                        : const Color(0xFF8A9BB5),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _selectedDate == null
                                        ? 'Pick a date'
                                        : DateFormat('EEE, MMMM d, yyyy')
                                            .format(_selectedDate!),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _selectedDate == null
                                          ? const Color(0xFF8A9BB5)
                                          : const Color(0xFF1A1F3C),
                                      fontWeight: _selectedDate != null
                                          ? FontWeight.w500
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),
                          const _SectionLabel('Reason for Leave'),
                          const SizedBox(height: 8),

                          TextFormField(
                            controller: _reasonController,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText:
                                  'Describe your reason for absence...',
                              hintStyle: const TextStyle(
                                  color: Color(0xFF8A9BB5), fontSize: 13),
                              filled: true,
                              fillColor: const Color(0xFFF4F6FB),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                    color: Color(0xFF4F6EF7), width: 2),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                    color: Color(0xFFEF4444)),
                              ),
                            ),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Please enter a reason'
                                    : null,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Submit Button ──────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitRequest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F6EF7),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.send_rounded),
                                  SizedBox(width: 8),
                                  Text('Submit Request',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // ── Past Requests ──────────────────────
                    const Text(
                      'My Requests',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1F3C)),
                    ),
                    const SizedBox(height: 12),

                    StreamBuilder<QuerySnapshot>(
                      stream: _requestsStream,
                      builder: (context, snap) {
                        if (!snap.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (snap.data!.docs.isEmpty) {
                          return Center(
                            child: Text('No requests yet',
                                style: TextStyle(
                                    color: Colors.grey.shade400)),
                          );
                        }

                        return Column(
                          children: snap.data!.docs.map((doc) {
                            final data =
                                doc.data() as Map<String, dynamic>;
                            final status =
                                data['status'] as String? ?? 'pending';
                            final date = data['date'] != null
                                ? DateFormat('MMM d, yyyy').format(
                                    (data['date'] as Timestamp).toDate())
                                : '—';
                            final color = _statusColor(status);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                      color:
                                          Colors.black.withOpacity(0.04),
                                      blurRadius: 6)
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.1),
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                    child: Icon(_statusIcon(status),
                                        color: color, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          data['className'] ?? '—',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '$date  •  ${data['reason'] ?? '—'}',
                                          style: TextStyle(
                                              color: Colors.grey.shade500,
                                              fontSize: 12),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.1),
                                      borderRadius:
                                          BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      status[0].toUpperCase() +
                                          status.substring(1),
                                      style: TextStyle(
                                          color: color,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold),
                                    ),
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
          ),
        ],
      ),
    );
  }

  InputDecoration _dropDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF4F6FB),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF4F6EF7), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: Color(0xFF1A1F3C)),
    );
  }
}
