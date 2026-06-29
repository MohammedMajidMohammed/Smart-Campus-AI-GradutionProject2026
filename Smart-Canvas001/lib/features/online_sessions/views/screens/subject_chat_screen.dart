import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:line_icons/line_icons.dart';
import 'package:smart_canvas/core/di/dependancy_injection.dart';
import 'package:smart_canvas/features/online_sessions/view_models/cubit/subject_chat_cubit.dart';
import 'package:smart_canvas/features/online_sessions/views/widgets/chat_input_bar.dart';
import 'package:smart_canvas/features/online_sessions/views/widgets/chat_message_bubble.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:smart_canvas/core/cache/cache_helper.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';

class SubjectChatScreen extends StatefulWidget {
  final String subjectId;
  final String subjectName;

  const SubjectChatScreen({
    super.key,
    required this.subjectId,
    required this.subjectName,
  });

  @override
  State<SubjectChatScreen> createState() => _SubjectChatScreenState();
}

class _SubjectChatScreenState extends State<SubjectChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final _userModel = getIt<CacheHelper>().getUserModel()!;
  late final String _currentUserId;
  late final bool _isProfessor;

  @override
  void initState() {
    super.initState();
    _currentUserId = _userModel.id;
    _isProfessor = _userModel.roleName.toLowerCase() == 'professor';
    context.read<SubjectChatCubit>().initChat(widget.subjectId);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildDateHeader(DateTime date) {
    String dateText;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDate = DateTime(date.year, date.month, date.day);

    if (msgDate == today) {
      dateText = 'today'.tr();
    } else if (msgDate == yesterday) {
      dateText = 'yesterday'.tr();
    } else {
      dateText = DateFormat('MMMM d, yyyy', context.locale.toString()).format(date);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? Colors.white10 
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        dateText,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade600,
        ),
      ),
    );
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0E0A) : const Color(0xFFFAF9F5),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LineIcons.book, size: 16, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Text(widget.subjectName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            Text('chat_title'.tr(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            tooltip: 'Language',
            onPressed: () {
              if (context.locale == const Locale('ar')) {
                context.setLocale(const Locale('en'));
              } else {
                context.setLocale(const Locale('ar'));
              }
            },
          ),
          IconButton(
            icon: const Icon(LineIcons.infoCircle),
            onPressed: () {
              // Show subject info or members
            },
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Premium subtle wallpaper pattern
          Positioned.fill(
            child: Opacity(
              opacity: isDark ? 0.03 : 0.05,
              child: Image.asset(
                'assets/images/chat_bg.png', // Ideally a tileable pattern
                repeat: ImageRepeat.repeat,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: isDark ? Colors.black12 : Colors.grey.withValues(alpha: 0.05),
                ),
              ),
            ),
          ),
          Column(
            children: [
          Expanded(
            child: BlocConsumer<SubjectChatCubit, SubjectChatState>(
              listener: (context, state) {
                if (state is SubjectChatLoaded) {
                  WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                }
              },
              builder: (context, state) {
                if (state is SubjectChatLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is SubjectChatError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 60, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('error_msg'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 8),
                        Text(state.message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => context.read<SubjectChatCubit>().initChat(widget.subjectId),
                          icon: const Icon(Icons.refresh),
                          label: Text('retry'.tr()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2ECC71),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  );
                } else if (state is SubjectChatLoaded) {
                  final messages = state.messages;
                  
                  if (messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LineIcons.comment, size: 100, color: const Color(0xFF2ECC71).withValues(alpha: 0.1)),
                          const SizedBox(height: 24),
                          Text(
                            'no_messages'.tr(), 
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Text(
                              'no_messages_desc'.tr(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final bool isMe = message.senderId == _currentUserId;
                      
                      // Date grouping logic
                      bool showDateHeader = false;
                      if (index == 0) {
                        showDateHeader = true;
                      } else {
                        final prevDate = messages[index - 1].createdAt;
                        if (message.createdAt.day != prevDate.day || 
                            message.createdAt.month != prevDate.month ||
                            message.createdAt.year != prevDate.year) {
                          showDateHeader = true;
                        }
                      }

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (showDateHeader) _buildDateHeader(message.createdAt),
                          ChatMessageBubble(
                            message: message,
                            isMe: isMe,
                            isProfessor: _isProfessor,
                          ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, curve: Curves.easeOutQuad),
                        ],
                      );
                    },
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          
          // Show uploading indicator if needed
          BlocBuilder<SubjectChatCubit, SubjectChatState>(
            builder: (context, state) {
              if (state is SubjectChatUploading) {
                return Container(
                  padding: const EdgeInsets.all(8),
                  color: const Color(0xFF1E8449).withValues(alpha: 0.1),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2ECC71)))),
                      const SizedBox(width: 12),
                      Text('sending'.tr(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2ECC71))),
                    ],
                  ),
                );
              }
              return const SizedBox();
            },
          ),

          // Typing Indicator
          BlocBuilder<SubjectChatCubit, SubjectChatState>(
            builder: (context, state) {
              if (state is SubjectChatLoaded && state.typingUsers.isNotEmpty) {
                final names = state.typingUsers.values.join(', ');
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 12, height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2ECC71)),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$names ${state.typingUsers.length > 1 ? 'are_typing'.tr() : 'is_typing'.tr()}',
                        style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: isDark ? Colors.grey : Colors.grey.shade600),
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideX(begin: -0.1);
              }
              return const SizedBox();
            },
          ),
          const ChatInputBar(),
            ],
          ),
        ],
      ),
    );
  }
}
