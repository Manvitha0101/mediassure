import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat_message_model.dart';

class ChatService {
  final _db = FirebaseFirestore.instance;

  static const String _colChats = 'chats';

  Stream<List<ChatMessageModel>> streamMessages(String patientId) {
    return _db
        .collection(_colChats)
        .doc(patientId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ChatMessageModel.fromDoc).toList());
  }

  Future<void> sendMessage({
    required String patientId,
    required String senderId,
    required String senderName,
    required String senderRole,
    required String text,
    String? imageUrl,
  }) async {
    final msg = <String, dynamic>{
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      if (imageUrl != null) 'imageUrl': imageUrl,
    };

    await _db
        .collection(_colChats)
        .doc(patientId)
        .collection('messages')
        .add(msg);
  }
}

