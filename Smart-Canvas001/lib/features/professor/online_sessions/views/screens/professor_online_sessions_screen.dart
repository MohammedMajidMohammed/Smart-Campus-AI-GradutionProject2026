import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:line_icons/line_icons.dart';
import 'package:smart_canvas/features/online_sessions/models/online_session_model.dart';
import 'package:smart_canvas/features/online_sessions/view_models/cubit/online_sessions_cubit.dart';
import 'package:smart_canvas/features/online_sessions/views/widgets/create_online_session_dialog.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smart_canvas/core/di/dependancy_injection.dart';
import 'package:smart_canvas/features/online_sessions/services/subject_chat_service.dart';
import 'package:easy_localization/easy_localization.dart';

class ProfessorOnlineSessionsScreen extends StatelessWidget {
  const ProfessorOnlineSessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0E0A) : const Color(0xFFFAF9F5),
      appBar: AppBar(
        title: Text(
          'my_online_sessions'.tr(), 
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -0.5)
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E8449), Color(0xFF2ECC71)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            colors: [Color(0xFF2ECC71), Color(0xFF1E8449)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2ECC71).withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          backgroundColor: Colors.transparent,
          elevation: 0,
          onPressed: () {
            _showCreateEditDialog(context);
          },
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: Text(
            'schedule_new'.tr(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
      body: BlocBuilder<OnlineSessionsCubit, OnlineSessionsState>(
        buildWhen: (previous, current) => 
            current is OnlineSessionsLoading || 
            current is OnlineSessionsLoaded || 
            current is OnlineSessionsError,
        builder: (context, state) {
          if (state is OnlineSessionsLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is OnlineSessionsError) {
            return Center(child: Text('Error: ${state.message}'));
          } else if (state is OnlineSessionsLoaded) {
            final sessions = state.sessions;
            
            if (sessions.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LineIcons.video, size: 80, color: Colors.grey.withValues(alpha: 0.3)),
                    const SizedBox(height: 16),
                    Text(
                      'no_sessions'.tr(),
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ).animate().fadeIn();
            }

            return RefreshIndicator(
              onRefresh: () => context.read<OnlineSessionsCubit>().loadProfessorSessions(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: sessions.length,
                itemBuilder: (context, index) {
                  final session = sessions[index];
                  final isUnderway = session.startTime.isBefore(DateTime.now()) &&
                      session.startTime.add(Duration(minutes: session.durationMinutes)).isAfter(DateTime.now());
                  final isUpcoming = session.startTime.isAfter(DateTime.now());
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildSessionCard(context, session, isUnderway, isUpcoming, isDark),
                  ).animate().fadeIn(delay: (50 * index).ms).slideY(begin: 0.05);
                },
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildSessionCard(BuildContext context, OnlineSessionModel session, bool isUnderway, bool isUpcoming, bool isDark) {
    final isActive = isUnderway || isUpcoming;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1B15) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Tags Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2ECC71).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          session.subjectName ?? 'Subject',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF1E8449),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isUnderway 
                                  ? const Color(0xFFEF4444) 
                                  : isUpcoming 
                                      ? const Color(0xFF10B981) 
                                      : Colors.grey)
                              .withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: isUnderway 
                                    ? const Color(0xFFEF4444) 
                                    : isUpcoming 
                                        ? const Color(0xFF10B981) 
                                        : Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isUnderway 
                                  ? 'live_now'.tr() 
                                  : isUpcoming 
                                      ? 'upcoming'.tr() 
                                      : 'finished'.tr(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: isUnderway 
                                    ? const Color(0xFFEF4444) 
                                    : isUpcoming 
                                        ? const Color(0xFF10B981) 
                                        : Colors.grey,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Title + Menu Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          session.title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: isDark ? Colors.white : const Color(0xFF0F0E0A),
                          ),
                        ),
                      ),
                      _buildActionsMenu(context, session, isDark),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Date & Time Details
                  Row(
                    children: [
                      _buildMiniInfo(LineIcons.calendar, DateFormat('MMM d, yyyy').format(session.startTime), isDark),
                      const SizedBox(width: 16),
                      _buildMiniInfo(LineIcons.clock, DateFormat('h:mm a').format(session.startTime), isDark),
                    ],
                  ),
                ],
              ),
            ),

            // Action Button
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: isActive
                    ? LinearGradient(
                        colors: isUnderway
                            ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                            : [const Color(0xFF1E8449), const Color(0xFF2ECC71)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      )
                    : null,
                color: isActive ? null : (isDark ? const Color(0xFF2A2720) : const Color(0xFFF1F5F9)),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    final url = Uri.parse(session.meetingLink);
                    if (isActive) {
                      getIt<SubjectChatService>().sendTextMessage(
                        session.subjectId, 
                        '🚀 *${"meeting_started".tr()}: ${session.title}*\n\n🔗 *${"join_session_here".tr()}:* ${session.meetingLink}\n\n📢 ${"join_conversation_now".tr()}'
                      );
                    }
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  },
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LineIcons.video, 
                          color: isActive ? Colors.white : (isDark ? Colors.white38 : Colors.grey.shade500), 
                          size: 20
                        ),
                        const SizedBox(width: 10),
                        Text(
                          isUnderway 
                              ? '${'launch_meeting'.tr()} (${'live_now'.tr()})'.toUpperCase()
                              : isUpcoming 
                                  ? 'launch_meeting'.tr() 
                                  : '${'launch_meeting'.tr()} (${'finished'.tr()})',
                          style: TextStyle(
                            fontSize: 15,
                            color: isActive ? Colors.white : (isDark ? Colors.white30 : Colors.grey.shade600),
                            fontWeight: FontWeight.w900,
                            letterSpacing: isUnderway ? 0.8 : 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniInfo(IconData icon, String text, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade400),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildActionsMenu(BuildContext context, OnlineSessionModel session, bool isDark) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: isDark ? Colors.white70 : Colors.black54,
      ),
      elevation: 12,
      color: isDark ? const Color(0xFF1E1B15) : Colors.white,
      onSelected: (value) {
        if (value == 'edit') {
          _showCreateEditDialog(context, session: session);
        } else if (value == 'delete') {
          _showDeleteConfirmation(context, session);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E8449).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.edit_rounded, color: Color(0xFF1E8449), size: 16),
              ),
              const SizedBox(width: 12),
              Text(
                'Edit Session',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 16),
              ),
              const SizedBox(width: 12),
              Text(
                'Delete Session',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Colors.red.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  void _showCreateEditDialog(BuildContext context, {OnlineSessionModel? session}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<OnlineSessionsCubit>(),
        child: CreateOnlineSessionDialog(sessionToEdit: session),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, OnlineSessionModel session) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1B15) : Colors.white,
        title: Text(
          'Delete Session?', 
          style: TextStyle(color: isDark ? Colors.white : Colors.black87)
        ),
        content: Text(
          'Are you sure you want to delete "${session.title}"? This cannot be undone.',
          style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade700)
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<OnlineSessionsCubit>().deleteSession(session.id);
              Navigator.pop(dialogContext);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
