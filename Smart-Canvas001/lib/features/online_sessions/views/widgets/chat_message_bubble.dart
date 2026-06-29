import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:smart_canvas/features/online_sessions/models/subject_message_model.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:smart_canvas/features/online_sessions/view_models/cubit/subject_chat_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';

class ChatMessageBubble extends StatelessWidget {
  final SubjectMessageModel message;
  final bool isMe;
  final bool isProfessor;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.isProfessor = false,
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
            _buildAvatar(message.senderName ?? 'U'),
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
                        Text(
                          message.senderName ?? 'user'.tr(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                            color: isDark ? const Color(0xFF2ECC71) : const Color(0xFF145A32),
                          ),
                        ),
                        if (message.isProfessor) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF2ECC71), Color(0xFF1E8449)]),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [BoxShadow(color: const Color(0xFF1E8449).withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2))],
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.verified, size: 10, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  'dr'.tr().toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
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
                          ? AppColors.primaryGradient
                          : null,
                      color: !isMe 
                          ? (isDark ? const Color(0xFF1E1B15) : Colors.white)
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
                            if (message.isEdited && message.editedAt != null) ...[
                              const SizedBox(width: 6),
                              Text(
                                '(${'edited'.tr()} ${DateFormat('h:mm a').format(message.editedAt!)})',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w500,
                                  color: isMe 
                                      ? Colors.white.withValues(alpha: 0.6) 
                                      : (isDark ? Colors.grey.shade500 : Colors.grey.shade500),
                                ),
                              ),
                            ],
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
    final initials = isMe ? 'me'.tr().toUpperCase() : name.split(' ').take(2).map((e) => e[0].toUpperCase()).join();
    
    // Dynamic premium colors based on name (university green-themed & cohesive palette)
    final List<Color> avatarColors = [
      AppColors.kPrimaryColor,
      AppColors.kSecondaryColor,
      const Color(0xFF145A32),
      const Color(0xFF1E3A8A), // Deep Blue
      const Color(0xFF0D9488), // Teal
      const Color(0xFF4F46E5), // Indigo
      const Color(0xFF0369A1), // Sky
    ];
    final colorIndex = name.hashCode.abs() % avatarColors.length;
    final color = avatarColors[colorIndex];

    return CircleAvatar(
      radius: 16,
      backgroundColor: isMe ? AppColors.kPrimaryColor.withValues(alpha: 0.2) : color.withValues(alpha: 0.15),
      child: Text(
        initials,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: isMe ? AppColors.kPrimaryColor : color,
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context, Offset tapPosition) {
    final cubit = context.read<SubjectChatCubit>();
    final canEdit = isMe && message.attachmentType == MessageAttachmentType.text;
    final canDelete = isMe || isProfessor;

    if (!canEdit && !canDelete) return;

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
        if (canEdit)
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
        if (canDelete)
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

  void _confirmDelete(BuildContext context, SubjectChatCubit cubit) {
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

  Widget _buildFormattedText(String text, bool isMe, bool isDark) {
    final baseColor = isMe ? Colors.white : (isDark ? Colors.white : Colors.black87);
    final linkColor = isMe ? const Color(0xFFFEF08A) : AppColors.kSecondaryColor;

    final baseStyle = TextStyle(
      color: baseColor,
      fontSize: 14.5,
      height: 1.35,
    );

    final boldStyle = TextStyle(
      color: baseColor,
      fontSize: 14.5,
      fontWeight: FontWeight.bold,
      height: 1.35,
    );

    final linkStyle = TextStyle(
      color: linkColor,
      fontSize: 14.5,
      fontWeight: FontWeight.bold,
      decoration: TextDecoration.underline,
      height: 1.35,
    );

    final lines = text.split('\n');
    List<Widget> lineWidgets = [];

    for (final line in lines) {
      List<InlineSpan> spans = [];
      final regex = RegExp(r'(https?:\/\/[^\s]+)|\*([^*]+)\*');
      int lastIndex = 0;

      for (final match in regex.allMatches(line)) {
        if (match.start > lastIndex) {
          spans.add(TextSpan(
            text: line.substring(lastIndex, match.start),
            style: baseStyle,
          ));
        }

        if (match.group(1) != null) {
          final url = match.group(1)!;
          spans.add(WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: GestureDetector(
              onTap: () async {
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: Text(
                url,
                style: linkStyle,
              ),
            ),
          ));
        } else if (match.group(2) != null) {
          final boldText = match.group(2)!;
          spans.add(TextSpan(
            text: boldText,
            style: boldStyle,
          ));
        }

        lastIndex = match.end;
      }

      if (lastIndex < line.length) {
        spans.add(TextSpan(
          text: line.substring(lastIndex),
          style: baseStyle,
        ));
      }

      lineWidgets.add(
        RichText(
          text: TextSpan(children: spans),
        ),
      );
    }

    if (lineWidgets.length == 1) {
      return lineWidgets[0];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lineWidgets.map((w) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: w,
      )).toList(),
    );
  }

  Widget _buildMessageContent(BuildContext context, bool isDark) {
    switch (message.attachmentType) {
      case MessageAttachmentType.image:
        return _buildImageContent(context);
      case MessageAttachmentType.audio:
        return _buildAudioContent(isDark);
      case MessageAttachmentType.pdf:
      case MessageAttachmentType.file:
        return _buildFileContent(isDark);
      default:
        return _buildFormattedText(message.content ?? '', isMe, isDark);
    }
  }

  Widget _buildImageContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            _showFullScreenImage(context, message.attachmentUrl!);
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: message.attachmentUrl!,
              placeholder: (context, url) => Container(
                height: 200,
                color: Colors.grey.shade200,
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => const Icon(Icons.error),
              fit: BoxFit.cover,
            ),
          ),
        ),
        if (message.content != null && message.content!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _buildFormattedText(message.content!, isMe, isDark),
          ),
      ],
    );
  }

  Widget _buildAudioContent(bool isDark) {
    return AudioPlayerWidget(
      url: message.attachmentUrl!,
      isMe: isMe,
      isDark: isDark,
    );
  }

  Widget _buildFileContent(bool isDark) {
    final isPdf = message.attachmentType == MessageAttachmentType.pdf;
    return GestureDetector(
      onTap: () async {
        final url = Uri.parse(message.attachmentUrl!);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (isMe ? Colors.white : const Color(0xFF1E8449)).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPdf ? LineIcons.pdfFile : LineIcons.file,
              color: isMe ? Colors.white : const Color(0xFF2ECC71),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message.attachmentName ?? 'file'.tr(),
                style: TextStyle(
                  color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black87),
                  fontWeight: FontWeight.bold,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(
              child: Center(child: CachedNetworkImage(imageUrl: url)),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AudioPlayerWidget extends StatefulWidget {
  final String url;
  final bool isMe;
  final bool isDark;

  const AudioPlayerWidget({
    super.key,
    required this.url,
    required this.isMe,
    required this.isDark,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    
    _audioPlayer.onDurationChanged.listen((d) => setState(() => _duration = d));
    _audioPlayer.onPositionChanged.listen((p) => setState(() => _position = p));
    _audioPlayer.onPlayerComplete.listen((_) {
      setState(() {
        _isPlaying = false;
        _position = Duration.zero;
      });
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play(UrlSource(widget.url));
    }
    setState(() => _isPlaying = !_isPlaying);
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isMe ? Colors.white : const Color(0xFF2ECC71);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: _togglePlay,
          icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: color),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        SizedBox(
          width: 120,
          child: Slider(
            activeColor: color,
            inactiveColor: color.withValues(alpha: 0.3),
            min: 0,
            max: _duration.inSeconds.toDouble(),
            value: _position.inSeconds.toDouble().clamp(0, _duration.inSeconds.toDouble()),
            onChanged: (value) async {
              await _audioPlayer.seek(Duration(seconds: value.toInt()));
            },
          ),
        ),
        Text(
          _formatDuration(_duration - _position),
          style: TextStyle(color: color, fontSize: 10),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}
