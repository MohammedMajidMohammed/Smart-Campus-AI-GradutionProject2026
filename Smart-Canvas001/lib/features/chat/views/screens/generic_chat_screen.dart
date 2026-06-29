import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:line_icons/line_icons.dart';
import 'package:smart_canvas/core/di/dependancy_injection.dart';
import 'package:smart_canvas/features/chat/view_models/cubit/generic_chat_cubit.dart';
import 'package:smart_canvas/features/chat/views/widgets/generic_chat_input_bar.dart';
import 'package:smart_canvas/features/chat/views/widgets/generic_chat_message_bubble.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:smart_canvas/core/cache/cache_helper.dart';

class GenericChatScreen extends StatefulWidget {
  final String roomId;
  final String roomTitle;
  final String? roomSubtitle;

  const GenericChatScreen({
    super.key,
    required this.roomId,
    required this.roomTitle,
    this.roomSubtitle,
  });

  @override
  State<GenericChatScreen> createState() => _GenericChatScreenState();
}

class _GenericChatScreenState extends State<GenericChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final _currentUserId = getIt<CacheHelper>().getUserModel()!.id;
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<GenericChatCubit>().initChat(widget.roomId);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
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

  Widget _buildDateHeader(DateTime date) {
    String dateText;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDate = DateTime(date.year, date.month, date.day);

    if (msgDate == today) {
      dateText = 'today'.tr();
    } else if (msgDate == yesterday) dateText = 'yesterday'.tr();
    else dateText = DateFormat('MMMM d, yyyy').format(date);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        dateText,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0E0A) : const Color(0xFFFAF9F5),
      appBar: AppBar(
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: _isSearching
            ? Container(
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    hintText: context.locale.languageCode == 'ar' ? 'بحث عن رسائل...' : 'Search messages...',
                    border: InputBorder.none,
                    prefixIcon: const Icon(LineIcons.search, color: Colors.white70, size: 20),
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 14),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.roomTitle,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  if (widget.roomSubtitle != null)
                    Text(
                      widget.roomSubtitle!,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.normal, color: Colors.white70),
                    ),
                ],
              ),
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                  _searchQuery = '';
                });
              },
            )
          else
            IconButton(
              icon: const Icon(LineIcons.search),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF1E1B15), const Color(0xFF0F0E0A)]
                  : [const Color(0xFF1E8449), const Color(0xFF1E8449)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocConsumer<GenericChatCubit, GenericChatState>(
              listener: (context, state) {
                if (state is GenericChatLoaded && _searchQuery.isEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                }
              },
              builder: (context, state) {
                if (state is GenericChatLoading) return const Center(child: CircularProgressIndicator());
                if (state is GenericChatError) return Center(child: Text(state.message));
                if (state is GenericChatLoaded) {
                  final messages = state.messages;
                  final filteredMessages = _searchQuery.isEmpty
                      ? messages
                      : messages.where((m) =>
                          m.content != null &&
                          m.content!.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

                  return Column(
                    children: [
                      if (_isSearching && _searchQuery.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E1B15) : const Color(0xFFE2E8F0),
                            border: Border(
                              bottom: BorderSide(
                                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(LineIcons.search, size: 16, color: Color(0xFF1E8449)),
                              const SizedBox(width: 8),
                              Text(
                                context.locale.languageCode == 'ar'
                                    ? "تم العثور على ${filteredMessages.length} من التطابقات"
                                    : "Found ${filteredMessages.length} matches",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Expanded(
                        child: filteredMessages.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(LineIcons.comment, size: 80, color: Colors.grey.withValues(alpha: 0.2)),
                                    const SizedBox(height: 16),
                                    Text(
                                      _searchQuery.isEmpty
                                          ? 'no_messages'.tr()
                                          : (context.locale.languageCode == 'ar' ? 'لا توجد رسائل مطابقة' : 'No matching messages'),
                                      style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                                itemCount: filteredMessages.length,
                                itemBuilder: (context, index) {
                                  final message = filteredMessages[index];
                                  bool showDate = index == 0 || message.createdAt.day != filteredMessages[index - 1].createdAt.day;
                                  return Column(
                                    children: [
                                      if (showDate) _buildDateHeader(message.createdAt),
                                      GenericChatMessageBubble(
                                        message: message,
                                        isMe: message.senderId == _currentUserId,
                                        searchQuery: _searchQuery,
                                      ).animate().fadeIn().slideY(begin: 0.1),
                                    ],
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          // Typing Indicator
          BlocBuilder<GenericChatCubit, GenericChatState>(
            builder: (context, state) {
              if (state is GenericChatLoaded && state.typingUsers.isNotEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1E8449)),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${state.typingUsers.values.join(', ')} ${state.typingUsers.length > 1 ? 'are_typing'.tr() : 'is_typing'.tr()}',
                        style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: isDark ? Colors.grey : Colors.grey.shade600),
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideX(begin: -0.1);
              }
              return const SizedBox();
            },
          ),
          GenericChatInputBar(roomId: widget.roomId),
        ],
      ),
    );
  }
}
