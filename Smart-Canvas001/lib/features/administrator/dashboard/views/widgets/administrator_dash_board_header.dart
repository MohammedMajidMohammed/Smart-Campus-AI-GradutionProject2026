import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:line_icons/line_icons.dart';
import 'package:smart_canvas/core/components/custom_text_form_field.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:smart_canvas/features/profile/view_models/profile_cubit.dart';
import 'package:smart_canvas/features/profile/view_models/profile_state.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:smart_canvas/core/app_route/route_names.dart';
import 'package:smart_canvas/core/utilies/extensions/app_extensions.dart';
import 'package:smart_canvas/core/services/enhanced_notification_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smart_canvas/features/administrator/dashboard/views/widgets/administrator_search_palette.dart';

class AdministratorDashboardHeader extends StatelessWidget {
  const AdministratorDashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark 
              ? [const Color(0xFF1A263F), const Color(0xFF0F0E0A)]
              : [const Color(0xFF1E8449), const Color(0xFF1E8449)],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF1E8449)).withValues(alpha: 0.22),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.antiAlias,
        children: [
          // Academic Shield Concentric Watermark
          Positioned(
            right: -30,
            top: -20,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.04), width: 1.5),
              ),
              child: Center(
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.02), width: 1),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.school_outlined, 
                      size: 55, 
                      color: Colors.white.withValues(alpha: 0.04),
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: BlocBuilder<ProfileCubit, ProfileState>(
                        buildWhen: (previous, current) => current is ProfileLoaded,
                        builder: (context, state) {
                          String name = "Admin";
                          String? imageUrl;
                          if (state is ProfileLoaded) {
                            name = state.userData['full_name']?.split(' ').first ?? "Admin";
                            imageUrl = state.userData['image'];
                          }

                          return Row(
                            children: [
                              _buildAvatar(imageUrl),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        "${"hello".tr(args: [name])} 👋",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    _buildRoleBadge(context, "SYSTEM ADMIN"),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    _buildNotificationButton(context),
                  ],
                ).animate().fadeIn(duration: 800.ms).slideY(begin: -0.2),
                
                const SizedBox(height: 24),
                _buildEliteSearchBar(context, isDark)
                    .animate()
                    .fadeIn(delay: 300.ms)
                    .scale(begin: const Offset(0.97, 0.97)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String? imageUrl) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF1E8449).withValues(alpha: 0.6), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white24,
            backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                ? CachedNetworkImageProvider(imageUrl)
                : null,
            child: imageUrl == null || imageUrl.isEmpty
                ? const Icon(Icons.person, color: Colors.white)
                : null,
          ),
        ),
        // Mini gold verified badge
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E8449), Color(0xFF196F3D)],
            ),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1.5),
          ),
          child: const Icon(Icons.shield, color: Colors.white, size: 8),
        ),
      ],
    );
  }

  Widget _buildRoleBadge(BuildContext context, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  AppColors.kSecondaryColor.withValues(alpha: 0.25),
                  AppColors.kSecondaryColor.withValues(alpha: 0.08),
                ]
              : [
                  Colors.white.withValues(alpha: 0.22),
                  Colors.white.withValues(alpha: 0.12),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppColors.kSecondaryColor.withValues(alpha: 0.45)
              : Colors.white.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shield_outlined, 
            color: isDark ? AppColors.kSecondaryColor : Colors.white70, 
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: isDark ? AppColors.kSecondaryColor : Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationButton(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: EnhancedNotificationService().unreadCountNotifier,
      builder: (context, unreadCount, child) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: IconButton(
                icon: const Icon(LineIcons.bell, color: Colors.white, size: 24),
                onPressed: () => context.pushScreen(RouteNames.enhancedNotificationsScreen),
              ),
            ),
            if (unreadCount > 0)
              Positioned(
                right: -2, top: -2,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                  child: Text(
                    unreadCount > 9 ? '9+' : unreadCount.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildEliteSearchBar(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () => AdministratorSearchPalette.show(context),
      child: AbsorbPointer(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: CustomTextFormField(
            prefixIcon: Icon(LineIcons.search, color: isDark ? Colors.white54 : Colors.grey[400], size: 20),
            fillColor: isDark ? const Color(0xFF1E1B15) : Colors.white,
            hintText: "search_users_reports".tr(),
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF1E1B15),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            onChanged: (value) {},
          ),
        ),
      ),
    );
  }
}
