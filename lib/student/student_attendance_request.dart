import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// ─────────────────────────────────────────────────────────
/// Firestore collection: `attendance_requests`
///
/// Each document stores:
/// {
///   studentId:   "uid_string",          // Firebase Auth UID
///   studentName: "Ali Hassan",           // for admin display
///   groupId:     "g1",                  // student's group
///   classId:     "class001",            // Firestore doc ID of the class
///   subjectId:   "math_101",            // subject field from class doc
///   subjectName: "Mathematics",         // resolved human-readable name
///   classDate:   Timestamp,             // the class's scheduled date
///   reason:      "Was sick",            // student's typed reason
///   status:      "pending",             // "pending" | "approved" | "rejected"
///   adminNote:   "",                    // admin fills this when reviewing
///   submittedAt: Timestamp (server),    // when the request was created
/// }
///
/// Recommended Firestore indexes:
///   attendance_requests: studentId ASC, submittedAt DESC
///   attendance_requests: status ASC, submittedAt DESC   (for admin view)
/// ─────────────────────────────────────────────────────────

class AttendanceRequestPage extends StatefulWidget {
  const AttendanceRequestPage({super.key});

  @override
  State<AttendanceRequestPage> createState() => _AttendanceRequestPageState();
}

class _AttendanceRequestPageState extends State<AttendanceRequestPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  late TabController _tabController;

  // Cached student profile
  String _studentName = '';
  String _groupId = '';
  bool _profileLoaded = false;

  // Form state
  String? _selectedClassId;
  Map<String, dynamic>? _selectedClassData;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProfile();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('students')
          .doc(uid)
          .get();
      if (doc.exists) {
        setState(() {
          _studentName = doc['name'] ?? '';
          _groupId = doc['group'] ?? '';
          _profileLoaded = true;
        });
        return;
      }
      // uid-field fallback
      final q = await FirebaseFirestore.instance
          .collection('students')
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();
      if (q.docs.isNotEmpty) {
        setState(() {
          _studentName = q.docs.first['name'] ?? '';
          _groupId = q.docs.first['group'] ?? '';
          _profileLoaded = true;
        });
      }
    } catch (_) {}
  }

  /// Resolve subject name from subjectId
  Future<String> _resolveSubjectName(String subjectId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('subjects')
          .doc(subjectId)
          .get();
      return doc.exists ? (doc['name'] as String? ?? subjectId) : subjectId;
    } catch (_) {
      return subjectId;
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate() || _selectedClassData == null) {
      if (_selectedClassData == null) {
        _showSnack('Please select a class', isError: true);
      }
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final subjectId = _selectedClassData!['subject'] as String? ?? '';
      final subjectName = await _resolveSubjectName(subjectId);
      final classDate = _selectedClassData!['date'] as Timestamp;

      // Check: don't allow duplicate requests for same class
      final existing = await FirebaseFirestore.instance
          .collection('attendance_requests')
          .where('studentId', isEqualTo: uid)
          .where('classId', isEqualTo: _selectedClassId)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        _showSnack('You already submitted a request for this class.',
            isError: true);
        return;
      }

      await FirebaseFirestore.instance.collection('attendance_requests').add({
        'studentId': uid,
        'studentName': _studentName,
        'groupId': _groupId,
        'classId': _selectedClassId,
        'subjectId': subjectId,
        'subjectName': subjectName,
        'classDate': classDate,
        'reason': _reasonController.text.trim(),
        'status': 'pending',
        'adminNote': '',
        'submittedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        _showSnack('Request submitted successfully!', isError: false);
        setState(() {
          _selectedClassId = null;
          _selectedClassData = null;
          _reasonController.clear();
        });
        _tabController.animateTo(1); // switch to My Requests tab
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────
          Container(
            color: const Color(0xFF1A1F3C),
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.of(context).padding.top + 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Leave Requests',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Submit and track your absence requests',
                  style:
                      TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
                const SizedBox(height: 16),
                TabBar(
                  controller: _tabController,
                  indicatorColor: const Color(0xFF4F6EF7),
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: const Color(0xFF8A9BB5),
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                  tabs: const [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_circle_outline_rounded, size: 15),
                          SizedBox(width: 6),
                          Text('New Request'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history_rounded, size: 15),
                          SizedBox(width: 6),
                          Text('My Requests'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Tab content ──────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _NewRequestForm(
                  formKey: _formKey,
                  reasonController: _reasonController,
                  uid: uid,
                  groupId: _groupId,
                  profileLoaded: _profileLoaded,
                  selectedClassId: _selectedClassId,
                  selectedClassData: _selectedClassData,
                  isSubmitting: _isSubmitting,
                  onClassSelected: (id, data) => setState(() {
                    _selectedClassId = id;
                    _selectedClassData = data;
                  }),
                  onSubmit: _submitRequest,
                ),
                _MyRequestsList(uid: uid),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── New Request Form ─────────────────────────────────────
class _NewRequestForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController reasonController;
  final String uid, groupId;
  final bool profileLoaded, isSubmitting;
  final String? selectedClassId;
  final Map<String, dynamic>? selectedClassData;
  final Function(String id, Map<String, dynamic> data) onClassSelected;
  final VoidCallback onSubmit;

  const _NewRequestForm({
    required this.formKey,
    required this.reasonController,
    required this.uid,
    required this.groupId,
    required this.profileLoaded,
    required this.selectedClassId,
    required this.selectedClassData,
    required this.isSubmitting,
    required this.onClassSelected,
    required this.onSubmit,
  });

  String _getState(Map<String, dynamic> data) {
    final now = DateTime.now();
    final start = (data['date'] as Timestamp).toDate();
    final end = start.add(Duration(minutes: data['duration'] as int? ?? 0));
    if (now.isBefore(start)) return 'scheduled';
    if (now.isAfter(end)) return 'completed';
    return 'ongoing';
  }

  Color _stateColor(String s) {
    if (s == 'ongoing') return const Color(0xFF22C55E);
    if (s == 'scheduled') return const Color(0xFF4F6EF7);
    return const Color(0xFF8A9BB5);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF4F6EF7).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF4F6EF7).withOpacity(0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: Color(0xFF4F6EF7), size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'You can request attendance correction for a class you missed. The admin will review and approve or reject it.',
                      style:
                          TextStyle(color: Color(0xFF4F6EF7), fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Class picker
            const _Label('Select Class'),
            const SizedBox(height: 8),
            !profileLoaded
                ? const Center(
                    child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ))
                : groupId.isEmpty
                    ? _errorTile('Could not load your group. Please re-login.')
                    : StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('classes')
                            .where('groupid', isEqualTo: groupId)
                            .snapshots(),
                        builder: (context, snap) {
                          if (!snap.hasData) {
                            return const Center(
                                child: CircularProgressIndicator(
                                    strokeWidth: 2));
                          }

                          final docs = snap.data!.docs.where((doc) {
                            final d = doc.data() as Map<String, dynamic>;
                            return d['date'] != null;
                          }).toList()
                            ..sort((a, b) {
                              final aDate =
                                  ((a.data() as Map)['date'] as Timestamp)
                                      .toDate();
                              final bDate =
                                  ((b.data() as Map)['date'] as Timestamp)
                                      .toDate();
                              return bDate.compareTo(aDate); // newest first
                            });

                          if (docs.isEmpty) {
                            return _errorTile(
                                'No classes found for your group.');
                          }

                          return Column(
                            children: docs.map((doc) {
                              final d =
                                  doc.data() as Map<String, dynamic>;
                              final classState = _getState(d);
                              final color = _stateColor(classState);
                              final date =
                                  (d['date'] as Timestamp).toDate();
                              final isSelected = selectedClassId == doc.id;

                              return GestureDetector(
                                onTap: () => onClassSelected(doc.id, d),
                                child: AnimatedContainer(
                                  duration:
                                      const Duration(milliseconds: 150),
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF4F6EF7)
                                            .withOpacity(0.07)
                                        : Colors.white,
                                    borderRadius:
                                        BorderRadius.circular(14),
                                    border: isSelected
                                        ? Border.all(
                                            color: const Color(0xFF4F6EF7),
                                            width: 2)
                                        : Border.all(
                                            color: Colors.grey.shade100),
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.black
                                              .withOpacity(0.03),
                                          blurRadius: 6)
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: color,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              d['subject'] ?? '—',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                                color: isSelected
                                                    ? const Color(
                                                        0xFF4F6EF7)
                                                    : const Color(
                                                        0xFF1A1F3C),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              DateFormat('EEE, MMM d • HH:mm')
                                                  .format(date),
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      Colors.grey.shade500),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: color.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          classState[0].toUpperCase() +
                                              classState.substring(1),
                                          style: TextStyle(
                                              color: color,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      if (isSelected) ...[
                                        const SizedBox(width: 8),
                                        const Icon(
                                            Icons.check_circle_rounded,
                                            color: Color(0xFF4F6EF7),
                                            size: 18),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),

            const SizedBox(height: 20),

            // Reason
            const _Label('Reason for Absence'),
            const SizedBox(height: 8),
            TextFormField(
              controller: reasonController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Describe your reason for absence...',
                hintStyle: const TextStyle(
                    color: Color(0xFF8A9BB5), fontSize: 13),
                filled: true,
                fillColor: Colors.white,
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
                  borderSide:
                      const BorderSide(color: Color(0xFFEF4444)),
                ),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Please enter a reason'
                  : null,
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isSubmitting ? null : onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F6EF7),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
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

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _errorTile(String msg) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Color(0xFFEF4444), size: 18),
          const SizedBox(width: 10),
          Expanded(
              child: Text(msg,
                  style: const TextStyle(
                      color: Color(0xFFEF4444), fontSize: 13))),
        ],
      ),
    );
  }
}

// ─── My Requests List ─────────────────────────────────────
class _MyRequestsList extends StatelessWidget {
  final String uid;
  const _MyRequestsList({required this.uid});

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
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('attendance_requests')
          .where('studentId', isEqualTo: uid)
          .orderBy('submittedAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // Pending count badge
        final docs = snap.data!.docs;
        final pendingCount =
            docs.where((d) => (d['status'] ?? 'pending') == 'pending').length;

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inbox_rounded, size: 60, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text('No requests yet',
                    style: TextStyle(
                        color: Colors.grey.shade400, fontSize: 16)),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Summary row
            if (pendingCount > 0)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFFF59E0B).withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.hourglass_top_rounded,
                        color: Color(0xFFF59E0B), size: 18),
                    const SizedBox(width: 10),
                    Text(
                      '$pendingCount request${pendingCount > 1 ? 's' : ''} pending review',
                      style: const TextStyle(
                          color: Color(0xFFF59E0B),
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                    ),
                  ],
                ),
              ),

            ...docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final status = data['status'] as String? ?? 'pending';
              final color = _statusColor(status);
              final classDate = data['classDate'] != null
                  ? DateFormat('EEE, MMM d, yyyy')
                      .format((data['classDate'] as Timestamp).toDate())
                  : '—';
              final submittedAt = data['submittedAt'] != null
                  ? DateFormat('MMM d • HH:mm')
                      .format((data['submittedAt'] as Timestamp).toDate())
                  : '—';
              final adminNote = data['adminNote'] as String? ?? '';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8)
                  ],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top row
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
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
                                      data['subjectName'] ??
                                          data['subjectId'] ??
                                          '—',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Color(0xFF1A1F3C)),
                                    ),
                                    Text(
                                      'Class on $classDate',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade500),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
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

                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 12),

                          // Reason
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.notes_rounded,
                                  size: 15, color: Colors.grey.shade400),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  data['reason'] ?? '—',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 6),

                          // Submitted at
                          Row(
                            children: [
                              Icon(Icons.schedule_rounded,
                                  size: 13, color: Colors.grey.shade400),
                              const SizedBox(width: 6),
                              Text('Submitted $submittedAt',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade400)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Admin note (only if exists)
                    if (adminNote.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.06),
                          borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(16)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.admin_panel_settings_rounded,
                                size: 14, color: color),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Admin: $adminNote',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: color,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

// ─── Reusable label ───────────────────────────────────────
class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Color(0xFF1A1F3C)));
  }
}
