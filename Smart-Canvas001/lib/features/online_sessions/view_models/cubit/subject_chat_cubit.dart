import 'dart:async';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:smart_canvas/features/online_sessions/models/subject_message_model.dart';
import 'package:smart_canvas/features/online_sessions/services/subject_chat_service.dart';
import 'package:smart_canvas/core/cache/cache_helper.dart';
import 'package:smart_canvas/core/di/dependancy_injection.dart';
import 'package:smart_canvas/core/services/enhanced_notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';

part 'subject_chat_state.dart';

class SubjectChatCubit extends Cubit<SubjectChatState> {
  final SubjectChatService _service;
  StreamSubscription? _subscription;
  RealtimeChannel? _typingChannel;
  final Map<String, String> _typingUsers = {};
  String? _currentSubjectId;

  SubjectChatCubit(this._service) : super(SubjectChatInitial());

  /// Initialize chat for a subject
  Future<void> initChat(String subjectId) async {
    if (_currentSubjectId == subjectId) return;
    
    _currentSubjectId = subjectId;
    print("Initializing high-reliability subject chat for subject: $subjectId");
    _subscription?.cancel();

    // 1. Initial Load
    try {
      final initialData = await _service.getMessagesStream(subjectId).first;
      if (!isClosed) emit(SubjectChatLoaded(List.from(initialData)));
    } catch (e) {
      print("Initial load failed: $e");
    }

    // 2. High-Reliability Subscription
    _subscription = _service.getMessagesStream(subjectId).listen(
      (messages) {
        print("Subject Realtime update: Received ${messages.length} messages");
        final currentUserId = getIt<CacheHelper>().getUserModel()?.id;
        if (messages.isNotEmpty && currentUserId != null) {
          final lastMessage = messages.last;
          final isRecent = DateTime.now().difference(lastMessage.createdAt).inSeconds < 5;

          if (lastMessage.senderId != currentUserId && isRecent) {
            getIt<EnhancedNotificationService>().showNotification(
              id: lastMessage.id.hashCode,
              title: "New subject message",
              body: "${lastMessage.senderName}: ${lastMessage.content ?? "Sent an attachment"}",
              type: NotificationType.announcement,
            );
          }
        }

        final currentState = state;
        if (!isClosed) {
          if (currentState is SubjectChatLoaded) {
            emit(SubjectChatLoaded(List.from(messages), editingMessage: currentState.editingMessage, typingUsers: Map.from(_typingUsers)));
          } else {
            emit(SubjectChatLoaded(List.from(messages)));
          }
        }
      },
      onError: (error) {
        print("Subject Stream error: $error");
        // Auto-retry
        Future.delayed(const Duration(seconds: 3), () {
           if (!isClosed) initChat(subjectId);
        });
      },
    );

    // Typing & Refresh Broadcast
    _typingChannel?.unsubscribe();
    _typingChannel = _service.getSubjectChannel(subjectId);
    _typingChannel!.onBroadcast(
      event: 'typing',
      callback: (payload) {
        final userId = payload['userId']?.toString();
        final userName = payload['userName']?.toString();
        final isTyping = payload['isTyping'] as bool? ?? false;

        if (userId != null && userId != getIt<CacheHelper>().getUserModel()?.id) {
          if (isTyping) {
            _typingUsers[userId] = userName ?? 'user'.tr();
          } else {
            _typingUsers.remove(userId);
          }
          final currentState = state;
          if (!isClosed && currentState is SubjectChatLoaded) {
            emit(SubjectChatLoaded(currentState.messages, editingMessage: currentState.editingMessage, typingUsers: Map.from(_typingUsers)));
          }
        }
      },
    ).onBroadcast(
      event: 'refresh_messages',
      callback: (payload) {
        print("Received manual refresh signal for subject: $subjectId");
        // Manual refresh without re-subscribing
        _service.getMessagesStream(subjectId).first.then((msgs) {
           if (!isClosed && state is SubjectChatLoaded) {
             emit(SubjectChatLoaded(List.from(msgs), typingUsers: Map.from(_typingUsers)));
           }
        });
      },
    ).subscribe();

    // 3. Periodic Background Sync (Safety Net)
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (state is SubjectChatLoaded) {
         _service.getMessagesStream(subjectId).first.then((msgs) {
            if (!isClosed) {
              emit(SubjectChatLoaded(List.from(msgs), typingUsers: Map.from(_typingUsers)));
            }
         });
      }
    });
  }

  Timer? _syncTimer;

  void setTyping(bool isTyping) {
    if (_currentSubjectId != null) {
      _service.setTypingStatus(_currentSubjectId!, isTyping);
    }
  }

  /// Enter edit mode
  void setEditingMessage(SubjectMessageModel? message) {
    final currentState = state;
    if (currentState is SubjectChatLoaded) {
      if (message == null) {
        emit(SubjectChatLoaded(currentState.messages, typingUsers: Map.from(_typingUsers)));
      } else {
        emit(SubjectChatEditing(currentState.messages, editingMessage: message, typingUsers: Map.from(_typingUsers)));
      }
    }
  }

  /// Update an existing text message
  Future<void> updateText(String newContent) async {
    final currentState = state;
    if (currentState is! SubjectChatEditing || currentState.editingMessage == null) return;
    
    final messageId = currentState.editingMessage!.id;
    final messages = currentState.messages;

    try {
      emit(SubjectChatLoading()); // Or a specific updating state
      await _service.updateTextMessage(messageId, newContent.trim());
      if (!isClosed) emit(SubjectChatLoaded(messages)); // Exit edit mode
    } catch (e) {
      if (!isClosed) {
        emit(SubjectChatError(e.toString()));
        emit(SubjectChatLoaded(messages));
      }
    }
  }

  /// Delete a message
  Future<void> deleteMessage(String messageId) async {
    final currentState = state;
    if (currentState is! SubjectChatLoaded) return;
    
    final originalMessages = List<SubjectMessageModel>.from(currentState.messages);
    final updatedMessages = List<SubjectMessageModel>.from(originalMessages)
      ..removeWhere((m) => m.id == messageId);

    // Optimistic Update: Remove instantly from UI
    emit(SubjectChatLoaded(updatedMessages));

    try {
      await _service.deleteMessage(messageId);
    } catch (e) {
      // Rollback if deletion fails
      if (!isClosed) {
        emit(SubjectChatError(e.toString()));
        emit(SubjectChatLoaded(originalMessages));
      }
    }
  }

  /// Send text message
  Future<void> sendText(String content) async {
    if (_currentSubjectId == null || content.trim().isEmpty) return;
    
    final currentState = state;
    if (currentState is SubjectChatEditing) {
      await updateText(content);
      return;
    }

    final user = getIt<CacheHelper>().getUserModel();
    if (user == null) return;

    // Optimistic Update: Add message locally first
    if (currentState is SubjectChatLoaded) {
      final tempMessage = SubjectMessageModel(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        subjectId: _currentSubjectId!,
        senderId: user.id,
        senderName: user.fullName,
        isProfessor: user.roleName.toLowerCase() == 'professor',
        content: content.trim(),
        createdAt: DateTime.now(),
      );
      
      final updatedMessages = List<SubjectMessageModel>.from(currentState.messages)..add(tempMessage);
      emit(SubjectChatLoaded(updatedMessages, typingUsers: currentState.typingUsers));
    }

    try {
      await _service.sendTextMessage(_currentSubjectId!, content.trim());
      setTyping(false);
    } catch (e) {
      if (!isClosed) emit(SubjectChatError(e.toString()));
    }
  }

  /// Send attachment (Image, Audio, PDF, File)
  Future<void> sendAttachment({
    required File file,
    required MessageAttachmentType type,
    String? content,
  }) async {
    if (_currentSubjectId == null) return;
    
    final previousState = state;
    emit(const SubjectChatUploading());
    
    try {
      await _service.sendAttachmentMessage(
        subjectId: _currentSubjectId!,
        file: file,
        type: type,
        content: content,
      );
      // Success will trigger a new SubjectChatLoaded from the stream
    } catch (e) {
      if (!isClosed) {
        emit(SubjectChatError(e.toString()));
        if (previousState is SubjectChatLoaded) {
          emit(previousState);
        }
      }
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    _typingChannel?.unsubscribe();
    _syncTimer?.cancel();
    return super.close();
  }
}
