import 'dart:async';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_canvas/features/chat/models/chat_message_model.dart';
import 'package:smart_canvas/features/online_sessions/models/subject_message_model.dart';
import 'package:smart_canvas/features/chat/services/chat_service.dart';
import 'package:smart_canvas/core/cache/cache_helper.dart';
import 'package:smart_canvas/core/di/dependancy_injection.dart';
import 'package:smart_canvas/core/services/enhanced_notification_service.dart';

abstract class GenericChatState {}

class GenericChatInitial extends GenericChatState {}
class GenericChatLoading extends GenericChatState {}
class GenericChatLoaded extends GenericChatState {
  final List<ChatMessageModel> messages;
  final Map<String, String> typingUsers; // userId -> userName
  GenericChatLoaded(this.messages, {this.typingUsers = const {}});
}
class GenericChatUploading extends GenericChatState {}
class GenericChatError extends GenericChatState {
  final String message;
  GenericChatError(this.message);
}

class GenericChatCubit extends Cubit<GenericChatState> {
  final ChatService _chatService;
  StreamSubscription? _messageSubscription;
  RealtimeChannel? _typingChannel;
  final Map<String, String> _typingUsers = {};
  Timer? _typingTimer;
  String? _currentUserId;

  GenericChatCubit(this._chatService) : super(GenericChatInitial());

