import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/patient_log_model.dart';
import '../../services/patient_log_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/glass_components.dart';
import '../app_theme.dart';

class PatientLogsScreen extends StatefulWidget {
  final String patientId;
  const PatientLogsScreen({super.key, required this.patientId});

  @override
  State<PatientLogsScreen> createState() => _PatientLogsScreenState();
}

class _PatientLogsScreenState extends State<PatientLogsScreen> {
  final _logService = PatientLogService();
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;
  String _caretakerName = '';
  String _caretakerId = '';

  @override
  void initState() {
    super.initState();
    _loadCaretaker();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCaretaker() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return;
    final user = await AuthService().getUserRole(uid);
    if (mounted) {
      setState(() {
        _caretakerId = uid;
        _caretakerName = user?.name ?? 'Caretaker';
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _caretakerId.isEmpty) return;

    setState(() => _sending = true);
    try {
      await _logService.addLog(
        patientId: widget.patientId,
        message: text,
        caretakerId: _caretakerId,
        caretakerName: _caretakerName,
      );
      _msgCtrl.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Activity Log',
            style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ─── Message List ──────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<List<PatientLogModel>>(
              stream: _logService.getLogsStream(widget.patientId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final logs = snapshot.data ?? [];

                if (logs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: GlassCard(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.history_rounded,
                                  size: 60, color: AppColors.primary),
                            ),
                            const SizedBox(height: 24),
                            const Text('No Activity Yet',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary)),
                            const SizedBox(height: 12),
                            Text(
                              'Care notes and medicine logs will appear here.\nUse the box below to add a note.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary.withOpacity(0.8)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollCtrl,
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    return _LogBubble(
                      log: logs[index],
                      isMe: logs[index].caretakerId == _caretakerId,
                    );
                  },
                );
              },
            ),
          ),

          // ─── Compose Bar ───────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              borderRadius: 24,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      maxLines: null,
                      textInputAction: TextInputAction.newline,
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Add a care note…',
                        hintStyle: TextStyle(
                            color: AppColors.textSecondary.withOpacity(0.5),
                            fontSize: 14),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sending ? null : _sendMessage,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.accent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: _sending
                          ? const Padding(
                              padding: EdgeInsets.all(10),
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.send_rounded,
                              color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Log Bubble ───────────────────────────────────────────────────────────────

class _LogBubble extends StatelessWidget {
  final PatientLogModel log;
  final bool isMe;
  const _LogBubble({required this.log, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final isSystemMessage =
        log.message.contains('given at') || log.message.contains('marked as');
    final formatter = DateFormat('MMM d, h:mm a');

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CircleAvatar(
            backgroundColor: isMe
                ? AppColors.primary.withOpacity(0.3)
                : AppColors.accent.withOpacity(0.2),
            radius: 18,
            child: Text(
              log.caretakerName.isNotEmpty
                  ? log.caretakerName[0].toUpperCase()
                  : 'C',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isMe ? AppColors.primary : AppColors.accent,
                  fontSize: 14),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isMe ? 'You' : log.caretakerName,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isMe
                              ? AppColors.primary
                              : AppColors.textPrimary),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formatter.format(log.timestamp),
                      style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary.withOpacity(0.7)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                GlassCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  borderRadius: 16,
                  opacity: isMe ? 0.2 : 0.08,
                  child: Row(
                    children: [
                      if (isSystemMessage) ...[
                        const Icon(Icons.check_circle_rounded,
                            color: Colors.teal, size: 18),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          log.message,
                          style: TextStyle(
                            fontSize: 14,
                            color: isSystemMessage
                                ? Colors.teal.shade700
                                : AppColors.textPrimary,
                            fontWeight: isSystemMessage
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
        ],
      ),
    );
  }
}
