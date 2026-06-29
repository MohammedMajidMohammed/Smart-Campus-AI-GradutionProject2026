import 'dart:convert';
import 'dart:developer';
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:smart_canvas/core/constants/app_constants.dart';
import 'package:smart_canvas/core/di/dependancy_injection.dart';
import 'package:smart_canvas/core/cache/cache_helper.dart';
import 'package:smart_canvas/features/student/study_chatbot/models/message_model.dart';
part 'regulations_chatbot_state.dart';

class RegulationsChatbotCubit extends Cubit<RegulationsChatbotState> {
  RegulationsChatbotCubit() : super(RegulationsChatbotInitial()) {
    loadHistory();
  }

  //--> variables
  List<ChatSessionModel> sessions = [];
  ChatSessionModel? currentSession;
  List<MessageModel> messages = [];
  final messageTextcontroller = TextEditingController();
  static const String regulationsApiUrl = AppConstants.regulationsChatbotApiUrl;

  //send message to regulations chatbot
  Future<void> sendMessage() async {
    try {
      final text = messageTextcontroller.text.trim();
      if (text.isEmpty) {
        return;
      }

      if (currentSession != null && currentSession!.title == 'New Chat' && text.isNotEmpty) {
        currentSession!.title = text.length > 30 ? '${text.substring(0, 30)}...' : text;
      }

      // Add user message
      messages.add(
        MessageModel(message: text, isUser: true, createdAt: DateTime.now()),
      );
      saveHistory();

      final savedText = text;
      messageTextcontroller.clear();
      emit(ChatbotThinking());

      final response = await http.post(
        Uri.parse(regulationsApiUrl),
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'question': savedText}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final answer = data['answer'] as String;
          final verdict = (data['answerVerdict'] as Map<String, dynamic>?)?['verdict'] as String? ?? '';
          String finalMessage = answer;

          // ── CLARIFY: no faculty specified ──────────────────────────────
          if (verdict == 'CLARIFY') {
            const faculties = [
              'كلية الحاسبات والذكاء الاصطناعي',
              'كلية الهندسة',
              'كلية الصيدلة',
              'كلية التمريض',
              'كلية تكنولوجيا العلوم الصحية التطبيقية',
              'كلية العلوم الإنسانية والاجتماعية',
              'كلية طب الأسنان',
              'كلية الطب البشري',
              'كلية العلاج الطبيعي',
              'كلية الطب البيطري',
            ];
            messages.add(
              MessageModel(
                message: finalMessage,
                isUser: false,
                createdAt: DateTime.now(),
                isClarify: true,
                clarifyFaculties: faculties,
              ),
            );
            saveHistory();
            emit(ChatbotLoaded());
            return;
          }

          // Parse sources for references
          if (data['sources'] != null) {
            final sources = data['sources'] as List;
            if (sources.isNotEmpty) {
              if (answer == 'المعلومات غير موجودة في اللائحة') {
                finalMessage = '$answer\n\n🔍 المعلومات المتاحة من اللائحة:\n\n';
                for (var i = 0; i < sources.length && i < 5; i++) {
                  final source = sources[i] as Map<String, dynamic>;
                  final file = source['file'] as String? ?? 'غير محدد';
                  final page = source['page'] as int? ?? 0;
                  final snippet = source['snippet'] as String?
                      ?? source['textSnippet'] as String?
                      ?? '';

                  if (snippet.isNotEmpty) {
                    final cleanedSnippet = snippet
                        .replaceAll(RegExp(r'\n+'), ' ')
                        .replaceAll(RegExp(r'\s+'), ' ')
                        .trim();
                    final shortSnippet = cleanedSnippet.length > 120
                        ? '${cleanedSnippet.substring(0, 120)}...'
                        : cleanedSnippet;

                    final fileName = file.split('/').last.replaceAll(RegExp(r'\.(pdf|PDF)$'), '');
                    finalMessage += '• $fileName — ص $page\n  $shortSnippet\n\n';
                  }
                }
                finalMessage = finalMessage.trim();
              } else {
                // Regular response with sources: append clean references
                finalMessage += '\n\n📄 **المصادر:**\n';
                final Set<String> seen = {};
                final List<String> referenceLines = [];
                for (var i = 0; i < sources.length && referenceLines.length < 5; i++) {
                  final source = sources[i] as Map<String, dynamic>;
                  final file = source['file'] as String? ?? 'غير محدد';
                  final page = source['page'] as int? ?? 0;
                  final sectionTitle = source['sectionTitle'] as String?;
                  final fileName = file.split('/').last.replaceAll(RegExp(r'\.(pdf|PDF)$'), '');

                  final key = '$fileName|$page';
                  if (!seen.contains(key)) {
                    seen.add(key);
                    final sectionPart = (sectionTitle != null && sectionTitle.isNotEmpty && sectionTitle != 'N/A')
                        ? ' — $sectionTitle'
                        : '';
                    referenceLines.add('• $fileName — ص $page$sectionPart');
                  }
                }
                finalMessage += referenceLines.join('\n');
              }
            }
          }

          messages.add(
            MessageModel(
              message: finalMessage,
              isUser: false,
              createdAt: DateTime.now(),
            ),
          );
          saveHistory();
          emit(ChatbotLoaded());
        } else {
          throw Exception(data['error'] ?? 'Unknown error');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      log(e.toString());
      emit(ChatbotError(message: e.toString()));
    }
  }

