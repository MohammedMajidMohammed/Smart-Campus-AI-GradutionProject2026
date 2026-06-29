import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:smart_canvas/features/chat/models/chat_message_model.dart';
import 'package:smart_canvas/features/online_sessions/models/subject_message_model.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:smart_canvas/features/chat/view_models/cubit/generic_chat_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';

class GenericChatMessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool isMe;
  final String? searchQuery;

  const GenericChatMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRtl = Directionality.of(context) == ui.TextDirection.rtl;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            _buildAvatar(message.senderName),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            message.senderName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: isDark ? const Color(0xFF2ECC71) : const Color(0xFF145A32),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (message.senderName.toLowerCase().contains('admin') || 
                            message.senderName == 'Administrator' ||
                            message.senderName == 'Mohammed Majid Mohammed Ibrahim Mekhemer') ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.amber.withValues(alpha: 0.5), width: 0.5),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.shield, size: 8, color: Colors.amber),
                                const SizedBox(width: 2),
                                Text(
                                  'ADMIN',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.amber.shade700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                GestureDetector(
                  onLongPressStart: (details) => _showContextMenu(context, details.globalPosition),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: isMe 
                          ? const LinearGradient(
                              colors: [Color(0xFF1E8449), Color(0xFF145A32)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: !isMe 
                          ? (isDark ? const Color(0xFF1E1B15) : const Color(0xFFF1F5F9))
                          : null,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: Radius.circular(isMe ? 20 : (isRtl ? 20 : 4)),
                        bottomRight: Radius.circular(isMe ? (isRtl ? 20 : 4) : 20),
                      ),
                      border: !isMe ? Border.all(color: Colors.grey.withValues(alpha: 0.1)) : null,
                      boxShadow: [
                        BoxShadow(
                          color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildMessageContent(context, isDark),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              DateFormat('h:mm a').format(message.createdAt),
                              style: TextStyle(
                                fontSize: 10,
                                color: isMe 
                                    ? Colors.white.withValues(alpha: 0.7) 
                                    : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                              ),
                            ),
                            if (isMe) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.done_all,
                                size: 14,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            _buildAvatar('Me', isMe: true),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(String name, {bool isMe = false}) {
    final initials = isMe ? 'me'.tr().toUpperCase() : (name.isNotEmpty ? name[0].toUpperCase() : '?');
    
    final List<Color> avatarColors = [
      const Color(0xFF1E8449),
      const Color(0xFF1E8449),
      const Color(0xFF145A32),
      const Color(0xFF10B981),
      const Color(0xFF64748B),
    ];
    final colorIndex = name.hashCode.abs() % avatarColors.length;
    final color = avatarColors[colorIndex];

    return CircleAvatar(
      radius: 16,
      backgroundColor: isMe ? const Color(0xFF1E8449).withValues(alpha: 0.2) : color.withValues(alpha: 0.15),
      child: Text(
        initials,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: isMe ? const Color(0xFF1E8449) : color,
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context, Offset tapPosition) {
    if (!isMe) return;

    final cubit = context.read<GenericChatCubit>();
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    
    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        tapPosition & const Size(40, 40),
        Offset.zero & overlay.size,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      items: [
        if (message.attachmentType == MessageAttachmentType.text)
          PopupMenuItem(
            onTap: () => cubit.setEditingMessage(message),
            child: Row(
              children: [
                const Icon(Icons.edit, color: Color(0xFF1E8449), size: 20),
                const SizedBox(width: 12),
                Text('edit'.tr(), style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        PopupMenuItem(
          onTap: () => _confirmDelete(context, cubit),
          child: Row(
            children: [
              const Icon(Icons.delete, color: Colors.red, size: 20),
              const SizedBox(width: 12),
              Text('delete'.tr(), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, GenericChatCubit cubit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('confirm_delete_title'.tr()),
        content: Text('confirm_delete_message'.tr()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('cancel'.tr())),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              cubit.deleteMessage(message.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('delete'.tr(), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context, bool isDark) {
    switch (message.attachmentType) {
      case MessageAttachmentType.image:
        return _buildImageContent(context, isDark);
      case MessageAttachmentType.audio:
        return _buildAudioContent(isDark);
      case MessageAttachmentType.pdf:
      case MessageAttachmentType.file:
        return _buildFileContent(isDark);
      default:
        final text = message.content ?? '';
        if (searchQuery != null && searchQuery!.isNotEmpty && text.toLowerCase().contains(searchQuery!.toLowerCase())) {
          return _buildHighlightedText(text, searchQuery!, isDark);
        }
        return Text(
          text,
          style: TextStyle(
            color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black87),
            fontSize: 15,
          ),
        );
    }
  }

  Widget _buildHighlightedText(String text, String query, bool isDark) {
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    
    final List<TextSpan> spans = [];
    int start = 0;
    int index;
    
    while ((index = lowerText.indexOf(lowerQuery, start)) != -1) {
      if (index > start) {
        spans.add(TextSpan(
          text: text.substring(start, index),
          style: TextStyle(
            color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black87),
            fontSize: 15,
          ),
        ));
      }
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: const TextStyle(
          color: Colors.black87,
          backgroundColor: Colors.amberAccent,
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ));
      start = index + query.length;
    }
    
    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start),
        style: TextStyle(
          color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black87),
          fontSize: 15,
        ),
      ));
    }
    
    return RichText(
      text: TextSpan(children: spans),
    );
  }

  Widget _buildImageContent(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _showFullScreenImage(context, message.attachmentUrl!),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: message.attachmentUrl!,
              placeholder: (context, url) => Container(height: 200, color: Colors.grey.shade200, child: const Center(child: CircularProgressIndicator())),
              errorWidget: (context, url, error) => const Icon(Icons.error),
              fit: BoxFit.cover,
            ),
          ),
        ),
        if (message.content != null && message.content!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(message.content!, style: TextStyle(color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black87))),
          ),
      ],
    );
  }

  Widget _buildAudioContent(bool isDark) {
    return _GenericAudioPlayerWidget(url: message.attachmentUrl!, isMe: isMe, isDark: isDark);
  }

  Widget _buildFileContent(bool isDark) {
    final isPdf = message.attachmentType == MessageAttachmentType.pdf;
    return GestureDetector(
      onTap: () async {
        final url = Uri.parse(message.attachmentUrl!);
        if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: (isMe ? Colors.white : const Color(0xFF1E8449)).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isPdf ? LineIcons.pdfFile : LineIcons.file, color: isMe ? Colors.white : const Color(0xFF2ECC71)),
            const SizedBox(width: 8),
            Flexible(child: Text(message.attachmentName ?? 'file'.tr(), style: TextStyle(color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black87), fontWeight: FontWeight.bold, overflow: TextOverflow.ellipsis))),
          ],
        ),
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String url) {
    showDialog(context: context, builder: (_) => Dialog(backgroundColor: Colors.transparent, insetPadding: EdgeInsets.zero, child: Stack(children: [InteractiveViewer(child: Center(child: CachedNetworkImage(imageUrl: url))), Positioned(top: 40, right: 20, child: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 30), onPressed: () => Navigator.pop(context)))])));
  }
}

