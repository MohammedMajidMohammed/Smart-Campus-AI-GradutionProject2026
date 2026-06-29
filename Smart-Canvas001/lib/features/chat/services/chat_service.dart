import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:smart_canvas/features/chat/models/chat_message_model.dart';
import 'package:smart_canvas/features/chat/models/chat_room_model.dart';
import 'package:smart_canvas/features/online_sessions/models/subject_message_model.dart';
import 'package:smart_canvas/core/di/dependancy_injection.dart';
import 'package:smart_canvas/core/cache/cache_helper.dart';
import 'package:path/path.dart' as p;

class ChatService {
  final _supabase = getIt<SupabaseClient>();

  /// Get or Create a chat room
  Future<ChatRoomModel> getOrCreateRoom({
    required String type,
    required String targetId,
  }) async {
    // Check if room exists
    final response = await _supabase
        .from('chat_rooms')
        .select()
        .eq('type', type)
        .eq('target_id', targetId)
        .maybeSingle();

    if (response != null) {
      return ChatRoomModel.fromJson(response);
    }

    // Create new room
    final newRoom = await _supabase
        .from('chat_rooms')
        .insert({
          'type': type,
          'target_id': targetId,
        })
        .select()
        .single();

    return ChatRoomModel.fromJson(newRoom);
  }

  /// Stream messages for a specific room
  Stream<List<ChatMessageModel>> getMessagesStream(String roomId) {
    print("Subscribing to messages stream for room: $roomId");
    return _supabase
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('created_at', ascending: true)
        .map((data) {
          print("Received ${data.length} messages from stream for room: $roomId");
          return data.map((json) => ChatMessageModel.fromJson(json)).toList();
        });
  }

  /// Send a text message
  Future<void> sendTextMessage({
    required String roomId,
    required String content,
  }) async {
    final user = getIt<CacheHelper>().getUserModel();
    if (user == null) return;

    final message = {
      'room_id': roomId,
      'sender_id': user.id,
      'sender_name': user.fullName,
      'content': content,
      'attachment_type': 'text',
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };

    await _supabase.from('chat_messages').insert(message);
    await sendRefreshSignal(roomId);
  }

  /// Update an existing text message
  Future<void> updateTextMessage({
    required String messageId,
    required String content,
    required String roomId,
  }) async {
    await _supabase.from('chat_messages').update({
      'content': content,
      'is_edited': true,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', messageId);
    
    await sendRefreshSignal(roomId);
  }

  /// Send an attachment
  Future<void> sendAttachmentMessage({
    required String roomId,
    required File file,
    required MessageAttachmentType type,
    String? content,
  }) async {
    final user = getIt<CacheHelper>().getUserModel();
    if (user == null) return;

    final fileName = p.basename(file.path);
    final extension = p.extension(file.path);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storagePath = 'room_$roomId/${user.id}_$timestamp$extension';

    // 1. Upload to Storage
    await _supabase.storage.from('chat_attachments').upload(storagePath, file);

    // 2. Get Public URL
    final attachmentUrl = _supabase.storage.from('chat_attachments').getPublicUrl(storagePath);

    // 3. Create Message Entry
    final typeStr = type.toString().split('.').last;
    
    await _supabase.from('chat_messages').insert({
      'room_id': roomId,
      'sender_id': user.id,
      'sender_name': user.fullName,
      'content': content,
      'attachment_url': attachmentUrl,
      'attachment_type': typeStr,
      'attachment_name': fileName,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
    await sendRefreshSignal(roomId);
  }

  /// Delete a message
  Future<void> deleteMessage(String messageId) async {
    await _supabase.from('chat_messages').delete().eq('id', messageId);
  }

  /// Realtime Typing Indicators using Broadcast
  RealtimeChannel getRoomChannel(String roomId) {
    return _supabase.channel('room_$roomId');
  }

  Future<void> setTypingStatus(String roomId, bool isTyping) async {
    final user = getIt<CacheHelper>().getUserModel();
    if (user == null) return;

    final channel = getRoomChannel(roomId);
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

  /// Force a manual refresh signal for all clients in the room
  Future<void> sendRefreshSignal(String roomId) async {
    final channel = getRoomChannel(roomId);
    // Use named arguments with dynamic to bypass type issues
    try {
      (channel as dynamic).send(
        type: 'broadcast',
        event: 'refresh_messages',
        payload: {'roomId': roomId},
      );
    } catch (e) {
      debugPrint('Error sending refresh signal: $e');
    }
  }
}
