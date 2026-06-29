import 'package:smart_canvas/features/online_sessions/models/subject_message_model.dart';

class ChatMessageModel {
  final String id;
  final String roomId;
  final String senderId;
  final String senderName;
  final String? content;
  final String? attachmentUrl;
  final MessageAttachmentType attachmentType;
  final String? attachmentName;
  final bool isRead;
  final DateTime createdAt;

  ChatMessageModel({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.senderName,
    this.content,
    this.attachmentUrl,
    this.attachmentType = MessageAttachmentType.text,
    this.attachmentName,
    this.isRead = false,
    required this.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    MessageAttachmentType type = MessageAttachmentType.text;
    final typeStr = json['attachment_type']?.toString();
    if (typeStr == 'image') type = MessageAttachmentType.image;
    if (typeStr == 'audio') type = MessageAttachmentType.audio;
    if (typeStr == 'pdf') type = MessageAttachmentType.pdf;
    if (typeStr == 'file') type = MessageAttachmentType.file;

    return ChatMessageModel(
      id: json['id']?.toString() ?? '',
      roomId: json['room_id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      senderName: json['sender_name']?.toString() ?? 'User',
      content: json['content']?.toString(),
      attachmentUrl: json['attachment_url']?.toString(),
      attachmentType: type,
      attachmentName: json['attachment_name']?.toString(),
      isRead: json['is_read'] == true,
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
      'room_id': roomId,
      'sender_id': senderId,
      'sender_name': senderName,
      'content': content,
      'attachment_url': attachmentUrl,
      'attachment_type': typeStr,
      'attachment_name': attachmentName,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ChatMessageModel copyWith({
    String? id,
    String? roomId,
    String? senderId,
    String? senderName,
    String? content,
    String? attachmentUrl,
    MessageAttachmentType? attachmentType,
    String? attachmentName,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      content: content ?? this.content,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      attachmentType: attachmentType ?? this.attachmentType,
      attachmentName: attachmentName ?? this.attachmentName,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
