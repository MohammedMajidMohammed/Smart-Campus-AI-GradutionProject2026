import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:smart_canvas/features/online_sessions/models/subject_message_model.dart';
import 'package:smart_canvas/core/di/dependancy_injection.dart';
import 'package:smart_canvas/core/cache/cache_helper.dart';
import 'package:path/path.dart' as p;

class SubjectChatService {
  final _supabase = getIt<SupabaseClient>();

  /// Stream messages for a specific subject
  Stream<List<SubjectMessageModel>> getMessagesStream(String subjectId) {
    print("Subscribing to subject messages stream for subject: $subjectId");
    return _supabase
        .from('subject_messages')
        .stream(primaryKey: ['id'])
        .eq('subject_id', subjectId)
        .order('created_at', ascending: true)
        .map((data) {
          print("Received ${data.length} messages from stream for subject: $subjectId");
          return data.map((json) => SubjectMessageModel.fromJson(json)).toList();
        });
  }

  /// Send a text message
  Future<void> sendTextMessage(String subjectId, String content) async {
    final user = getIt<CacheHelper>().getUserModel();
    if (user == null) return;

    final message = SubjectMessageModel(
      id: '',
      subjectId: subjectId,
      senderId: user.id,
      senderName: user.fullName,
      isProfessor: user.roleName.toLowerCase() == 'professor',
      content: content,
      attachmentType: MessageAttachmentType.text,
      createdAt: DateTime.now(),
    );

    await _supabase.from('subject_messages').insert(message.toJson());
    await sendRefreshSignal(subjectId);
  }

  /// Send an attachment (Image, PDF, Audio, File)
  Future<void> sendAttachmentMessage({
    required String subjectId,
    required File file,
    required MessageAttachmentType type,
    String? content,
  }) async {
    final user = getIt<CacheHelper>().getUserModel();
    if (user == null) return;

    final fileName = p.basename(file.path);
    final extension = p.extension(file.path);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storagePath = 'subject_$subjectId/${user.id}_$timestamp$extension';

    // 1. Upload to Storage
    await _supabase.storage.from('chat_attachments').upload(storagePath, file);

    // 2. Get Public URL
    final attachmentUrl = _supabase.storage.from('chat_attachments').getPublicUrl(storagePath);

    // 3. Create Message Entry
    final message = SubjectMessageModel(
      id: '',
      subjectId: subjectId,
      senderId: user.id,
      senderName: user.fullName,
      isProfessor: user.roleName.toLowerCase() == 'professor',
      content: content,
      attachmentUrl: attachmentUrl,
      attachmentType: type,
      attachmentName: fileName,
      createdAt: DateTime.now(),
    );

    await _supabase.from('subject_messages').insert(message.toJson());
    await sendRefreshSignal(subjectId);
  }

  /// Update an existing text message
  Future<void> updateTextMessage(String messageId, String newContent) async {
    await _supabase
        .from('subject_messages')
        .update({
          'content': newContent,
          'is_edited': true,
          'edited_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', messageId);
  }

  /// Delete a message
  Future<void> deleteMessage(String messageId) async {
    await _supabase
        .from('subject_messages')
        .delete()
        .eq('id', messageId);
  }

  /// Realtime Typing Indicators & Refresh using Broadcast
  RealtimeChannel getSubjectChannel(String subjectId) {
    return _supabase.channel('subject_$subjectId');
  }

  Future<void> setTypingStatus(String subjectId, bool isTyping) async {
    final user = getIt<CacheHelper>().getUserModel();
    if (user == null) return;

    final channel = getSubjectChannel(subjectId);
    // Use named arguments with dynamic to bypass type issues
    try {
      (channel as dynamic).send(
        type: 'broadcast',
        event: 'typing',
        payload: {
          'userId': user.id,
          'userName': user.fullName,
          'isTyping': isTyping,
        },
      );
    } catch (e) {
      debugPrint('Error sending typing status: $e');
    }
  }

  /// Force a manual refresh signal for all clients in the subject chat
  Future<void> sendRefreshSignal(String subjectId) async {
    final channel = getSubjectChannel(subjectId);
    // Use named arguments with dynamic to bypass type issues
    try {
      (channel as dynamic).send(
        type: 'broadcast',
        event: 'refresh_messages',
        payload: {'subjectId': subjectId},
      );
    } catch (e) {
      debugPrint('Error sending refresh signal: $e');
    }
  }
}
