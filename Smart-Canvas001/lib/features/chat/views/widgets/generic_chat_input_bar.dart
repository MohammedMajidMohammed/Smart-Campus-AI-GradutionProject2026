import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:line_icons/line_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:smart_canvas/features/chat/view_models/cubit/generic_chat_cubit.dart';
import 'package:smart_canvas/features/online_sessions/models/subject_message_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';

class GenericChatInputBar extends StatefulWidget {
  final String roomId;

  const GenericChatInputBar({
    super.key,
    required this.roomId,
  });

  @override
  State<GenericChatInputBar> createState() => _GenericChatInputBarState();
}

class _GenericChatInputBarState extends State<GenericChatInputBar> {
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
      context.read<GenericChatCubit>().setTyping(widget.roomId, true);
      // Reset typing after 3 seconds of inactivity
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) context.read<GenericChatCubit>().setTyping(widget.roomId, false);
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
      context.read<GenericChatCubit>().sendMessage(widget.roomId, _controller.text.trim());
      _controller.clear();
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source, imageQuality: 70);
    if (image != null && mounted) {
      context.read<GenericChatCubit>().sendAttachment(
        roomId: widget.roomId,
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
    if (result != null && mounted) {
      final file = File(result.files.single.path!);
      final extension = result.files.single.extension?.toLowerCase();
      context.read<GenericChatCubit>().sendAttachment(
        roomId: widget.roomId,
        file: file,
        type: extension == 'pdf' ? MessageAttachmentType.pdf : MessageAttachmentType.file,
        content: result.files.single.name,
      );
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _recorder.hasPermission()) {
        final directory = await getTemporaryDirectory();
        _recordingPath = '${directory.path}/voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _recorder.start(const RecordConfig(), path: _recordingPath!);
        setState(() { _isRecording = true; _recordingSeconds = 0; });
        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) => setState(() => _recordingSeconds++));
      }
    } catch (e) { debugPrint('Error starting record: $e'); }
  }

  Future<void> _stopRecording({bool cancel = false}) async {
    _recordingTimer?.cancel();
    final path = await _recorder.stop();
    setState(() => _isRecording = false);
    if (!cancel && path != null && mounted) {
      context.read<GenericChatCubit>().sendAttachment(
        roomId: widget.roomId,
        file: File(path),
        type: MessageAttachmentType.audio,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const Color universityGreen = Color(0xFF1E8449);
    
    return BlocBuilder<GenericChatCubit, GenericChatState>(
      builder: (context, state) {
        final bool isEditing = state is GenericChatEditing;
        if (isEditing && _controller.text.isEmpty) {
          _controller.text = state.editingMessage.content ?? '';
          _controller.selection = TextSelection.fromPosition(TextPosition(offset: _controller.text.length));
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isEditing)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: universityGreen.withValues(alpha: 0.1),
                  border: Border(top: BorderSide(color: universityGreen.withValues(alpha: 0.2))),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.edit, size: 14, color: universityGreen),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'editing_message'.tr(),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: universityGreen),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        _controller.clear();
                        context.read<GenericChatCubit>().setEditingMessage(null);
                      },
                      child: const Icon(Icons.close, size: 18, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            if (_isRecording) _buildRecordingUI() else
            Container(
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
                  )
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(color: universityGreen.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: IconButton(
                        icon: const Icon(Icons.add, color: universityGreen, size: 20),
                        onPressed: () => _showAttachmentMenu(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        minLines: 1, maxLines: 5,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        decoration: InputDecoration(
                          hintText: isEditing ? 'edit_message_hint'.tr() : 'placeholder_text'.tr(), 
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
                                ? const LinearGradient(
                                    colors: [Color(0xFF1E8449), Color(0xFF10B981)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ) 
                                : null,
                            color: hasText ? null : universityGreen.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            boxShadow: hasText 
                                ? [BoxShadow(color: universityGreen.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))] 
                                : null,
                          ),
                          child: hasText 
                            ? IconButton(
                                icon: Icon(isEditing ? Icons.check : Icons.send, color: Colors.white, size: 20),
                                onPressed: _sendMessage,
                              )
                            : GestureDetector(
                                onLongPress: _startRecording,
                                onLongPressUp: () => _stopRecording(),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  child: const Icon(Icons.mic, color: universityGreen, size: 20),
                                ),
                              ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
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
            Text(
              'release_to_send'.tr(),
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  String _formatSeconds(int s) => "${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}";

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
