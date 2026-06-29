import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:line_icons/line_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:smart_canvas/features/online_sessions/models/subject_message_model.dart';
import 'package:smart_canvas/features/online_sessions/view_models/cubit/subject_chat_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';

class ChatInputBar extends StatefulWidget {
  const ChatInputBar({super.key});

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _controller = TextEditingController();
  late AudioRecorder _recorder;
  bool _isRecording = false;
  String? _recordingPath;
  Timer? _recordingTimer;
  Timer? _typingTimer;
  int _recordingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _recorder = AudioRecorder();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (_controller.text.isNotEmpty) {
      context.read<SubjectChatCubit>().setTyping(true);
      // Reset typing after 3 seconds of inactivity
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) context.read<SubjectChatCubit>().setTyping(false);
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _recorder.dispose();
    _recordingTimer?.cancel();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _sendMessage() {
    if (_controller.text.trim().isNotEmpty) {
      context.read<SubjectChatCubit>().sendText(_controller.text);
      _controller.clear();
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source, imageQuality: 70);
    
    if (image != null) {
      if (!mounted) return;
      context.read<SubjectChatCubit>().sendAttachment(
        file: File(image.path),
        type: MessageAttachmentType.image,
      );
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt'],
    );

    if (result != null) {
      final file = File(result.files.single.path!);
      final extension = result.files.single.extension?.toLowerCase();
      final type = extension == 'pdf' ? MessageAttachmentType.pdf : MessageAttachmentType.file;
      
      if (!mounted) return;
      context.read<SubjectChatCubit>().sendAttachment(
        file: file,
        type: type,
        content: result.files.single.name,
      );
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _recorder.hasPermission()) {
        final directory = await getTemporaryDirectory();
        _recordingPath = '${directory.path}/voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        const config = RecordConfig();
        await _recorder.start(config, path: _recordingPath!);
        
        setState(() {
          _isRecording = true;
          _recordingSeconds = 0;
        });
        
        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() => _recordingSeconds++);
        });
      }
    } catch (e) {
      print('Error starting record: $e');
    }
  }

  Future<void> _stopRecording({bool cancel = false}) async {
    _recordingTimer?.cancel();
    final path = await _recorder.stop();
    
    setState(() => _isRecording = false);

    if (!cancel && path != null) {
      if (!mounted) return;
      context.read<SubjectChatCubit>().sendAttachment(
        file: File(path),
        type: MessageAttachmentType.audio,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BlocListener<SubjectChatCubit, SubjectChatState>(
      listenWhen: (previous, current) => current is SubjectChatEditing || (previous is SubjectChatEditing && current is! SubjectChatEditing),
      listener: (context, state) {
        if (state is SubjectChatEditing) {
          _controller.text = state.editingMessage?.content ?? '';
          _controller.selection = TextSelection.fromPosition(TextPosition(offset: _controller.text.length));
        } else if (state is SubjectChatLoaded && state.editingMessage == null) {
          _controller.clear();
        }
      },
      child: BlocBuilder<SubjectChatCubit, SubjectChatState>(
        builder: (context, state) {
          final isEditing = state is SubjectChatEditing;
          
          if (_isRecording) {
            return _buildRecordingUI();
          }

          return Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1B15) : Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isEditing)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2ECC71).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.edit, size: 16, color: Color(0xFF2ECC71)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'edit_mode'.tr(),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2ECC71)),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.read<SubjectChatCubit>().setEditingMessage(null),
                            child: const Icon(Icons.close, size: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF2ECC71).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.add, color: Color(0xFF2ECC71), size: 20),
                          onPressed: isEditing ? null : () => _showAttachmentMenu(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          minLines: 1,
                          maxLines: 5,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                          decoration: InputDecoration(
                            hintText: 'placeholder_text'.tr(),
                            hintStyle: TextStyle(color: Colors.grey.withValues(alpha: 0.6)),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _controller,
                        builder: (context, value, child) {
                          final bool hasText = value.text.trim().isNotEmpty;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              gradient: hasText 
                                  ? AppColors.primaryGradient
                                  : null,
                              color: hasText ? null : const Color(0xFF2ECC71).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                              boxShadow: hasText ? [
                                BoxShadow(
                                  color: const Color(0xFF2ECC71).withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                )
                              ] : null,
                            ),
                            child: hasText 
                              ? IconButton(
                                  icon: Icon(isEditing ? Icons.check : Icons.send, color: Colors.white, size: 20),
                                  onPressed: _sendMessage,
                                )
                              : GestureDetector(
                                  onLongPress: isEditing ? null : _startRecording,
                                  onLongPressUp: isEditing ? null : () => _stopRecording(),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    child: Icon(Icons.mic, color: isEditing ? Colors.grey : const Color(0xFF2ECC71), size: 20),
                                  ),
                                ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecordingUI() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            const Icon(Icons.mic, color: Colors.red),
            const SizedBox(width: 8),
            Text(
              '${'recording'.tr()}: ${_formatSeconds(_recordingSeconds)}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => _stopRecording(cancel: true),
              child: Text('cancel'.tr(), style: const TextStyle(color: Colors.grey)),
            ),
            const SizedBox(width: 8),
            Text('release_to_send'.tr(), style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  String _formatSeconds(int seconds) {
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remaining.toString().padLeft(2, '0')}';
  }

  void _showAttachmentMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _attachmentOption(LineIcons.image, 'gallery'.tr(), Colors.purple, () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                }),
                _attachmentOption(LineIcons.camera, 'camera'.tr(), Colors.orange, () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                }),
                _attachmentOption(LineIcons.pdfFile, 'file'.tr(), Colors.red, () {
                  Navigator.pop(context);
                  _pickFile();
                }),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _attachmentOption(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
