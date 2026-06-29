import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smart_canvas/core/app_route/route_names.dart';
import 'package:smart_canvas/core/di/dependancy_injection.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:smart_canvas/features/admin/subjects/models/subject_model.dart';
import 'package:smart_canvas/features/online_sessions/services/online_sessions_service.dart';
import 'package:smart_canvas/features/chat/services/chat_service.dart';
import 'package:smart_canvas/features/chat/views/screens/generic_chat_screen.dart';
import 'package:smart_canvas/features/chat/view_models/cubit/generic_chat_cubit.dart';
import 'package:smart_canvas/core/cache/cache_helper.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfessorSubjectChatListScreen extends StatelessWidget {
  const ProfessorSubjectChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0E0A) : const Color(0xFFF4F6F5),
      body: Stack(
        children: [
          // Background Decorative Elements (Consistent with Premium Design)
          Positioned(
            top: -100, right: -50,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [AppColors.kPrimaryColor.withValues(alpha: 0.15), AppColors.kSecondaryColor.withValues(alpha: 0.05)]),
              ),
            ),
          ),
          Positioned(
            bottom: 50, left: -100,
            child: Container(
              width: 400, height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [AppColors.kPrimaryColor.withValues(alpha: 0.08), Colors.transparent]),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Premium Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF2ECC71), Color(0xFF1E8449)]),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: const Color(0xFF1E8449).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 5))],
                        ),
                        child: const Icon(LineIcons.comment, color: Colors.white, size: 28),
                      ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'subject_chat_btn'.tr(),
                            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87),
                          ).animate().fadeIn(duration: 500.ms).slideX(begin: 0.1),
                          const SizedBox(height: 4),
                          Text(
                            "Manage your community connections",
                            style: TextStyle(fontSize: 14, color: isDark ? Colors.white54 : Colors.grey.shade600, fontWeight: FontWeight.w500),
                          ).animate().fadeIn(duration: 600.ms).slideX(begin: 0.1),
                        ],
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: FutureBuilder<List<SubjectModel>>(
                    future: getIt<OnlineSessionsService>().getProfessorSubjects(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final subjects = snapshot.data ?? [];
                      return ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        itemCount: subjects.length + 2,
                        itemBuilder: (context, index) {
                          if (index == 0) return _buildAdminChatItem(context, isDark);
                          if (index == 1) return _buildCollegeGroupItem(context, isDark);
                          
                          final subject = subjects[index - 2];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: InkWell(
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  RouteNames.subjectChatScreen,
                                  arguments: {'subjectId': subject.id, 'subjectName': subject.name},
                                );
                              },
                              borderRadius: BorderRadius.circular(24),
                              child: Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.transparent),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 55, height: 55,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(colors: [AppColors.kPrimaryColor, Color(0xFF2ECC71)]),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Center(child: Icon(LineIcons.book, color: Colors.white, size: 24)),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            subject.name,
                                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: isDark ? Colors.white : Colors.black87),
                                            maxLines: 1, overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            subject.code ?? 'no_code'.tr(),
                                            style: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(LineIcons.chevronCircleRight, color: AppColors.kPrimaryColor, size: 28),
                                  ],
                                ),
                              ),
                            ),
                          ).animate().fadeIn(duration: 400.ms, delay: (50 * index).ms).slideY(begin: 0.1);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminChatItem(BuildContext context, bool isDark) {
    final user = getIt<CacheHelper>().getUserModel();
    if (user == null) return const SizedBox();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () async {
          final chatService = getIt<ChatService>();
          final room = await chatService.getOrCreateRoom(type: 'private_admin_prof', targetId: user.id);
          if (!context.mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BlocProvider(
                create: (context) => getIt<GenericChatCubit>(),
                child: GenericChatScreen(
                  roomId: room.id,
                  roomTitle: 'Administrator Chat',
                  roomSubtitle: 'Private Direct Message',
                ),
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF2ECC71), Color(0xFF1E8449)]),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: const Color(0xFF2ECC71).withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: Row(
            children: [
              Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(16)),
                child: const Center(child: Icon(LineIcons.userShield, color: Colors.white, size: 28)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Administrator', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text('Direct channel to admin', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const Icon(LineIcons.chevronCircleRight, color: Colors.white, size: 28),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildCollegeGroupItem(BuildContext context, bool isDark) {
    final user = getIt<CacheHelper>().getUserModel();
    if (user == null || user.collegeId == null) return const SizedBox();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () async {
          // Show loading
          showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));
          
          try {
            final chatService = getIt<ChatService>();
            final room = await chatService.getOrCreateRoom(type: 'college_group', targetId: user.collegeId!);
            
            if (!context.mounted) return;
            Navigator.pop(context); // Close loading
            
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BlocProvider(
                  create: (context) => getIt<GenericChatCubit>(),
                  child: GenericChatScreen(
                    roomId: room.id,
                    roomTitle: user.collegeName.isEmpty ? 'College Group' : user.collegeName,
                    roomSubtitle: 'Administrative Channel',
                  ),
                ),
              ),
            );
          } catch (e) {
            if (!context.mounted) return;
            Navigator.pop(context); // Close loading
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
          }
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.transparent),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: Row(
            children: [
              Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.kPrimaryColor, Color(0xFF2ECC71)]), borderRadius: BorderRadius.circular(16)),
                child: const Center(child: Icon(LineIcons.university, color: Colors.white, size: 28)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.collegeName.isEmpty ? 'My College Group Chat' : '${user.collegeName} Group Chat', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: isDark ? Colors.white : Colors.black87)),
                    const SizedBox(height: 4),
                    Text('Official College Channel', style: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const Icon(LineIcons.chevronCircleRight, color: AppColors.kPrimaryColor, size: 28),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 50.ms).slideY(begin: 0.1);
  }
}