  /// Called when user taps a faculty chip or department chip in a CLARIFY message.
  /// Finds the last user question and re-asks it with the selected faculty and optional department.
  Future<void> sendMessageWithFacultyAndDept(String faculty, String? department) async {
    // Find the last user message (before the CLARIFY bot message)
    String originalQuestion = '';
    for (int i = messages.length - 1; i >= 0; i--) {
      if (messages[i].isUser) {
        originalQuestion = messages[i].message ?? '';
        break;
      }
    }
    if (originalQuestion.isEmpty) return;

    String suffix = ' في $faculty';
    if (department != null && department.isNotEmpty && department != 'تخطي') {
      suffix += ' قسم $department';
    }

    final newQuestion = '$originalQuestion$suffix';
    messageTextcontroller.text = newQuestion;
    await sendMessage();
  }

  // load chat history from CacheHelper (SharedPreferences)
  void loadHistory() {
    try {
      final userId = getIt<CacheHelper>().getUserModel()?.id;
      if (userId == null) return;

      final historyJson = getIt<CacheHelper>().getDataString(key: 'regulations_chat_sessions_$userId');
      if (historyJson != null) {
        final List<dynamic> decoded = jsonDecode(historyJson);
        sessions = decoded
            .map((item) => ChatSessionModel.fromJson(item as Map<String, dynamic>))
            .toList();
        // Sort sessions by date (newest first)
        sessions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }

      if (sessions.isEmpty) {
        createNewSession();
      } else {
        selectSession(sessions.first);
      }
    } catch (e) {
      log('Error loading regulations chat history: $e');
      if (sessions.isEmpty) {
        createNewSession();
      }
    }
  }

  // save chat history to CacheHelper (SharedPreferences)
  void saveHistory() {
    try {
      final userId = getIt<CacheHelper>().getUserModel()?.id;
      if (userId == null) return;

      final encoded = jsonEncode(sessions.map((s) => s.toJson()).toList());
      getIt<CacheHelper>().saveData(key: 'regulations_chat_sessions_$userId', value: encoded);
    } catch (e) {
      log('Error saving regulations chat history: $e');
    }
  }

  // clear chat history
  void clearHistory() {
    try {
      final userId = getIt<CacheHelper>().getUserModel()?.id;
      if (userId == null) return;

      sessions.clear();
      getIt<CacheHelper>().removeData(key: 'regulations_chat_sessions_$userId');
      createNewSession();
    } catch (e) {
      log('Error clearing regulations chat history: $e');
    }
  }

  // create a new chat session
  void createNewSession() {
    final newSession = ChatSessionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'New Chat',
      messages: [],
      createdAt: DateTime.now(),
    );
    sessions.insert(0, newSession);
    currentSession = newSession;
    messages = newSession.messages;
    emit(RegulationsChatbotInitial());
    saveHistory();
  }

  // select an existing chat session
  void selectSession(ChatSessionModel session) {
    currentSession = session;
    messages = session.messages;
    if (messages.isEmpty) {
      emit(RegulationsChatbotInitial());
    } else {
      emit(ChatbotLoaded());
    }
  }

  // delete a specific session
  void deleteSession(String sessionId) {
    try {
      sessions.removeWhere((s) => s.id == sessionId);
      if (currentSession?.id == sessionId) {
        if (sessions.isEmpty) {
          createNewSession();
        } else {
          selectSession(sessions.first);
        }
      } else {
        emit(ChatbotLoaded());
      }
      saveHistory();
    } catch (e) {
      log('Error deleting regulations chat session: $e');
    }
  }
}
