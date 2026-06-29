import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:line_icons/line_icons.dart';
import 'package:smart_canvas/core/app_route/route_names.dart';
import 'package:smart_canvas/core/cache/cache_helper.dart';
import 'package:smart_canvas/core/components/settings/change_password_dialog.dart';
import 'package:smart_canvas/core/components/settings/edit_profile_screen.dart';
import 'package:smart_canvas/core/components/settings/enhanced_notifications_screen.dart';
import 'package:smart_canvas/core/components/settings/help_center_dialog.dart';
import 'package:smart_canvas/core/di/dependancy_injection.dart';
import 'package:smart_canvas/core/utilies/extensions/app_extensions.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:smart_canvas/core/utilies/theme/theme_cubit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:smart_canvas/features/administrator/collages/view_models/cubit/colleges_cubit.dart';
import 'package:smart_canvas/features/profile/view_models/profile_cubit.dart';
import 'package:smart_canvas/features/profile/view_models/profile_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfessionalSettingsScreen extends StatelessWidget {
  const ProfessionalSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => ProfileCubit()..loadUserProfile()),
        BlocProvider(create: (context) => CollegesCubit()),
      ],
      child: const _SettingsView(),
    );
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView();

  @override
  Widget build(BuildContext context) {
    final height = SizeConfig.height;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Sleek premium backgrounds
    final scaffoldBg = isDark ? const Color(0xFF09090B) : const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: height * 0.46,
            backgroundColor: isDark ? const Color(0xFF09090B) : const Color(0xFF1E8449),
            elevation: 0,
            pinned: true,
            stretch: true,
            leading: const SizedBox.shrink(),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
              centerTitle: true,
              titlePadding: const EdgeInsets.only(bottom: 16),
              title: LayoutBuilder(
                builder: (context, constraints) {
                  final isCollapsed = constraints.biggest.height <= kToolbarHeight + 40;
                  return AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isCollapsed ? 1.0 : 0.0,
                    child: Text(
                      'settings'.tr(),
                      style: const TextStyle(
                        color: Colors.white, 
                        fontWeight: FontWeight.w900, 
                        fontSize: 18,
                        letterSpacing: 0.5,
                      ),
                    ),
                  );
                },
              ),
              background: LayoutBuilder(
                builder: (context, constraints) {
                  final currentHeight = constraints.maxHeight;
                  final double expandedHeight = height * 0.46;
                  // Calculate opacity: fully visible when expanded, fades out smoothly on scroll down to 180px
                  final double opacity = ((currentHeight - 170) / (expandedHeight - 170)).clamp(0.0, 1.0);
                  
                  return Container(
                    decoration: BoxDecoration(
                      gradient: isDark
                          ? const LinearGradient(
                              colors: [Color(0xFF0F172A), Color(0xFF020617), Color(0xFF09090B)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            )
                          : const LinearGradient(
                              colors: [Color(0xFF1E8449), Color(0xFF2E9B58)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(40),
                        bottomRight: Radius.circular(40),
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Premium ambient glowing mesh blobs (Cyberpunk/Aesthetic aura)
                        Positioned(
                          top: -60,
                          right: -60,
                          child: Container(
                            width: 320,
                            height: 320,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  (isDark ? const Color(0xFF8B5CF6) : const Color(0xFF2DD4BF)).withValues(alpha: isDark ? 0.12 : 0.35),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -40,
                          left: -60,
                          child: Container(
                            width: 260,
                            height: 260,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  (isDark ? const Color(0xFF06B6D4) : const Color(0xFF34D399)).withValues(alpha: isDark ? 0.10 : 0.30),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 120,
                          left: 40,
                          child: Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  (isDark ? const Color(0xFFF43F5E) : const Color(0xFFFBBF24)).withValues(alpha: isDark ? 0.08 : 0.20),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        // Fades the profile card out smoothly as SliverAppBar collapses
                        Center(
                          child: Opacity(
                            opacity: opacity,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 20, right: 20, top: 24, bottom: 6),
                              child: _buildResponsiveProfile(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
              ),
            ),
          ),

          // Content Panels with Beautiful Premium Aesthetics
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    children: [
                      _AnimatedSlideUp(
                        delayMs: 100,
                        child: _GlassSectionCard(
                          title: 'preferences'.tr(),
                          children: [
                            _InteractiveSettingTile(
                              icon: LineIcons.sun,
                              title: 'dark_mode'.tr(),
                              themeColor: const Color(0xFFF59E0B),
                              onTap: () {},
                              trailing: const _CustomThemeToggle(),
                            ),
                            _InteractiveSettingTile(
                              icon: LineIcons.language,
                              title: 'language'.tr(),
                              themeColor: const Color(0xFF10B981),
                              onTap: () {},
                              trailing: const _CustomLanguageSelector(),
                            ),
                            _InteractiveSettingTile(
                              icon: LineIcons.userEdit,
                              title: 'edit_profile'.tr(),
                              subtitle: 'manage_account'.tr(),
                              themeColor: const Color(0xFF0EA5E9),
                              onTap: () => _navigateToEditProfile(context),
                            ),
                          ],
                        ),
                      ),
                      _AnimatedSlideUp(
                        delayMs: 200,
                        child: _GlassSectionCard(
                          title: 'security'.tr(),
                          children: [
                            _InteractiveSettingTile(
                              icon: LineIcons.lock,
                              title: 'password'.tr(),
                              subtitle: 'change_recovery'.tr(),
                              themeColor: const Color(0xFFEC4899),
                              onTap: () => _showChangePasswordDialog(context),
                            ),
                            _InteractiveSettingTile(
                              icon: LineIcons.bell,
                              title: 'notifications'.tr(),
                              subtitle: 'customize_alerts'.tr(),
                              themeColor: const Color(0xFF8B5CF6),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const EnhancedNotificationsScreen()),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _AnimatedSlideUp(
                        delayMs: 300,
                        child: _GlassSectionCard(
                          title: 'support'.tr(),
                          children: [
                            _InteractiveSettingTile(
                              icon: LineIcons.questionCircle,
                              title: 'help_center'.tr(),
                              themeColor: const Color(0xFF06B6D4),
                              onTap: () => showDialog(context: context, builder: (_) => const HelpCenterDialog()),
                            ),
                            _InteractiveSettingTile(
                              icon: LineIcons.infoCircle,
                              title: 'about'.tr(),
                              themeColor: const Color(0xFF10B981),
                              onTap: () => _showAboutDialog(context),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _AnimatedSlideUp(
                        delayMs: 400,
                        child: _buildSignOutPanel(context),
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

  Widget _buildResponsiveProfile(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        String name = '...';
        String email = '';
        String role = 'STUDENT';
        String? imageUrl;
        String collegeName = '';
        String levelText = '';
        String universityId = '...';
        
        if (state is ProfileLoaded) {
          name = state.userData['full_name'] ?? 'User';
          email = state.userData['email'] ?? '';
          imageUrl = state.userData['image'];
          universityId = state.userData['university_id']?.toString() ?? 'N/A';
          final roles = state.userData['role'];
          if (roles != null && roles is Map) role = roles['name'] ?? 'STUDENT';
          
          final college = state.userData['colleges'];
          final level = state.userData['year_level'];
          
          final String normalizedRole = role.toUpperCase();
          final bool isStudent = normalizedRole == 'STUDENT';
          
          if (normalizedRole == 'STUDENT' || normalizedRole == 'PROFESSOR' || normalizedRole == 'DOCTOR') {
            collegeName = college != null && college is Map ? (college['name'] ?? '') : '';
          }
          
          if (isStudent) {
            if (level != null) {
              final translated = "year_level_label".tr(args: [level.toString()]);
              if (translated == "year_level_label") {
                final isArabic = context.locale.languageCode == 'ar';
                levelText = isArabic ? "المستوى $level" : "Level $level";
              } else {
                levelText = translated;
              }
            }
          }
        }

        final roleColor = _getRoleColor(role, isDark);
        final roleIcon = _getRoleIcon(role);
        
        // Premium role-based color gradients for custom name styling
        final Gradient nameGradient = role.toUpperCase() == 'ADMINISTRATOR' || role.toUpperCase() == 'ADMIN'
            ? const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFF59E0B)])
            : role.toUpperCase() == 'PROFESSOR' || role.toUpperCase() == 'DOCTOR'
                ? const LinearGradient(colors: [Color(0xFFC084FC), Color(0xFFF472B6)])
                : const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF06B6D4)]);

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 36, bottom: 8), // Reduced top margin from 50 to prevent overflow
          // Gradient Border Wrapper for the Glass Card
          padding: const EdgeInsets.all(1.5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: isDark ? 0.12 : 0.6),
                roleColor.withValues(alpha: isDark ? 0.35 : 0.8),
                Colors.white.withValues(alpha: 0.04),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22.5),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                color: isDark 
                    ? const Color(0xFF18181B).withValues(alpha: 0.8) 
                    : Colors.white.withValues(alpha: 0.82),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), // More compact padding
                child: Stack(
                  children: [
                    // Corner HUD Brackets for high-tech holographic smart pass theme
                    Positioned(top: 2, left: 2, child: _buildHUDCorner(isDark, topLeft: true)),
                    Positioned(top: 2, right: 2, child: _buildHUDCorner(isDark, topRight: true)),
                    Positioned(bottom: 2, left: 2, child: _buildHUDCorner(isDark, bottomLeft: true)),
                    Positioned(bottom: 2, right: 2, child: _buildHUDCorner(isDark, bottomRight: true)),
                    
                    // Card Glass Diagonal Shimmer reflection
                    Positioned.fill(
                      child: FractionallySizedBox(
                        widthFactor: 2.0,
                        heightFactor: 2.0,
                        alignment: Alignment.center,
                        child: Transform.rotate(
                          angle: -0.5,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0.0),
                                  Colors.white.withValues(alpha: isDark ? 0.015 : 0.04),
                                  Colors.white.withValues(alpha: 0.0),
                                ],
                                stops: const [0.35, 0.5, 0.65],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Simulated Campus Smart Chip ornament in top-right
                    Positioned(
                      top: 4,
                      right: 4,
                      child: _buildSmartChip(isDark),
                    ),
                    
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 4),
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            _PremiumGlowingAvatar(imageUrl: imageUrl, roleColor: roleColor, size: 76), // Reduced size to prevent overflow
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isDark 
                                      ? [roleColor, roleColor.withValues(alpha: 0.7)]
                                      : [const Color(0xFF10B981), const Color(0xFF059669)],
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark ? const Color(0xFF18181B) : Colors.white, 
                                  width: 1.5,
                                ),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                                ],
                              ),
                              child: Icon(
                                roleIcon == Icons.school_rounded ? Icons.shield : roleIcon, 
                                color: Colors.white, 
                                size: 10,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8), // Reduced spacing
                        
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: _GradientText(
                            name,
                            gradient: nameGradient,
                            style: const TextStyle(
                              fontSize: 20, // Slightly more compact font
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            email,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark ? Colors.white38 : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8), // Spacing before stats

                        // Sleek Futuristic Stats Grid instead of simple badges
                        Builder(
                          builder: (context) {
                            final List<Widget> statsWidgets = [];
                            final String normalizedRole = role.toUpperCase();
                            
                            if (normalizedRole == 'STUDENT') {
                              statsWidgets.add(
                                _buildStatItem(
                                  "level_lbl", 
                                  levelText.isNotEmpty ? levelText.replaceAll(RegExp(r'Level\s*|المستوى\s*'), '') : '—', 
                                  Icons.school_rounded, 
                                  isDark,
                                ),
                              );
                              statsWidgets.add(_buildVerticalDivider(isDark));
                              statsWidgets.add(
                                _buildStatItem(
                                  "college_lbl", 
                                  collegeName.isNotEmpty ? _abbreviateCollege(collegeName) : '—', 
                                  Icons.account_balance_rounded, 
                                  isDark,
                                ),
                              );
                              statsWidgets.add(_buildVerticalDivider(isDark));
                              statsWidgets.add(
                                _buildStatItem(
                                  "status_label", 
                                  "active_status".tr(), 
                                  Icons.verified_user_rounded, 
                                  isDark,
                                  isStatus: true,
                                ),
                              );
                            } else if (normalizedRole == 'PROFESSOR' || normalizedRole == 'DOCTOR') {
                              if (collegeName.isNotEmpty) {
                                statsWidgets.add(
                                  _buildStatItem(
                                    "college_lbl", 
                                    _abbreviateCollege(collegeName), 
                                    Icons.account_balance_rounded, 
                                    isDark,
                                  ),
                                );
                                statsWidgets.add(_buildVerticalDivider(isDark));
                              }
                              statsWidgets.add(
                                _buildStatItem(
                                  "role_lbl", 
                                  "faculty_stat".tr(), 
                                  Icons.badge_rounded, 
                                  isDark,
                                ),
                              );
                              statsWidgets.add(_buildVerticalDivider(isDark));
                              statsWidgets.add(
                                // Status is verified status
                                _buildStatItem(
                                  "status_label", 
                                  "active_status".tr(), 
                                  Icons.verified_user_rounded, 
                                  isDark,
                                  isStatus: true,
                                ),
                              );
                            } else {
                              // ADMINISTRATOR / ADMIN / other roles
                              statsWidgets.add(
                                _buildStatItem(
                                  "access_lbl", 
                                  "full_access".tr(), 
                                  Icons.admin_panel_settings_rounded, 
                                  isDark,
                                ),
                              );
                              statsWidgets.add(_buildVerticalDivider(isDark));
                              statsWidgets.add(
                                _buildStatItem(
                                  "system_lbl", 
                                  "control_panel".tr(), 
                                  Icons.settings_suggest_rounded, 
                                  isDark,
                                ),
                              );
                              statsWidgets.add(_buildVerticalDivider(isDark));
                              statsWidgets.add(
                                _buildStatItem(
                                  "status_label", 
                                  "active_status".tr(), 
                                  Icons.verified_user_rounded, 
                                  isDark,
                                  isStatus: true,
                                ),
                              );
                            }
                            
                            return Container(
                              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8), // Compact padding
                              decoration: BoxDecoration(
                                color: isDark ? Colors.black.withValues(alpha: 0.15) : const Color(0xFFF1F5F9).withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
                                  width: 1.0,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: statsWidgets,
                              ),
                            );
                          }
                        ),
                        const SizedBox(height: 10), // Reduced spacing
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildRoleBadge(role, isDark, roleColor, roleIcon),
                            const SizedBox(width: 8),
                            Expanded(child: _buildCardBarcode(isDark, universityId)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Sci-fi HUD brackets widget
  Widget _buildHUDCorner(bool isDark, {bool topLeft = false, bool topRight = false, bool bottomLeft = false, bool bottomRight = false}) {
    final color = isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.06);
    return SizedBox(
      width: 6,
      height: 6,
      child: CustomPaint(
        painter: _HUDCornerPainter(
          color: color,
          topLeft: topLeft,
          topRight: topRight,
          bottomLeft: bottomLeft,
          bottomRight: bottomRight,
        ),
      ),
    );
  }

  // Futuristic smart chip drawing
  Widget _buildSmartChip(bool isDark) {
    return Container(
      width: 34,
      height: 24,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFFF59E0B), const Color(0xFFD97706), const Color(0xFFB45309)]
              : [const Color(0xFFFBBF24), const Color(0xFFF59E0B), const Color(0xFFD97706)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD97706).withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _ChipLinesPainter(),
      ),
    );
  }

  // Stat item renderer inside the Pass Card
  Widget _buildStatItem(String label, String value, IconData icon, bool isDark, {bool isStatus = false}) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 10, color: isDark ? Colors.white30 : Colors.black38),
              const SizedBox(width: 3),
              Text(
                label.tr(),
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white30 : Colors.black38,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isStatus) ...[
                const _GlowingStatusDot(),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white.withValues(alpha: 0.87) : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider(bool isDark) {
    return Container(
      width: 1,
      height: 20,
      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
    );
  }

  // Abbreviate long college names to fit card
  String _abbreviateCollege(String name) {
    if (name.length <= 10) return name;
    final clean = name.toLowerCase();
    if (clean.contains("computer") || clean.contains("حاسبات")) {
      return "FCAI";
    }
    if (clean.contains("engineering") || clean.contains("هندسة")) {
      return "ENG";
    }
    if (clean.contains("science") || clean.contains("علوم")) {
      return "SCI";
    }
    final words = name.split(' ');
    if (words.length > 1) {
      return words.map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();
    }
    return name.substring(0, 8);
  }

  // Barcode decoration at the bottom
  Widget _buildCardBarcode(bool isDark, String universityId) {
    final barColor = isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05);
    final List<double> barWidths = [1.5, 3.5, 1, 2.5, 1, 4.5, 1.5, 1, 3.5, 2, 2.5, 1, 3, 1.5, 1, 4, 1.5];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: barWidths.map((w) => Container(
            width: w,
            height: 10,
            margin: const EdgeInsets.symmetric(horizontal: 0.5),
            color: barColor,
          )).toList(),
        ),
        const SizedBox(height: 2),
        Text(
          "ID: $universityId",
          style: TextStyle(
            fontSize: 9.0,
            fontFamily: 'Courier',
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white70 : Colors.black87,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleBadge(String role, bool isDark, Color roleColor, IconData roleIcon) {
    final badgeBorderColor = isDark 
        ? roleColor.withValues(alpha: 0.35) 
        : Colors.white.withValues(alpha: 0.35);
    final badgeBgGradient = isDark 
        ? LinearGradient(
            colors: [roleColor.withValues(alpha: 0.12), roleColor.withValues(alpha: 0.04)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : LinearGradient(
            colors: [roleColor, roleColor.withValues(alpha: 0.85)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
    final badgeContentColor = isDark 
        ? roleColor 
        : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), // Reduced padding
      decoration: BoxDecoration(
        gradient: badgeBgGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: badgeBorderColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: roleColor.withValues(alpha: isDark ? 0.03 : 0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(roleIcon, color: badgeContentColor, size: 12),
          const SizedBox(width: 4),
          Text(
            role.toUpperCase(),
            style: TextStyle(
              color: badgeContentColor,
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignOutPanel(BuildContext context) {
    return _InteractiveSignOutButton(
      onTap: () => _signOut(context),
    );
  }

  Color _getRoleColor(String role, bool isDark) {
    switch (role.toUpperCase()) {
      case 'ADMINISTRATOR':
      case 'ADMIN':
        return const Color(0xFFEF4444); // Crimson Red
      case 'PROFESSOR':
      case 'DOCTOR':
        return const Color(0xFF8B5CF6); // Royal Purple
      case 'STUDENT':
      default:
        return const Color(0xFF10B981); // Emerald Green
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role.toUpperCase()) {
      case 'ADMINISTRATOR':
      case 'ADMIN':
        return Icons.security_rounded;
      case 'PROFESSOR':
      case 'DOCTOR':
        return Icons.psychology_rounded;
      case 'STUDENT':
      default:
        return Icons.school_rounded;
    }
  }

  void _navigateToEditProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: context.read<ProfileCubit>()),
            BlocProvider.value(value: context.read<CollegesCubit>()),
          ],
          child: const EditProfileScreen(),
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<ProfileCubit>(),
        child: const ChangePasswordDialog(),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF18181B) : Colors.white,
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
            width: 1.2,
          ),
        ),
        title: Text(
          "about".tr(),
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.school_rounded,
              color: Color(0xFF10B981),
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              "Smart Campus",
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Version 1.0.0",
              style: TextStyle(
                color: isDark ? Colors.white38 : Colors.grey[500],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Your intelligent companion for campus navigation, schedules, and seamless communication.",
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "close".tr(),
              style: const TextStyle(
                color: Color(0xFF10B981),
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        ],
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF18181B) : Colors.white,
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
            width: 1.2,
          ),
        ),
        title: Text(
          'confirm_sign_out'.tr(),
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Text(
          'logout_desc'.tr(),
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr(), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'sign_out'.tr(),
              style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await getIt<SupabaseClient>().auth.signOut();
    await getIt<CacheHelper>().clearData();
    if (context.mounted) {
      context.pushAndRemoveUntilScreen(RouteNames.signInScreen);
    }
  }
}

// Custom Premium Double-Ring Animated Avatar Ring
class _PremiumGlowingAvatar extends StatefulWidget {
  final String? imageUrl;
  final Color roleColor;
  final double size;
  const _PremiumGlowingAvatar({this.imageUrl, required this.roleColor, this.size = 80});

  @override
  State<_PremiumGlowingAvatar> createState() => _PremiumGlowingAvatarState();
}

class _PremiumGlowingAvatarState extends State<_PremiumGlowingAvatar> with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 12),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final glow = _pulseAnimation.value;
        final size = widget.size;
        return Stack(
          alignment: Alignment.center,
          children: [
            // Glowing breathing background aura
            Container(
              width: size + 4,
              height: size + 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.roleColor.withValues(alpha: 0.12 + (glow * 0.22)),
                    blurRadius: 10 + (glow * 10),
                    spreadRadius: 1 + (glow * 2),
                  ),
                ],
              ),
            ),
            // Double-ring border
            Container(
              width: size + 4,
              height: size + 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.roleColor.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
            ),
            // Inner Rotating tracer
            RotationTransition(
              turns: _rotationController,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.8),
                      Colors.transparent,
                      widget.roleColor.withValues(alpha: 0.5),
                      Colors.white.withValues(alpha: 0.8),
                    ],
                  ),
                ),
              ),
            ),
            // Profile Image Avatar
            CircleAvatar(
              radius: size / 2 - 4,
              backgroundColor: Colors.white24,
              backgroundImage: widget.imageUrl != null && widget.imageUrl!.isNotEmpty
                  ? CachedNetworkImageProvider(widget.imageUrl!)
                  : null,
              child: widget.imageUrl == null || widget.imageUrl!.isEmpty
                  ? Icon(Icons.person, size: size * 0.45, color: Colors.white)
                  : null,
            ),
          ],
        );
      },
    );
  }
}

