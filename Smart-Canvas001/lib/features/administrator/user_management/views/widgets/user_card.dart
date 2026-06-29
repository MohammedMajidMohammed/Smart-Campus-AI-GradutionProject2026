import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:smart_canvas/features/administrator/user_management/models/user_model.dart';

class UserCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const UserCard({
    super.key,
    required this.user,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final width = SizeConfig.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final roleColors = _getRoleColors(user.roleName);

    return Container(
      margin: EdgeInsets.only(bottom: width * 0.04),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1B15).withValues(alpha: 0.7) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(width * 0.045),
            child: Row(
              children: [
                // Avatar with Dynamic Role-colored Gradient Border
                Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        roleColors[0],
                        roleColors.length > 1 ? roleColors[1] : roleColors[0].withValues(alpha: 0.2),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F0E0A) : Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: width * 0.08,
                      backgroundColor: roleColors[0].withValues(alpha: 0.08),
                      child: ClipOval(
                        child: user.image != null && user.image!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: user.image!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                errorWidget: (context, url, error) => Icon(
                                  _getRoleIcon(user.roleName),
                                  size: width * 0.08,
                                  color: roleColors[0],
                                ),
                              )
                            : Icon(
                                _getRoleIcon(user.roleName),
                                size: width * 0.08,
                                color: roleColors[0],
                              ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: width * 0.04),
                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: TextStyle(
                          fontSize: width * 0.042,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : const Color(0xFF0F0E0A),
                          letterSpacing: -0.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.email,
                        style: TextStyle(
                          fontSize: width * 0.03,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: width * 0.025),
                      // Badges Row
                      Wrap(
                        spacing: width * 0.02,
                        runSpacing: width * 0.015,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _buildRoleBadge(width),
                          if ((user.roleName?.toLowerCase() == 'student' || user.roleName?.toLowerCase() == 'professor' || user.roleName?.toLowerCase() == 'doctor') && 
                              user.collegeName != null && user.collegeName!.isNotEmpty)
                            _buildContextBadge(width),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Action Buttons
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (onEdit != null)
                      _buildSmallIconButton(
                        icon: Icons.edit_rounded,
                        color: Colors.orange,
                        onPressed: onEdit!,
                        width: width,
                      ),
                    if (onDelete != null) ...[
                      SizedBox(height: width * 0.03),
                      _buildSmallIconButton(
                        icon: Icons.delete_rounded,
                        color: Colors.red,
                        onPressed: onDelete!,
                        width: width,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleBadge(double width) {
    final colors = _getRoleColors(user.roleName);
    final icon = _getRoleIcon(user.roleName);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: width * 0.025,
        vertical: width * 0.01,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: colors[0].withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: width * 0.032,
            color: Colors.white,
          ),
          SizedBox(width: width * 0.01),
          Text(
            user.roleName ?? '',
            style: TextStyle(
              fontSize: width * 0.025,
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContextBadge(double width) {
    final isStudent = user.roleName?.toLowerCase() == 'student';
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: width * 0.025,
        vertical: width * 0.01,
      ),
      decoration: BoxDecoration(
        color: AppColors.kPrimaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.kPrimaryColor.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.school_outlined,
            size: width * 0.03,
            color: AppColors.kPrimaryColor,
          ),
          SizedBox(width: width * 0.01),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: width * 0.35),
            child: Text(
              isStudent 
                  ? "${user.collegeName} • Y${user.currentYear ?? '?'}"
                  : "${user.collegeName}${user.academicYearName != null ? ' • ${user.academicYearName}' : ''}",
              style: TextStyle(
                fontSize: width * 0.025,
                color: AppColors.kPrimaryColor,
                fontWeight: FontWeight.w800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required double width,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: color,
          size: width * 0.045,
        ),
      ),
    );
  }

  IconData _getRoleIcon(String? roleName) {
    switch (roleName?.toLowerCase().trim()) {
      case 'admin':
      case 'administrator':
        return Icons.admin_panel_settings_rounded;
      case 'professor':
        return Icons.school_rounded;
      case 'student':
        return Icons.person_rounded;
      case 'doctor':
        return Icons.medical_services_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  List<Color> _getRoleColors(String? roleName) {
    switch (roleName?.toLowerCase().trim()) {
      case 'admin':
      case 'administrator':
        return [const Color(0xFF2ECC71), const Color(0xFF1E8449)];
      case 'professor':
        return [const Color(0xFF10B981), const Color(0xFF059669)];
      case 'student':
        return [const Color(0xFFF59E0B), const Color(0xFFD97706)];
      case 'doctor':
        return [const Color(0xFF1E8449), const Color(0xFF1E8449)];
      default:
        return [const Color(0xFF94A3B8), const Color(0xFF64748B)];
    }
  }
}