  Future<void> initChat(String roomId) async {
    emit(GenericChatLoading());
    
    _currentUserId = getIt<CacheHelper>().getUserModel()?.id;

    // Listen to messages
    print("Initializing high-reliability chat for room: $roomId");
    _messageSubscription?.cancel();
    
    // 1. Initial Load
    final initialData = await _chatService.getMessagesStream(roomId).first;
    if (!isClosed) {
      emit(GenericChatLoaded(List.from(initialData), typingUsers: Map.from(_typingUsers)));
    }

    // 2. High-Reliability Subscription
    _messageSubscription = _chatService.getMessagesStream(roomId).listen(
      (messages) {
        print("Realtime update: Received ${messages.length} messages for room: $roomId");
        if (messages.isNotEmpty && _currentUserId != null) {
          final lastMessage = messages.last;
          final isRecent = DateTime.now().difference(lastMessage.createdAt).inSeconds < 5;
          
          if (lastMessage.senderId != _currentUserId && isRecent) {
            getIt<EnhancedNotificationService>().showNotification(
              id: lastMessage.id.hashCode,
              title: "New message from ${lastMessage.senderName}",
              body: lastMessage.content ?? "Sent an attachment",
              type: NotificationType.general,
            );
          }
        }
        if (!isClosed) {
          emit(GenericChatLoaded(List.from(messages), typingUsers: Map.from(_typingUsers)));
        }
      },
      onError: (e) {
        print("Stream error: $e");
        // Auto-retry after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (!isClosed) initChat(roomId);
        });
      },
    );

    // Listen to typing & refresh broadcast
    _typingChannel?.unsubscribe();
    _typingChannel = _chatService.getRoomChannel(roomId);
    _typingChannel!.onBroadcast(
      event: 'typing',
      callback: (payload) {
        final userId = payload['userId']?.toString();
        final userName = payload['userName']?.toString();
        final isTyping = payload['isTyping'] as bool? ?? false;

        if (userId == null || userId == _currentUserId) return;

        if (isTyping && userName != null) {
          _typingUsers[userId] = userName;
        } else {
          _typingUsers.remove(userId);
        }

        if (!isClosed && state is GenericChatLoaded) {
          final currentState = state as GenericChatLoaded;
          emit(GenericChatLoaded(currentState.messages, typingUsers: Map.from(_typingUsers)));
        }
      },
    ).onBroadcast(
      event: 'refresh_messages',
      callback: (payload) {
        print("Received manual refresh signal for room: $roomId");
        // Manual refresh without re-subscribing
        _chatService.getMessagesStream(roomId).first.then((msgs) {
           if (!isClosed && state is GenericChatLoaded) {
             emit(GenericChatLoaded(List.from(msgs), typingUsers: Map.from(_typingUsers)));
           }
        });
      },
    ).subscribe();

    // 3. Periodic Background Sync (Safety Net)
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!isClosed && state is GenericChatLoaded) {
         _chatService.getMessagesStream(roomId).first.then((msgs) {
            if (!isClosed) {
              emit(GenericChatLoaded(List.from(msgs), typingUsers: Map.from(_typingUsers)));
            }
         });
      }
    });
  }

  Timer? _syncTimer;

  void setTyping(String roomId, bool isTyping) {
    _chatService.setTypingStatus(roomId, isTyping);
  }

  @override
  Future<void> close() {
    _messageSubscription?.cancel();
    _typingChannel?.unsubscribe();
    _typingTimer?.cancel();
    _syncTimer?.cancel();
    return super.close();
  }

  Future<void> sendMessage(String roomId, String content) async {
    final user = getIt<CacheHelper>().getUserModel();
    if (user == null) return;

    // Optimistic Update: Add message locally first
    if (state is GenericChatLoaded) {
      final currentState = state as GenericChatLoaded;
      final tempMessage = ChatMessageModel(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        roomId: roomId,
        senderId: user.id,
        senderName: user.fullName,
        content: content,
        createdAt: DateTime.now(),
      );
      
      final updatedMessages = List<ChatMessageModel>.from(currentState.messages)..add(tempMessage);
      emit(GenericChatLoaded(updatedMessages, typingUsers: currentState.typingUsers));
    }

    try {
      await _chatService.sendTextMessage(roomId: roomId, content: content);
      setTyping(roomId, false);
    } catch (e) {
      emit(GenericChatError(e.toString()));
    }
  }

  Future<void> sendAttachment({
    required String roomId,
    required File file,
    required MessageAttachmentType type,
    String? content,
  }) async {
    try {
      emit(GenericChatUploading());
      await _chatService.sendAttachmentMessage(
        roomId: roomId,
        file: file,
        type: type,
        content: content,
      );
      // Success will be handled by the message stream
    } catch (e) {
      emit(GenericChatError(e.toString()));
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await _chatService.deleteMessage(messageId);
    } catch (e) {
      emit(GenericChatError(e.toString()));
    }
  }

  /// Enter edit mode
  void setEditingMessage(ChatMessageModel? message) {
    if (state is GenericChatLoaded) {
      final currentState = state as GenericChatLoaded;
      if (message == null) {
        emit(GenericChatLoaded(currentState.messages, typingUsers: Map.from(currentState.typingUsers)));
      } else {
        emit(GenericChatEditing(currentState.messages, editingMessage: message, typingUsers: Map.from(currentState.typingUsers)));
      }
    }
  }

  /// Update an existing text message
  Future<void> updateMessage(String roomId, String newContent) async {
    final currentState = state;
    if (currentState is! GenericChatEditing) return;
    
    final messageId = currentState.editingMessage.id;
    final messages = currentState.messages;

    try {
      // Optimistic Update locally
      final updatedMessages = messages.map((m) {
        if (m.id == messageId) {
          return m.copyWith(content: newContent);
        }
        return m;
      }).toList();
      
      emit(GenericChatLoaded(updatedMessages, typingUsers: Map.from(currentState.typingUsers)));

      await _chatService.updateTextMessage(
        messageId: messageId,
        content: newContent.trim(),
        roomId: roomId,
      );
    } catch (e) {
      emit(GenericChatError(e.toString()));
      emit(GenericChatLoaded(messages, typingUsers: Map.from(currentState.typingUsers)));
    }
  }
}

class GenericChatEditing extends GenericChatLoaded {
  final ChatMessageModel editingMessage;
  GenericChatEditing(super.messages, {required this.editingMessage, super.typingUsers});
}
