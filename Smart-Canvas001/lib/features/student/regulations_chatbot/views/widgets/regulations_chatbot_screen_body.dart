import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:line_icons/line_icons.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:smart_canvas/features/student/regulations_chatbot/view_models/cubit/regulations_chatbot_cubit.dart';
import 'package:smart_canvas/features/student/regulations_chatbot/views/widgets/regulations_chat_input_bar.dart';
import 'package:smart_canvas/features/student/regulations_chatbot/views/widgets/regulations_messages_list_view.dart';

class RegulationsChatbotScreenBody extends StatelessWidget {
  const RegulationsChatbotScreenBody({super.key});

  @override
  Widget build(BuildContext context) {
    var cubit = context.read<RegulationsChatbotCubit>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<RegulationsChatbotCubit, RegulationsChatbotState>(
      listener: (context, state) {
        if (state is ChatbotError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text(state.message)),
                ],
              ),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F0E0A) : const Color(0xFFFAF9F5),
        drawer: _buildHistoryDrawer(context, cubit, isDark),
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF1E1B15) : Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsetsDirectional.only(start: 12.0, top: 8.0, bottom: 8.0),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200,
                width: 1.2,
              ),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: isDark ? Colors.white70 : const Color(0xFF0F0E0A),
                size: 16,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        centerTitle: true,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.kPrimaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(LineIcons.balanceScale, color: AppColors.kPrimaryColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'academic_bot'.tr(),
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF0F0E0A),
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFF2ECC71),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2ECC71).withValues(alpha: 0.5),
                      blurRadius: 6,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200,
                  width: 1.2,
                ),
              ),
              child: Builder(
                builder: (context) => IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.history_rounded,
                    color: isDark ? Colors.white70 : const Color(0xFF0F0E0A),
                    size: 18,
                  ),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 12.0, top: 8.0, bottom: 8.0),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200,
                  width: 1.2,
                ),
              ),
              child: PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: isDark ? Colors.white70 : const Color(0xFF0F0E0A),
                  size: 18,
                ),
                onSelected: (value) {
                  if (value == 'clear') {
                    _showClearConfirmation(context, cubit);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'clear',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'clear_chat_history'.tr(),
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(child: RegulationsMessagesListView(cubit: cubit)),
          RegulationsChatInputBar(cubit: cubit),
          SizedBox(height: MediaQuery.of(context).padding.bottom > 0 ? 0 : 8),
        ],
      ),
    ),
  );
}

  void _showClearConfirmation(BuildContext context, RegulationsChatbotCubit cubit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('clear_history_confirm_title'.tr()),
        content: Text('clear_history_confirm_message'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              cubit.clearHistory();
              Navigator.pop(context);
            },
            child: Text(
              'delete'.tr(),
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryDrawer(BuildContext context, RegulationsChatbotCubit cubit, bool isDark) {
    return Drawer(
      backgroundColor: isDark ? const Color(0xFF13120E) : const Color(0xFFFBFBFA),
      elevation: 0,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                    color: AppColors.kPrimaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LineIcons.balanceScale,
                    color: AppColors.kPrimaryColor,
                    size: 18,
                  ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'chat_history'.tr(),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white70 : Colors.black87,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
            
            // Custom New Chat Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.kPrimaryColor.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      cubit.createNewSession();
                      Navigator.pop(context); // Close Drawer
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'new_chat'.tr(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Elegant thin separator
            Container(
              height: 1,
              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
              margin: const EdgeInsets.symmetric(vertical: 12),
            ),
            
            // Sessions List
            Expanded(
              child: BlocBuilder<RegulationsChatbotCubit, RegulationsChatbotState>(
                builder: (context, state) {
                  return ListView.builder(
                    itemCount: cubit.sessions.length,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemBuilder: (context, index) {
                      final session = cubit.sessions[index];
                      final isSelected = session.id == cubit.currentSession?.id;
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.kPrimaryColor.withValues(alpha: 0.06)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.kPrimaryColor.withValues(alpha: 0.12)
                                  : Colors.transparent,
                              width: 1,
                            ),
                          ),
                          child: InkWell(
                            onTap: () {
                              cubit.selectSession(session);
                              Navigator.pop(context); // Close Drawer
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              child: Row(
                                children: [
                                  // Selected Accent Line Indicator (Gold)
                                  if (isSelected)
                                    Container(
                                      width: 3.5,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        color: AppColors.kPrimaryColor,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    )
                                  else
                                    const SizedBox(width: 3.5),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    color: isSelected
                                        ? AppColors.kPrimaryColor
                                        : (isDark ? Colors.white30 : Colors.black38),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      session.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                        color: isSelected
                                            ? AppColors.kPrimaryColor
                                            : (isDark ? Colors.white70 : Colors.black87),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () {
                                      _showDeleteSessionConfirmation(context, cubit, session.id);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isSelected
                                            ? AppColors.kPrimaryColor.withValues(alpha: 0.08)
                                            : Colors.transparent,
                                      ),
                                      child: Icon(
                                        Icons.delete_outline_rounded,
                                        color: isSelected
                                            ? AppColors.kPrimaryColor.withValues(alpha: 0.7)
                                            : (isDark ? Colors.white30 : Colors.black26),
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteSessionConfirmation(BuildContext context, RegulationsChatbotCubit cubit, String sessionId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('confirm_delete_session_title'.tr()),
        content: Text('confirm_delete_session_msg'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              cubit.deleteSession(sessionId);
              Navigator.pop(context);
            },
            child: Text(
              'delete'.tr(),
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
}
