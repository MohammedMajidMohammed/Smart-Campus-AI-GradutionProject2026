import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:line_icons/line_icons.dart';
import 'package:smart_canvas/core/app_route/route_names.dart';
import 'package:smart_canvas/core/components/custom_text_form_field.dart';
import 'package:smart_canvas/core/utilies/extensions/app_extensions.dart';
import 'package:smart_canvas/features/profile/view_models/profile_cubit.dart';
import 'package:smart_canvas/features/profile/view_models/profile_state.dart';
import 'package:smart_canvas/core/services/enhanced_notification_service.dart';
import 'package:easy_localization/easy_localization.dart';

class ProfessorDashboardHeader extends StatelessWidget {
  const ProfessorDashboardHeader({super.key});

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
              ? [const Color(0xFF1E1B15), const Color(0xFF0F0E0A)]
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
                        builder: (context, state) {
                          String name = "";
                          String? imageUrl;
                          if (state is ProfileLoaded) {
                            name = (state.userData['full_name'] ?? "").toString().trim();
                            imageUrl = state.userData['image'];
                          }

                          final String displayName;
                          if (name.isEmpty) {
                            displayName = "dr".tr().trim();
                          } else {
                            final lowerName = name.toLowerCase();
                            if (lowerName.startsWith('dr.') || 
                                lowerName.startsWith('dr ') || 
                                lowerName.startsWith('د.') || 
                                lowerName.startsWith('د ')) {
                              displayName = name;
                            } else {
                              displayName = "${"dr".tr()}$name";
                            }
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
                                        "${"hello".tr(args: [displayName])} 👋",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    _buildRoleBadge(context.locale.languageCode == 'ar' ? "أستاذ جامعي" : "PROFESSOR"),
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
                ),
                const SizedBox(height: 24),
                _buildSearchBar(context, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.22),
            Colors.white.withValues(alpha: 0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35), 
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.school_outlined, 
            color: Colors.white70, 
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String? imageUrl) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF1E8449), Colors.white70, Color(0xFF1E8449)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
          color: Color(0xFF1E8449),
          shape: BoxShape.circle,
        ),
        child: CircleAvatar(
          radius: 26,
          backgroundColor: Colors.white24,
          backgroundImage: imageUrl != null && imageUrl.isNotEmpty
              ? CachedNetworkImageProvider(imageUrl)
              : null,
          child: imageUrl == null || imageUrl.isEmpty
              ? const Icon(Icons.person, color: Colors.white, size: 26)
              : null,
        ),
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
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: IconButton(
                icon: const Icon(LineIcons.bell, color: Colors.white, size: 26),
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

  Widget _buildSearchBar(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: CustomTextFormField(
        prefixIcon: Icon(LineIcons.search, color: isDark ? Colors.white54 : Colors.grey[400], size: 22),
        fillColor: isDark ? const Color(0xFF2A2720) : Colors.white,
        hintText: "search_schedule".tr(),
        style: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF1E1B15),
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
