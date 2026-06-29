import 'dart:developer';
import 'dart:io';
import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_canvas/core/helper/pick_image.dart';
import 'package:smart_canvas/core/di/dependancy_injection.dart';
import 'package:smart_canvas/core/cache/cache_helper.dart';
import 'package:smart_canvas/features/student/study_chatbot/models/message_model.dart';
part 'study_chatbot_state.dart';

class StudyChatbotCubit extends Cubit<StudyChatbotState> {
  StudyChatbotCubit() : super(StudyChatbotInitial()) {
    loadHistory();
  }
  //--> variables
  List<ChatSessionModel> sessions = [];
  ChatSessionModel? currentSession;
  List<MessageModel> messages = [];
  File? image;
  File? file;
  final messageTextcontroller = TextEditingController();
  final prompt = """
You are a Study Chatbot for university students. Your task:

1. Answer only questions related to studying, subjects, lessons, summaries, examples, and exercises.
2. If a student asks about anything outside studying, such as college administration, personal info, schedules, grades, or any topic not related to understanding lessons, reply politely in a simple and clear way that you cannot answer such questions. For example:
   - English: "I am here to help you study and understand your lessons. For questions about college administration or other topics, please use the Academic Chatbot."
   - Arabic: "أنا موجود لمساعدتك على دراسة وفهم الدروس فقط. للأسئلة عن الشؤون الأكاديمية أو أمور أخرى، من فضلك استخدم Academic Chatbot."
3. Keep your answers simple, clear, and easy to understand for students.
4. Respond in the same language as the student: if the question is in Arabic, reply in Arabic; if in English, reply in English.
5. Do not use any unnecessary symbols, formatting characters, or markdown in your responses.
6. Always be polite, friendly, and helpful.
""";
  final apiKey = dotenv.env['API_KEY']!;
  //--> functions
  //pick image
  pickImageFromGallery() async {
    try {
      await pickImage(source: ImageSource.gallery).then((value) {
        if (value != null) {
          image = value;
          emit(UpdateImage());
        }
      });
    } catch (e) {
      emit(PickImageError(message: e.toString()));
    }
  }