class _GenericAudioPlayerWidget extends StatefulWidget {
  final String url; final bool isMe; final bool isDark;
  const _GenericAudioPlayerWidget({required this.url, required this.isMe, required this.isDark});
  @override State<_GenericAudioPlayerWidget> createState() => _GenericAudioPlayerWidgetState();
}

class _GenericAudioPlayerWidgetState extends State<_GenericAudioPlayerWidget> {
  late AudioPlayer _audioPlayer; bool _isPlaying = false; Duration _duration = Duration.zero; Duration _position = Duration.zero;
  @override void initState() { super.initState(); _audioPlayer = AudioPlayer(); _audioPlayer.onDurationChanged.listen((d) => setState(() => _duration = d)); _audioPlayer.onPositionChanged.listen((p) => setState(() => _position = p)); _audioPlayer.onPlayerComplete.listen((_) => setState(() { _isPlaying = false; _position = Duration.zero; })); }
  @override void dispose() { _audioPlayer.dispose(); super.dispose(); }
  Future<void> _togglePlay() async { if (_isPlaying) {
    await _audioPlayer.pause();
  } else {
    await _audioPlayer.play(UrlSource(widget.url));
  } setState(() => _isPlaying = !_isPlaying); }
  @override Widget build(BuildContext context) { final color = widget.isMe ? Colors.white : const Color(0xFF2ECC71); return Row(mainAxisSize: MainAxisSize.min, children: [IconButton(onPressed: _togglePlay, icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: color), padding: EdgeInsets.zero, constraints: const BoxConstraints()), SizedBox(width: 120, child: Slider(activeColor: color, inactiveColor: color.withValues(alpha: 0.3), min: 0, max: _duration.inSeconds.toDouble(), value: _position.inSeconds.toDouble().clamp(0, _duration.inSeconds.toDouble()), onChanged: (value) async => await _audioPlayer.seek(Duration(seconds: value.toInt())))), Text(_formatDuration(_duration - _position), style: TextStyle(color: color, fontSize: 10))]); }
  String _formatDuration(Duration d) { String twoDigits(int n) => n.toString().padLeft(2, "0"); return "${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}"; }
}
