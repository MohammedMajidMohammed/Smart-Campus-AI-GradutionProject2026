import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:smart_canvas/features/online_sessions/view_models/cubit/online_sessions_cubit.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';

class StudentOnlineSessionsScreen extends StatelessWidget {
  const StudentOnlineSessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0E0A) : const Color(0xFFFAF9F5),
      body: BlocBuilder<OnlineSessionsCubit, OnlineSessionsState>(
        buildWhen: (previous, current) =>
            current is OnlineSessionsLoading ||
            current is OnlineSessionsLoaded ||
            current is OnlineSessionsError,
        builder: (context, state) {
          int sessionCount = 0;
          if (state is OnlineSessionsLoaded) {
            sessionCount = state.sessions.length;
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Premium SliverAppBar
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                elevation: 0,
                stretch: true,
                backgroundColor: isDark ? const Color(0xFF1E1B15) : AppColors.kPrimaryColor,
                foregroundColor: Colors.white,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  titlePadding: const EdgeInsets.only(bottom: 16),
                  title: Text(
                    'virtual_classes'.tr(),
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: Colors.white,
                      letterSpacing: -0.3,
                      shadows: [Shadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 8)],
                    ),
                  ),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1E8449), Color(0xFF1E8449)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: -50, right: -40,
                          child: Container(
                            width: 200, height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.06),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 30, left: -20,
                          child: Container(
                            width: 100, height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.03),
                            ),
                          ),
                        ),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 32),
                            child: Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.1),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 2),
                              ),
                              child: const Icon(Icons.videocam_rounded, size: 32, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Section header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Scheduled Sessions",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : const Color(0xFF0F0E0A),
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.kPrimaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "$sessionCount",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: AppColors.kPrimaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: -0.1),
              ),

              // Content
              _buildContent(state, isDark),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent(OnlineSessionsState state, bool isDark) {
    if (state is OnlineSessionsLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator(color: AppColors.kPrimaryColor)),
      );
    } else if (state is OnlineSessionsError) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withValues(alpha: 0.08),
                ),
                child: Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.withValues(alpha: 0.4)),
              ),
              const SizedBox(height: 20),
              Text(
                'Error loading sessions',
                style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.grey.shade400,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    } else if (state is OnlineSessionsLoaded) {
      final sessions = state.sessions;

      if (sessions.isEmpty) {
        return SliverFillRemaining(child: _buildEmptyState(isDark));
      }

      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final session = sessions[index];
              final isUnderway = session.startTime.isBefore(DateTime.now()) &&
                  session.startTime.add(Duration(minutes: session.durationMinutes)).isAfter(DateTime.now());
              final isUpcoming = session.startTime.isAfter(DateTime.now());

              return _SessionCard(
                session: session,
                isUnderway: isUnderway,
                isUpcoming: isUpcoming,
                isDark: isDark,
              ).animate().fadeIn(delay: (80 * index).ms).slideY(begin: 0.05);
            },
            childCount: sessions.length,
          ),
        ),
      );
    }
    return const SliverToBoxAdapter(child: SizedBox());
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : AppColors.kPrimaryColor.withValues(alpha: 0.06),
            ),
            child: Icon(
              Icons.videocam_off_rounded,
              size: 48,
              color: isDark ? Colors.white.withValues(alpha: 0.12) : AppColors.kPrimaryColor.withValues(alpha: 0.2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'no_virtual_classes'.tr(),
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.grey.shade400,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Check back later for scheduled sessions",
            style: TextStyle(
              color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.grey.shade300,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final dynamic session;
  final bool isUnderway;
  final bool isUpcoming;
  final bool isDark;

  const _SessionCard({
    required this.session,
    required this.isUnderway,
    required this.isUpcoming,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // Status theming
    final Color statusColor;
    final String statusLabel;
    final bool isActive = isUnderway || isUpcoming;

    if (isUnderway) {
      statusColor = const Color(0xFFEF4444);
      statusLabel = 'live_now'.tr();
    } else if (isUpcoming) {
      statusColor = const Color(0xFF22C55E);
      statusLabel = 'upcoming'.tr();
    } else {
      statusColor = Colors.grey;
      statusLabel = 'finished'.tr();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1B15) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isUnderway
              ? const Color(0xFFEF4444).withValues(alpha: 0.2)
              : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade100),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          if (isUnderway)
            BoxShadow(
              color: const Color(0xFFEF4444).withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        children: [
          // Top section
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tags row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.kPrimaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        session.subjectName ?? 'Subject',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.kPrimaryColor,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isUnderway)
                            Container(
                              width: 6, height: 6,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ).animate(onPlay: (controller) => controller.repeat())
                              .fadeIn(duration: 600.ms)
                              .fadeOut(duration: 600.ms)
                          else
                            Container(
                              width: 6, height: 6,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          const SizedBox(width: 6),
                          Text(
                            statusLabel.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  session.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                    color: isDark ? Colors.white : const Color(0xFF0F0E0A),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),

                // Info rows
                _InfoRow(
                  icon: Icons.person_rounded,
                  text: session.professorName ?? 'professor_lbl'.tr(),
                  isDark: isDark,
                ),
                const SizedBox(height: 10),
                _InfoRow(
                  icon: Icons.schedule_rounded,
                  text: DateFormat('EEEE, MMM d, yyyy — h:mm a').format(session.startTime),
                  isDark: isDark,
                ),
                const SizedBox(height: 10),
                _InfoRow(
                  icon: Icons.timelapse_rounded,
                  text: "${session.durationMinutes} min",
                  isDark: isDark,
                ),
              ],
            ),
          ),

          // Bottom action
          Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              gradient: isActive
                  ? LinearGradient(
                      colors: isUnderway
                          ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                          : [const Color(0xFF1E8449), const Color(0xFF2ECC71)],
                    )
                  : null,
              color: isActive ? null : (isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFFAFBFC)),
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade100,
                  width: 1,
                ),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  final url = Uri.parse(session.meetingLink);
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                },
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isUnderway ? Icons.videocam_rounded : (isUpcoming ? Icons.videocam_rounded : Icons.videocam_off_rounded),
                        color: isActive ? Colors.white : (isDark ? Colors.white24 : Colors.grey.shade400),
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isUnderway
                            ? 'join_live_session'.tr().toUpperCase()
                            : (isUpcoming ? 'join_live_session'.tr() : '${'join_live_session'.tr()} ($statusLabel)'),
                        style: TextStyle(
                          fontSize: 13,
                          color: isActive ? Colors.white : (isDark ? Colors.white24 : Colors.grey.shade400),
                          fontWeight: FontWeight.w900,
                          letterSpacing: isUnderway ? 0.8 : 0,
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
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDark;

  const _InfoRow({
    required this.icon,
    required this.text,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppColors.kPrimaryColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: AppColors.kPrimaryColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white54 : const Color(0xFF475569),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