  // pick file
  pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'xlsx', 'pptx'],
      );
      if (result != null) {
        file = File(result.files.single.path!);
        emit(UpdateFile());
      }
    } on Exception catch (e) {
      emit(PickFileError(message: e.toString()));
    }
  }

  //send message
  Future<void> sendMessage() async {
    try {
      List<Part> parts = [];
      final text = messageTextcontroller.text.trim();
      if (text.isNotEmpty) {
        parts.add(TextPart(text));
      }
      if (image != null) {
        final imageBytes = await image!.readAsBytes();
        parts.add(DataPart('image/jpeg', imageBytes));
      }
      if (file != null) {
        final fileBytes = await file!.readAsBytes();
        parts.add(DataPart(getMimeType(file!.path), fileBytes));
      }
      if (parts.isEmpty) {
        return;
      }
      if (currentSession != null && currentSession!.title == 'New Chat' && text.isNotEmpty) {
        currentSession!.title = text.length > 30 ? '${text.substring(0, 30)}...' : text;
      }
      messages.add(
        MessageModel(
          message: text,
          isUser: true,
          file: file,
          image: image,
          createdAt: DateTime.now(),
        ),
      );
      saveHistory();
      messageTextcontroller.clear();
      image = null;
      file = null;
      emit(ChatbotThinking());
      
      int retryCount = 0;
      GenerateContentResponse? response;
      final modelNames = [
        'models/gemini-2.5-flash',
        'models/gemini-2.0-flash',
        'models/gemini-flash-latest',
      ];
      
      while (true) {
        final currentModelName = modelNames[retryCount.clamp(0, modelNames.length - 1)];
        try {
          final model = GenerativeModel(
            model: currentModelName,
            apiKey: apiKey,
            systemInstruction: Content.system(prompt),
          );
          response = await model.generateContent([Content.multi(parts)]);
          break; // Success!
        } catch (e) {
          final errStr = e.toString().toLowerCase();
          final isTransient = errStr.contains('503') || 
                              errStr.contains('429') || 
                              errStr.contains('unavailable') || 
                              errStr.contains('resource_exhausted') ||
                              errStr.contains('busy') ||
                              errStr.contains('quota') ||
                              errStr.contains('exceeded') ||
                              errStr.contains('limit') ||
                              errStr.contains('rate') ||
                              errStr.contains('not found') || 
                              errStr.contains('not supported');
          
          if (isTransient && retryCount < modelNames.length - 1) {
            retryCount++;
            log('Gemini model error with $currentModelName. Retrying ($retryCount/${modelNames.length - 1}) with model ${modelNames[retryCount]} after delay...');
            await Future.delayed(Duration(seconds: 1 * retryCount));
          } else {
            rethrow; // Rethrow if not transient or we ran out of retries
          }
        }
      }

      final botReply = response.candidates.first.content.parts
          .whereType<TextPart>()
          .map((e) => e.text)
          .join('\n');
      messages.add(
        MessageModel(
          message: botReply,
          isUser: false,
          createdAt: DateTime.now(),
        ),
      );
      saveHistory();
      emit(ChatbotLoaded());
    } catch (e) {
      log(e.toString());
      final errStr = e.toString().toLowerCase();
      String errorMsg = e.toString();
      if (errStr.contains('503') || errStr.contains('unavailable') || errStr.contains('busy')) {
        errorMsg = "الخدمة غير متوفرة حالياً بسبب الضغط على السيرفر، يرجى المحاولة مرة أخرى بعد قليل.\n\nThe AI service is temporarily busy. Please try again in a moment.";
      } else if (errStr.contains('429') || 
                 errStr.contains('resource_exhausted') || 
                 errStr.contains('quota') || 
                 errStr.contains('exceeded') || 
                 errStr.contains('limit') || 
                 errStr.contains('rate')) {
        errorMsg = "تم تجاوز حد الطلبات المجانية المسموح بها مؤقتاً. يرجى الانتظار لمدة دقيقة ثم المحاولة مجدداً.\n\nYou have temporarily exceeded the free tier requests limit. Please wait a minute and try again.";
      }
      emit(ChatbotError(message: errorMsg));
    }
  }

  // detect mime type
  String getMimeType(String path) {
    final ext = path.split('.').last.toLowerCase();

    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'pdf':
        return 'application/pdf';
      case 'txt':
        return 'text/plain';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        throw Exception('Unsupported file type: .$ext');
    }
  }

  // on remove image
  void onRemoveImage() {
    image = null;
    emit(UpdateImage());
  }

  // on remove file
  void onRemoveFile() {
    file = null;
    emit(UpdateFile());
  }

  // load chat history from CacheHelper (SharedPreferences)
  void loadHistory() {
    try {
      final userId = getIt<CacheHelper>().getUserModel()?.id;
      if (userId == null) return;

      final historyJson = getIt<CacheHelper>().getDataString(key: 'study_chat_sessions_$userId');
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
      log('Error loading study chat history: $e');
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
      getIt<CacheHelper>().saveData(key: 'study_chat_sessions_$userId', value: encoded);
    } catch (e) {
      log('Error saving study chat history: $e');
    }
  }

  // clear chat history
  void clearHistory() {
    try {
      final userId = getIt<CacheHelper>().getUserModel()?.id;
      if (userId == null) return;

      sessions.clear();
      getIt<CacheHelper>().removeData(key: 'study_chat_sessions_$userId');
      createNewSession();
    } catch (e) {
      log('Error clearing study chat history: $e');
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
    emit(StudyChatbotInitial());
    saveHistory();
  }

  // select an existing chat session
  void selectSession(ChatSessionModel session) {
    currentSession = session;
    messages = session.messages;
    if (messages.isEmpty) {
      emit(StudyChatbotInitial());
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
      log('Error deleting study chat session: $e');
    }
  }
}
