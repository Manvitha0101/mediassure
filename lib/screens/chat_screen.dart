import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../widgets/glass_components.dart';
import 'app_theme.dart';
import '../debug/debug_logger.dart';

class ChatScreen extends StatefulWidget {
  final String patientId;
  final String title;

  const ChatScreen({
    super.key,
    required this.patientId,
    required this.title,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _chat = ChatService();
  final _textCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final raw = _textCtrl.text.trim();
    if (raw.isEmpty) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _sending = true);
    try {
      final user = await AuthService().getUserRole(uid);
      if (user == null) throw Exception('Failed to load user profile.');

      await _chat.sendMessage(
        patientId: widget.patientId,
        senderId: uid,
        senderName: user.name,
        senderRole: user.role.name,
        text: raw,
      );

      _textCtrl.clear();
    } catch (e) {
      if (!mounted) return;
      DebugLogger.log(
        hypothesisId: 'CHAT',
        location: 'chat_screen.dart',
        message: 'send failed',
        data: {'err': e.toString()},
      );
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: uid == null
          ? const Center(child: Text('Not logged in'))
          : Column(
              children: [
                Expanded(
                  child: StreamBuilder(
                    stream: _chat.streamMessages(widget.patientId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      final messages = snapshot.data ?? const [];
                      if (messages.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: GlassCard(
                              padding: const EdgeInsets.all(28),
                              child: Text(
                                'No messages yet.\nStart the conversation here.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.textSecondary.withOpacity(0.85),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                        itemCount: messages.length,
                        itemBuilder: (context, i) {
                          final m = messages[i];
                          final isMe = m.senderId == uid;
                          final bubbleColor = isMe
                              ? AppColors.primary.withOpacity(0.18)
                              : Colors.white.withOpacity(0.14);
                          final borderColor = isMe
                              ? AppColors.primary.withOpacity(0.20)
                              : Colors.white.withOpacity(0.18);

                          return Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              constraints: const BoxConstraints(maxWidth: 320),
                              child: GlassCard(
                                borderRadius: 18,
                                opacity: 0.10,
                                blur: 10,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: bubbleColor,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: borderColor),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (!isMe)
                                        Text(
                                          '${m.senderName} • ${m.senderRole}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.textSecondary.withOpacity(0.9),
                                          ),
                                        ),
                                      if (!isMe) const SizedBox(height: 6),
                                      Text(
                                        m.text,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      borderRadius: 22,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _textCtrl,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _sending ? null : _send(),
                              decoration: InputDecoration(
                                hintText: 'Type a message…',
                                border: InputBorder.none,
                                hintStyle: TextStyle(
                                  color: AppColors.textSecondary.withOpacity(0.65),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _sending ? null : _send,
                            icon: Icon(
                              Icons.send_rounded,
                              color: _sending
                                  ? AppColors.textSecondary.withOpacity(0.4)
                                  : AppColors.primary,
                            ),
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
}

