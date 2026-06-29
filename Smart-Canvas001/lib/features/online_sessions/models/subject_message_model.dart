import 'package:equatable/equatable.dart';

enum MessageAttachmentType { text, image, audio, pdf, file }

class SubjectMessageModel extends Equatable {
  final String id;
  final String subjectId;
  final String senderId;
  final String? senderName;
  final String? content;
  final String? attachmentUrl;
  final MessageAttachmentType attachmentType;
  final String? attachmentName;
  final bool isProfessor;
  final bool isEdited;
  final DateTime? editedAt;
  final DateTime createdAt;

  const SubjectMessageModel({
    required this.id,
    required this.subjectId,
    required this.senderId,
    this.senderName,
    this.content,
    this.attachmentUrl,
    this.attachmentType = MessageAttachmentType.text,
    this.attachmentName,
    this.isProfessor = false,
    this.isEdited = false,
    this.editedAt,
    required this.createdAt,
  });

  factory SubjectMessageModel.fromJson(Map<String, dynamic> json) {
    MessageAttachmentType type = MessageAttachmentType.text;
    final typeStr = json['attachment_type']?.toString();
    if (typeStr == 'image') type = MessageAttachmentType.image;
    if (typeStr == 'audio') type = MessageAttachmentType.audio;
    if (typeStr == 'pdf') type = MessageAttachmentType.pdf;
    if (typeStr == 'file') type = MessageAttachmentType.file;

    return SubjectMessageModel(
      id: json['id']?.toString() ?? '',
      subjectId: json['subject_id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      senderName: json['sender_name']?.toString() ?? json['users']?['full_name']?.toString() ?? 'User',
      content: json['content']?.toString(),
      attachmentUrl: json['attachment_url']?.toString(),
      attachmentType: type,
      attachmentName: json['attachment_name']?.toString(),
      isProfessor: json['is_professor'] == true,
      isEdited: json['is_edited'] == true,
      editedAt: json['edited_at'] != null 
          ? DateTime.parse(json['edited_at']) 
          : null,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    String? typeStr;
    if (attachmentType == MessageAttachmentType.image) typeStr = 'image';
    if (attachmentType == MessageAttachmentType.audio) typeStr = 'audio';
    if (attachmentType == MessageAttachmentType.pdf) typeStr = 'pdf';
    if (attachmentType == MessageAttachmentType.file) typeStr = 'file';

    return {
      if (id.isNotEmpty) 'id': id,
      'subject_id': subjectId,
      'sender_id': senderId,
      'sender_name': senderName,
      'is_professor': isProfessor,
      'content': content,
      'attachment_url': attachmentUrl,
      'attachment_type': typeStr,
      'attachment_name': attachmentName,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        subjectId,
        senderId,
        senderName,
        content,
        attachmentUrl,
        attachmentType,
        attachmentName,
        isProfessor,
        isEdited,
        editedAt,
        createdAt,
      ];
}
