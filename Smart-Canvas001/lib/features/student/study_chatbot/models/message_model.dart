import 'dart:io';

class MessageModel {
  final String? message;
  final bool isUser;
  final DateTime? createdAt;
  final File? image, file;
  final bool isClarify;
  final List<String> clarifyFaculties;

  MessageModel({
    this.message,
    required this.isUser,
    this.createdAt,
    this.image,
    this.file,
    this.isClarify = false,
    this.clarifyFaculties = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'isUser': isUser,
      'createdAt': createdAt?.toIso8601String(),
      'imagePath': image?.path,
      'filePath': file?.path,
      'isClarify': isClarify,
      'clarifyFaculties': clarifyFaculties,
    };
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      message: json['message'] as String?,
      isUser: json['isUser'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      image: json['imagePath'] != null ? File(json['imagePath'] as String) : null,
      file: json['filePath'] != null ? File(json['filePath'] as String) : null,
      isClarify: json['isClarify'] as bool? ?? false,
      clarifyFaculties: (json['clarifyFaculties'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? const [],
    );
  }
}

class ChatSessionModel {
  final String id;
  String title;
  final List<MessageModel> messages;
  final DateTime createdAt;

  ChatSessionModel({
    required this.id,
    required this.title,
    required this.messages,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'messages': messages.map((m) => m.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ChatSessionModel.fromJson(Map<String, dynamic> json) {
    return ChatSessionModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'New Chat',
      messages: (json['messages'] as List<dynamic>?)
              ?.map((m) => MessageModel.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}
