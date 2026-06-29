import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:line_icons/line_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smart_canvas/core/app_route/route_names.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:smart_canvas/features/student/dashboard/view_models/college_data_cubit.dart';
import 'package:smart_canvas/features/chat/services/chat_service.dart';
import 'package:smart_canvas/features/chat/views/screens/generic_chat_screen.dart';
import 'package:smart_canvas/features/chat/view_models/cubit/generic_chat_cubit.dart';
import 'package:smart_canvas/core/di/dependancy_injection.dart';
import 'package:smart_canvas/core/cache/cache_helper.dart';

class StudentSubjectChatListScreen extends StatelessWidget {
  const StudentSubjectChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0E0A) : const Color(0xFFF4F6F5),
      body: Stack(
        children: [
          // Background Decorative Elements
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.kPrimaryColor.withValues(alpha: isDark ? 0.25 : 0.15),
                    AppColors.kSecondaryColor.withValues(alpha: isDark ? 0.2 : 0.05),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.kPrimaryColor.withValues(alpha: isDark ? 0.1 : 0.04),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Custom Premium Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2ECC71), Color(0xFF1E8449)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1E8449).withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(LineIcons.comment, color: Colors.white, size: 28),
                      ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'subject_chat_btn'.tr(),
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : Colors.black87,
                              letterSpacing: -0.5,
                            ),
                          ).animate().fadeIn(duration: 500.ms).slideX(begin: 0.1),
                          const SizedBox(height: 4),
                          Text(
                            "join_conversation_now".tr(),
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white54 : Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ).animate().fadeIn(duration: 600.ms).slideX(begin: 0.1),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // List of Chats
                Expanded(
                  child: BlocBuilder<CollegeDataCubit, CollegeDataState>(
                    builder: (context, state) {
                      if (state is CollegeDataLoading) {
                        return Center(
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.kPrimaryColor.withValues(alpha: 0.2),
                                  blurRadius: 20,
                                ),
                              ],
                            ),
                            child: const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.kPrimaryColor),
                            ),
                          ),
                        ).animate().scale();
                      }

                      final subjects = context.read<CollegeDataCubit>().filteredSubjects;
                      
                      if (subjects.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(30),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.white,
                                  border: Border.all(
                                    color: isDark ? Colors.white12 : Colors.grey.shade200,
                                  ),
                                ),
                                child: Icon(LineIcons.comments, size: 80, color: AppColors.kPrimaryColor.withValues(alpha: 0.5)),
                              ).animate().shimmer(duration: 2.seconds).slideY(begin: 0.2),
                              const SizedBox(height: 24),
                              Text(
                                'no_subjects'.tr(), 
                                style: TextStyle(
                                  fontSize: 18, 
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white70 : Colors.black54,
                                ),
                              ).animate().fadeIn(delay: 200.ms),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 100),
                        itemCount: subjects.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return _buildCollegeGroupItem(context, isDark);
                          }
                          final subject = subjects[index - 1];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: InkWell(
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  RouteNames.subjectChatScreen,
                                  arguments: {
                                    'subjectId': subject.id,
                                    'subjectName': subject.name,
                                  },
                                );
                              },
                              borderRadius: BorderRadius.circular(24),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
                                    width: 1.5,
                                  ),
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
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [AppColors.kPrimaryColor, Color(0xFF2ECC71)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(18),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.kPrimaryColor.withValues(alpha: 0.3),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: const Center(
                                        child: Icon(LineIcons.book, color: Colors.white, size: 28),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            subject.name, 
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: isDark ? Colors.white : Colors.black87,
                                              letterSpacing: -0.2,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Icon(LineIcons.hashtag, size: 14, color: isDark ? Colors.white54 : Colors.grey.shade500),
                                              const SizedBox(width: 4),
                                              Text(
                                                subject.code ?? 'no_code'.tr(),
                                                style: TextStyle(
                                                  color: isDark ? Colors.white54 : Colors.grey.shade600,
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.white.withValues(alpha: 0.1) : AppColors.kPrimaryColor.withValues(alpha: 0.08),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(LineIcons.chevronRight, size: 18, color: AppColors.kPrimaryColor),
                                    ),
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.kPrimaryColor, Color(0xFF2ECC71)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: AppColors.kPrimaryColor.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: Row(
            children: [
              Container(width: 60, height: 60, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(18)), child: const Center(child: Icon(LineIcons.university, color: Colors.white, size: 28))),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.collegeName.isEmpty ? 'My College Group Chat' : '${user.collegeName} Group Chat', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white, letterSpacing: -0.2)),
                    const SizedBox(height: 6),
                    Text('Official Administrative Channel', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w500, fontSize: 13)),
                  ],
                ),
              ),
              const Icon(LineIcons.chevronRight, size: 18, color: Colors.white),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }
}