// Glassmorphic Section Container Card
class _GlassSectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _GlassSectionCard({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121214) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: isDark ? 0.3 : 0.03),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardTitle(context, title),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildCardTitle(BuildContext context, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          width: 4,
          height: 15,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF06B6D4)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withValues(alpha: 0.3),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0D9488), // High contrast premium section headers
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

// Custom Option Item Tile Widget with Press Scale & Glowing Icons
class _InteractiveSettingTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color themeColor;
  final VoidCallback onTap;
  final Widget? trailing;

  const _InteractiveSettingTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.themeColor,
    required this.onTap,
    this.trailing,
  });

  @override
  State<_InteractiveSettingTile> createState() => _InteractiveSettingTileState();
}

class _InteractiveSettingTileState extends State<_InteractiveSettingTile> with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => _scaleController.forward(),
        onTapUp: (_) {
          _scaleController.reverse();
          widget.onTap();
        },
        onTapCancel: () => _scaleController.reverse(),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: isDark 
                  ? (_isHovered ? widget.themeColor.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.015)) 
                  : (_isHovered ? widget.themeColor.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.005)),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isHovered 
                    ? widget.themeColor.withValues(alpha: 0.3) 
                    : (isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF1F5F9)),
                width: 1.2,
              ),
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: widget.themeColor.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : null,
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              leading: _buildIconBox(isDark),
              title: Text(
                widget.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF0F172A),
                ),
              ),
              subtitle: widget.subtitle != null
                  ? Text(
                      widget.subtitle!,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? Colors.white38 : Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  : null,
              trailing: widget.trailing ?? AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(5),
                transform: Matrix4.translationValues(_isHovered ? 4.0 : 0.0, 0.0, 0.0),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: _isHovered ? widget.themeColor : (isDark ? Colors.white30 : Colors.grey[400]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconBox(bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [widget.themeColor.withValues(alpha: 0.25), widget.themeColor.withValues(alpha: 0.05)]
              : [widget.themeColor.withValues(alpha: 0.18), widget.themeColor.withValues(alpha: 0.04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isHovered 
              ? widget.themeColor.withValues(alpha: 0.5) 
              : widget.themeColor.withValues(alpha: 0.2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.themeColor.withValues(alpha: _isHovered ? 0.2 : 0.06),
            blurRadius: _isHovered ? 12 : 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(widget.icon, color: widget.themeColor, size: 20),
    );
  }
}

// Custom Animated Theme Toggle Switch Widget
class _CustomThemeToggle extends StatelessWidget {
  const _CustomThemeToggle();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, mode) {
        final activeDark = mode == ThemeMode.dark;
        return GestureDetector(
          onTap: () => context.read<ThemeCubit>().toggleTheme(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 66,
            height: 34,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: activeDark
                  ? const LinearGradient(
                      colors: [Color(0xFF1E1E2F), Color(0xFF0F0C1B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : const LinearGradient(
                      colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              border: Border.all(
                color: activeDark 
                    ? Colors.white.withValues(alpha: 0.1) 
                    : Colors.white.withValues(alpha: 0.25),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: activeDark
                      ? const Color(0xFF0F0C1B).withValues(alpha: 0.4)
                      : const Color(0xFF0284C7).withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                PositionedDirectional(
                  start: activeDark ? 6 : 32,
                  top: 6,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: 0.7,
                    child: Icon(
                      activeDark ? Icons.star_rounded : Icons.cloud_rounded,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
                AnimatedAlign(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack,
                  alignment: activeDark ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: activeDark
                          ? const LinearGradient(
                              colors: [Colors.white, Color(0xFFF1F5F9)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : const LinearGradient(
                              colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      boxShadow: [
                        BoxShadow(
                          color: activeDark 
                              ? Colors.white.withValues(alpha: 0.3) 
                              : const Color(0xFFF59E0B).withValues(alpha: 0.4),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        activeDark ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                        color: activeDark ? const Color(0xFF1E1035) : Colors.white,
                        size: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Custom Sliding Language Segmented Controller
class _CustomLanguageSelector extends StatelessWidget {
  const _CustomLanguageSelector();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = context.locale.languageCode;
    final isEn = lang == 'en';
    
    return Container(
      width: 132,
      height: 38,
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withValues(alpha: 0.3) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOutCubic,
            alignment: isEn ? AlignmentDirectional.centerStart : AlignmentDirectional.centerEnd,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1.0,
              child: Container(
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (!isEn) {
                      context.setLocale(const Locale('en'));
                    }
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🇺🇸', style: TextStyle(fontSize: 13)),
                        const SizedBox(width: 4),
                        Text(
                          'EN',
                          style: TextStyle(
                            color: isEn ? Colors.white : (isDark ? Colors.white38 : const Color(0xFF64748B)),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (isEn) {
                      context.setLocale(const Locale('ar'));
                    }
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🇪🇬', style: TextStyle(fontSize: 13)),
                        const SizedBox(width: 4),
                        Text(
                          'AR',
                          style: TextStyle(
                            color: !isEn ? Colors.white : (isDark ? Colors.white38 : const Color(0xFF64748B)),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Custom Glassmorphic Animated Sign Out Button
class _InteractiveSignOutButton extends StatefulWidget {
  final VoidCallback onTap;
  const _InteractiveSignOutButton({required this.onTap});

  @override
  State<_InteractiveSignOutButton> createState() => _InteractiveSignOutButtonState();
}

class _InteractiveSignOutButtonState extends State<_InteractiveSignOutButton> with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => _scaleController.forward(),
        onTapUp: (_) {
          _scaleController.reverse();
          widget.onTap();
        },
        onTapCancel: () => _scaleController.reverse(),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isHovered
                    ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                    : [const Color(0xFFEF4444).withValues(alpha: 0.06), const Color(0xFFEF4444).withValues(alpha: 0.03)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _isHovered 
                    ? const Color(0xFFDC2626) 
                    : const Color(0xFFEF4444).withValues(alpha: 0.15),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEF4444).withValues(alpha: _isHovered ? 0.2 : 0.01),
                  blurRadius: _isHovered ? 16 : 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LineIcons.alternateSignOut,
                    color: _isHovered ? Colors.white : const Color(0xFFEF4444),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'sign_out'.tr(),
                    style: TextStyle(
                      color: _isHovered ? Colors.white : const Color(0xFFEF4444),
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Missing _GradientText Widget Implementation
class _GradientText extends StatelessWidget {
  final String text;
  final Gradient gradient;
  final TextStyle style;

  const _GradientText(
    this.text, {
    required this.gradient,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Text(
        text,
        style: style.copyWith(color: Colors.white),
      ),
    );
  }
}

// Entry Staggered Animator Widget
class _AnimatedSlideUp extends StatelessWidget {
  final Widget child;
  final int delayMs;
  const _AnimatedSlideUp({required this.child, required this.delayMs});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 24 * (1.0 - value)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.only(
          top: delayMs == 100 ? 0.0 : 4.0, // minor padding separation
        ),
        child: child,
      ),
    );
  }
}

// Glowing Status Indicator Dot
class _GlowingStatusDot extends StatefulWidget {
  const _GlowingStatusDot();

  @override
  State<_GlowingStatusDot> createState() => _GlowingStatusDotState();
}

class _GlowingStatusDotState extends State<_GlowingStatusDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 2.0, end: 8.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF10B981),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withValues(alpha: 0.6),
                blurRadius: _glowAnimation.value,
                spreadRadius: 1,
              ),
            ],
          ),
        );
      },
    );
  }
}

// Painter to draw copper lines on simulated metallic smart chip
class _ChipLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // Draw horizontal split line
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);
    // Draw vertical split lines
    canvas.drawLine(Offset(size.width * 0.35, 0), Offset(size.width * 0.35, size.height), paint);
    canvas.drawLine(Offset(size.width * 0.65, 0), Offset(size.width * 0.65, size.height), paint);

    // Draw concentric patterns on center sections
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(size.width * 0.35 + 2, 2, size.width * 0.65 - 2, size.height - 2),
        const Radius.circular(2),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Painter for drawing high-tech corner brackets (Cyberpunk HUD markers)
class _HUDCornerPainter extends CustomPainter {
  final Color color;
  final bool topLeft;
  final bool topRight;
  final bool bottomLeft;
  final bool bottomRight;

  _HUDCornerPainter({
    required this.color,
    this.topLeft = false,
    this.topRight = false,
    this.bottomLeft = false,
    this.bottomRight = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final w = size.width;
    final h = size.height;

    if (topLeft) {
      canvas.drawLine(const Offset(0, 0), Offset(w, 0), paint);
      canvas.drawLine(const Offset(0, 0), Offset(0, h), paint);
    } else if (topRight) {
      canvas.drawLine(Offset(w, 0), const Offset(0, 0), paint);
      canvas.drawLine(Offset(w, 0), Offset(w, h), paint);
    } else if (bottomLeft) {
      canvas.drawLine(Offset(0, h), Offset(w, h), paint);
      canvas.drawLine(Offset(0, h), const Offset(0, 0), paint);
    } else if (bottomRight) {
      canvas.drawLine(Offset(w, h), Offset(0, h), paint);
      canvas.drawLine(Offset(w, h), Offset(w, 0), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
