import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class TeacherLeaveRequestsPage extends StatefulWidget {
  const TeacherLeaveRequestsPage({super.key});

  @override
  State<TeacherLeaveRequestsPage> createState() =>
      _TeacherLeaveRequestsPageState();
}

class _TeacherLeaveRequestsPageState
    extends State<TeacherLeaveRequestsPage> {
  String _filter = 'all';
  late final Future<_TeacherContext> _teacherContextFuture;

  @override
  void initState() {
    super.initState();
    // Cache future here — calling _loadTeacherContext() directly in build()
    // means every setState() (filter chip tap, etc.) re-runs it from scratch,
    // causing the flash-then-spinner loop.
    _teacherContextFuture = _loadTeacherContext();
  }

  // Resolve the teacher's custom ID and the class IDs they teach
  Future<_TeacherContext> _loadTeacherContext() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('Not logged in');

    final teacherDoc = await FirebaseFirestore.instance
        .collection('teachers')
        .doc(uid)
        .get();
    if (!teacherDoc.exists) throw Exception('Teacher not found');

    final teacherId = teacherDoc['teacherId'] as String;

    // Get all classIds this teacher is assigned to
    final classesSnap = await FirebaseFirestore.instance
        .collection('classes')
        .where('teacherId', isEqualTo: teacherId)
        .get();

    final classIds = classesSnap.docs.map((d) => d.id).toList();

    return _TeacherContext(
        teacherId: teacherId, classIds: classIds);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: FutureBuilder<_TeacherContext>(
        future: _teacherContextFuture,
        builder: (context, teacherSnap) {
          if (teacherSnap.connectionState ==
              ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator());
          }
          if (teacherSnap.hasError || !teacherSnap.hasData) {
            return _ErrorView(
                message: teacherSnap.error?.toString() ??
                    'Could not load teacher profile');
          }

          final ctx = teacherSnap.data!;

          // No classes assigned yet
          if (ctx.classIds.isEmpty) {
            return _buildScaffold(
              pendingCount: 0,
              child: _EmptyState(
                  filter: _filter,
                  icon: Icons.class_outlined,
                  message: 'No classes assigned to you yet'),
            );
          }

          // Firestore `whereIn` supports max 30 items; chunk if needed
          // For typical usage a single query is fine
          final classIdsChunk = ctx.classIds.take(30).toList();

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('attendance_requests')
                .where('classId', whereIn: classIdsChunk)
                .orderBy('submittedAt', descending: true)
                .snapshots(),
            builder: (context, snap) {
              if (snap.hasError) {
                return _buildScaffold(
                  pendingCount: 0,
                  child: _ErrorView(message: 'Error loading requests.\n\${snap.error}'),
                );
              }
              // Only show spinner on the very first load
              if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              // Filter out docs where submittedAt is still null (pending server write)
              var docs = (snap.data?.docs ?? []).where((d) {
                return (d.data() as Map<String, dynamic>)['submittedAt'] != null;
              }).toList();

              // Client-side status filter
              if (_filter != 'all') {
                docs = docs
                    .where((d) =>
                        (d['status'] as String? ?? 'pending') ==
                        _filter)
                    .toList();
              }

              final pendingCount = (snap.data?.docs ?? [])
                .where((d) => (d['status'] as String? ?? 'pending') == 'pending')
                .length;

              return _buildScaffold(
                pendingCount: pendingCount,
                child: docs.isEmpty
                    ? _EmptyState(
                        filter: _filter,
                        icon: Icons.inbox_rounded,
                        message: _filter == 'all'
                            ? 'No leave requests yet'
                            : 'No ${_filter} requests')
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          return _RequestTile(
                            docId: doc.id,
                            data: data,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => _RequestDetailPage(
                                    docId: doc.id,
                                    data: data,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildScaffold(
      {required int pendingCount, required Widget child}) {
    return Column(
      children: [
        // ── Header ───────────────────────────────────────
        Container(
          color: const Color(0xFF1A1F3C),
          padding:
              const EdgeInsets.fromLTRB(20, 50, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: 8),
                  const Text('Leave Requests',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  const Spacer(),
                  if (pendingCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B)
                            .withOpacity(0.2),
                        borderRadius:
                            BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$pendingCount pending',
                        style: const TextStyle(
                            color: Color(0xFFF59E0B),
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              // Filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    'all',
                    'pending',
                    'approved',
                    'rejected'
                  ].map((f) {
                    final selected = _filter == f;
                    final label =
                        f[0].toUpperCase() + f.substring(1);
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _filter = f),
                      child: AnimatedContainer(
                        duration:
                            const Duration(milliseconds: 180),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFF4F6EF7)
                              : Colors.white.withOpacity(0.08),
                          borderRadius:
                              BorderRadius.circular(20),
                          border: Border.all(
                            color: selected
                                ? const Color(0xFF4F6EF7)
                                : Colors.white
                                    .withOpacity(0.15),
                          ),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : const Color(0xFF8A9BB5),
                              fontSize: 13,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.normal),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

// ─── Request Tile ─────────────────────────────────────────
class _RequestTile extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final VoidCallback onTap;
  const _RequestTile(
      {required this.docId,
      required this.data,
      required this.onTap});

  Color _statusColor(String s) {
    if (s == 'approved') return const Color(0xFF22C55E);
    if (s == 'rejected') return const Color(0xFFEF4444);
    return const Color(0xFFF59E0B);
  }

  IconData _statusIcon(String s) {
    if (s == 'approved') return Icons.check_circle_rounded;
    if (s == 'rejected') return Icons.cancel_rounded;
    return Icons.hourglass_top_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final status = data['status'] as String? ?? 'pending';
    final color = _statusColor(status);
    final classDate = data['classDate'] != null
        ? DateFormat('MMM d, yyyy')
            .format((data['classDate'] as Timestamp).toDate())
        : '—';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8)
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor:
                  const Color(0xFF4F6EF7).withOpacity(0.1),
              child: Text(
                (data['studentName'] as String? ?? '?')[0]
                    .toUpperCase(),
                style: const TextStyle(
                    color: Color(0xFF4F6EF7),
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['studentName'] ?? '—',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF1A1F3C)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data['subjectName'] ??
                        data['subjectId'] ??
                        '—',
                    style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12),
                  ),
                  Text(
                    'Class on $classDate',
                    style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 11),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_statusIcon(status),
                          color: color, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        status[0].toUpperCase() +
                            status.substring(1),
                        style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                const Icon(Icons.chevron_right_rounded,
                    color: Color(0xFFCBD5E1), size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Request Detail Page ──────────────────────────────────
class _RequestDetailPage extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;
  const _RequestDetailPage(
      {required this.docId, required this.data});

  @override
  State<_RequestDetailPage> createState() =>
      _RequestDetailPageState();
}

class _RequestDetailPageState
    extends State<_RequestDetailPage> {
  final _noteController = TextEditingController();
  bool _isProcessing = false;
  late String _currentStatus;

  @override
  void initState() {
    super.initState();
    _currentStatus =
        widget.data['status'] as String? ?? 'pending';
    _noteController.text =
        widget.data['adminNote'] as String? ?? '';
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _updateRequest(String newStatus) async {
    setState(() => _isProcessing = true);
    try {
      // 1. Update the request status
      await FirebaseFirestore.instance
          .collection('attendance_requests')
          .doc(widget.docId)
          .update({
        'status': newStatus,
        'adminNote': _noteController.text.trim(),
        'reviewedAt': FieldValue.serverTimestamp(),
      });

      // 2. If approved, mark student present in attendance
      if (newStatus == 'approved') {
        final classId = widget.data['classId'] as String?;
        final studentId = widget.data['studentId'] as String?;

        if (classId != null && studentId != null) {
          await FirebaseFirestore.instance
              .collection('classes')
              .doc(classId)                                    // classId IS the doc ID
              .update({
            'attended': FieldValue.arrayUnion([studentId]),   // add uid to attended array
          });
        }
      }

      setState(() => _currentStatus = newStatus);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              Icon(
                newStatus == 'approved'
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
                color: Colors.white,
                size: 18),
              const SizedBox(width: 10),
              Text('Request ${newStatus}'),
            ]),
            backgroundColor: newStatus == 'approved'
                ? const Color(0xFF22C55E)
                : const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Color _statusColor(String s) {
    if (s == 'approved') return const Color(0xFF22C55E);
    if (s == 'rejected') return const Color(0xFFEF4444);
    return const Color(0xFFF59E0B);
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final classDate = d['classDate'] != null
        ? DateFormat('EEEE, MMMM d, yyyy')
            .format((d['classDate'] as Timestamp).toDate())
        : '—';
    final submittedAt = d['submittedAt'] != null
        ? DateFormat('MMM d, yyyy • HH:mm')
            .format((d['submittedAt'] as Timestamp).toDate())
        : '—';

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
                  // ── Student card ────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                            color:
                                Colors.black.withOpacity(0.04),
                            blurRadius: 10)
                      ],
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: const Color(0xFF4F6EF7)
                              .withOpacity(0.12),
                          child: Text(
                            (d['studentName'] as String? ??
                                    '?')[0]
                                .toUpperCase(),
                            style: const TextStyle(
                                color: Color(0xFF4F6EF7),
                                fontSize: 28,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          d['studentName'] ?? '—',
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1F3C)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          d['subjectName'] ??
                              d['subjectId'] ??
                              '—',
                          style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 14),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: _statusColor(_currentStatus)
                                .withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(20),
                          ),
                          child: Text(
                            _currentStatus[0].toUpperCase() +
                                _currentStatus.substring(1),
                            style: TextStyle(
                                color: _statusColor(
                                    _currentStatus),
                                fontWeight: FontWeight.bold,
                                fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Details ──────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                            color:
                                Colors.black.withOpacity(0.04),
                            blurRadius: 10)
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                        vertical: 4, horizontal: 16),
                    child: Column(
                      children: [
                        _DetailRow(
                          icon: Icons.calendar_today_rounded,
                          label: 'Class Date',
                          value: classDate,
                        ),
                        const Divider(
                            height: 1,
                            color: Color(0xFFF0F2F8),
                            indent: 44),
                        _DetailRow(
                          icon: Icons.notes_rounded,
                          label: 'Reason',
                          value: d['reason'] ?? '—',
                        ),
                        const Divider(
                            height: 1,
                            color: Color(0xFFF0F2F8),
                            indent: 44),
                        _DetailRow(
                          icon: Icons.groups_rounded,
                          label: 'Group',
                          value: d['groupId'] ?? '—',
                        ),
                        const Divider(
                            height: 1,
                            color: Color(0xFFF0F2F8),
                            indent: 44),
                        _DetailRow(
                          icon: Icons.schedule_rounded,
                          label: 'Submitted',
                          value: submittedAt,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Admin note ───────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                            color:
                                Colors.black.withOpacity(0.04),
                            blurRadius: 10)
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Note to Student (optional)',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: Color(0xFF1A1F3C)),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _noteController,
                          maxLines: 3,
                          enabled:
                              _currentStatus == 'pending',
                          decoration: InputDecoration(
                            hintText:
                                'Add a note visible to the student...',
                            hintStyle: const TextStyle(
                                color: Color(0xFF8A9BB5),
                                fontSize: 13),
                            filled: true,
                            fillColor: const Color(0xFFF4F6FB),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: Color(0xFF4F6EF7),
                                  width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // ── Action buttons ────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -3))
              ],
            ),
            child: _currentStatus == 'pending'
                ? Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isProcessing
                              ? null
                              : () =>
                                  _updateRequest('approved'),
                          icon: const Icon(Icons.check_rounded),
                          label: const Text('Approve',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight:
                                      FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(0xFF22C55E),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isProcessing
                              ? null
                              : () =>
                                  _updateRequest('rejected'),
                          icon: const Icon(Icons.close_rounded),
                          label: const Text('Reject',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight:
                                      FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  )
                : Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _statusColor(_currentStatus)
                          .withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: _statusColor(_currentStatus)
                              .withOpacity(0.25)),
                    ),
                    child: Text(
                      'This request has been ${_currentStatus}.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color:
                              _statusColor(_currentStatus),
                          fontWeight: FontWeight.w600,
                          fontSize: 14),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Detail Row ───────────────────────────────────────────
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _DetailRow(
      {required this.icon,
      required this.label,
      required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:
                  const Color(0xFF4F6EF7).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon,
                color: const Color(0xFF4F6EF7), size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 11)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        color: Color(0xFF1A1F3C),
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String filter, message;
  final IconData icon;
  const _EmptyState(
      {required this.filter,
      required this.message,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(message,
              style: TextStyle(
                  color: Colors.grey.shade400, fontSize: 15)),
        ],
      ),
    );
  }
}

// ─── Error view ───────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 52, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.grey.shade400, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}

// ─── Internal data model ──────────────────────────────────
class _TeacherContext {
  final String teacherId;
  final List<String> classIds;
  _TeacherContext(
      {required this.teacherId, required this.classIds});
}
