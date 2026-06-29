import 'package:smart_canvas/core/components/custom_professional_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_canvas/core/components/animated_card.dart';
import 'package:smart_canvas/core/components/shimmer_loading.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:smart_canvas/features/administrator/user_management/view_models/cubit/users_cubit.dart';
import 'package:smart_canvas/features/administrator/user_management/views/widgets/add_user_dialog.dart';
import 'package:smart_canvas/features/administrator/user_management/views/widgets/edit_user_dialog.dart';
import 'package:smart_canvas/features/administrator/user_management/views/widgets/user_card.dart';
import 'package:smart_canvas/features/administrator/user_management/models/user_model.dart';
import 'package:smart_canvas/features/administrator/user_management/views/widgets/bulk_import_dialog.dart';
import 'package:easy_localization/easy_localization.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = SizeConfig.width;
    final height = SizeConfig.height;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFAF9F5),
      body: SafeArea(
        child: Column(
          children: [
            // Premium Glassmorphic Header
            Container(
              padding: EdgeInsets.only(
                top: SizeConfig.w(4),
                left: SizeConfig.w(5),
                right: SizeConfig.w(5),
                bottom: SizeConfig.w(6),
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Back Button
                      _buildHeaderButton(
                        icon: Icons.arrow_back_ios_new,
                        onTap: () => Navigator.pop(context),
                        color: AppColors.kPrimaryColor,
                        isDark: isDark,
                      ),
                      SizedBox(width: width * 0.04),
                      // Title Section
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'user_management_title'.tr(),
                              style: TextStyle(
                                fontSize: SizeConfig.w(6),
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : const Color(0xFF1A1C1E),
                                letterSpacing: -0.5,
                              ),
                            ),
                            BlocBuilder<UsersCubit, UsersState>(
                              builder: (context, state) {
                                final count = context.read<UsersCubit>().users.length;
                                return Text(
                                  'specialists_registered'.tr(args: [count.toString()]),
                                  style: TextStyle(
                                    fontSize: SizeConfig.w(3.2),
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.w500,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      // Actions
                      Row(
                        children: [
                          _buildHeaderButton(
                            icon: Icons.refresh_rounded,
                            onTap: () => context.read<UsersCubit>().fetchUsers(),
                            color: Colors.grey.shade600,
                            isDark: isDark,
                          ),
                          SizedBox(width: width * 0.02),
                          _buildHeaderButton(
                            icon: Icons.file_upload_outlined,
                            onTap: () => showDialog(
                              context: context,
                              builder: (context) => const BulkImportDialog(),
                            ),
                            color: AppColors.kPrimaryColor,
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: height * 0.025),
                  // Search Area
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 55,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.transparent,
                            ),
                          ),
                          child: TextField(
                            controller: context.read<UsersCubit>().searchController,
                            onChanged: (value) => context.read<UsersCubit>().searchUsers(value),
                            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                            decoration: InputDecoration(
                              hintText: "search_user_hint".tr(),
                              hintStyle: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: width * 0.035,
                              ),
                              prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: height * 0.02),
                  // Fast Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: BlocBuilder<UsersCubit, UsersState>(
                      builder: (context, state) {
                        final cubit = context.read<UsersCubit>();
                        return Row(
                          children: [
                            _buildFilterChip(
                              context,
                              label: "all_filter".tr(),
                              value: null,
                              isSelected: cubit.selectedRoleFilter == null,
                            ),
                            ...cubit.roles.map((role) => _buildFilterChip(
                              context,
                              label: role.name,
                              value: role.name,
                              isSelected: cubit.selectedRoleFilter?.toLowerCase() == role.name.toLowerCase(),
                            )),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Users List
            Expanded(
              child: BlocConsumer<UsersCubit, UsersState>(
                listenWhen: (p, c) =>
                    c is DeleteUserSuccess || c is DeleteUserFailure,
                listener: (context, state) {
                  if (state is DeleteUserSuccess) {
                    CustomProfessionalDialog.showSuccess(
                      context,
                      title: 'success_msg'.tr(),
                      message: 'user_deleted_success'.tr(),
                    );
                  } else if (state is DeleteUserFailure) {
                    CustomProfessionalDialog.showError(
                      context,
                      title: 'error_msg'.tr(),
                      message: state.message,
                    );
                  }
                },
                buildWhen: (p, c) =>
                    c is UsersSuccess ||
                    c is UsersLoading ||
                    c is UsersFailure,
                builder: (context, state) {
                  if (state is UsersLoading) {
                    return ListView.builder(
                      padding: EdgeInsets.all(width * 0.05),
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 5,
                      itemBuilder: (context, index) => const ShimmerUserCard(),
                    );
                  }

                  if (state is UsersFailure) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: width * 0.15,
                            color: Colors.grey.shade400,
                          ),
                          SizedBox(height: height * 0.02),
                          Text(
                            'error_loading_users'.tr(),
                            style: TextStyle(
                              fontSize: width * 0.04,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          SizedBox(height: height * 0.02),
                          ElevatedButton(
                            onPressed: () =>
                                context.read<UsersCubit>().fetchUsers(),
                            child: Text('retry_lbl'.tr()),
                          ),
                        ],
                      ),
                    );
                  }

                  final cubit = context.read<UsersCubit>();
                  final users = cubit.filteredUsers;
                  final isSearching = cubit.selectedRoleFilter != null || cubit.searchController.text.isNotEmpty;

                  if (users.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.all(width * 0.08),
                              decoration: BoxDecoration(
                                color: AppColors.kPrimaryColor.withValues(alpha: 0.05),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isSearching ? Icons.search_off_rounded : Icons.people_outline_rounded,
                                size: width * 0.15,
                                color: AppColors.kPrimaryColor.withValues(alpha: 0.4),
                              ),
                            ),
                            SizedBox(height: height * 0.03),
                            Text(
                              isSearching ? 'no_matching_users'.tr() : 'no_users_registered'.tr(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: width * 0.05,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF1A1C1E),
                                letterSpacing: -0.5,
                              ),
                            ),
                            SizedBox(height: height * 0.01),
                            Text(
                              isSearching 
                                  ? 'adjust_search_desc'.tr() 
                                  : 'add_first_user_desc'.tr(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: width * 0.035,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w500,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: SizeConfig.maxContentWidth,
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isTablet = constraints.maxWidth > 700;
                          
                          if (isTablet) {
                            return GridView.builder(
                              padding: EdgeInsets.symmetric(
                                horizontal: SizeConfig.horizontalPadding,
                                vertical: SizeConfig.verticalPadding,
                              ),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 2.22,
                                crossAxisSpacing: 20,
                                mainAxisSpacing: 0,
                              ),
                              itemCount: users.length,
                              itemBuilder: (context, index) {
                                final user = users[index];
                                return StaggeredListItem(
                                  index: index,
                                  child: UserCard(
                                    user: user,
                                    onEdit: () => _showEditUserDialog(context, user),
                                    onDelete: () => _showDeleteConfirmation(context, user.id),
                                  ),
                                );
                              },
                            );
                          }

                          return ListView.builder(
                            padding: EdgeInsets.symmetric(
                              horizontal: SizeConfig.horizontalPadding,
                              vertical: SizeConfig.verticalPadding,
                            ),
                            itemCount: users.length,
                            itemBuilder: (context, index) {
                              final user = users[index];
                              return StaggeredListItem(
                                index: index,
                                child: UserCard(
                                  user: user,
                                  onEdit: () => _showEditUserDialog(context, user),
                                  onDelete: () => _showDeleteConfirmation(context, user.id),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      // Floating Action Button
      floatingActionButton: Container(
        height: 64,
        width: 64,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.kPrimaryColor,
              AppColors.kPrimaryColor.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.kPrimaryColor.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => _showAddUserDialog(context),
          backgroundColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Icon(
            Icons.add_rounded,
            color: Colors.white,
            size: SizeConfig.w(8),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon,
          color: color,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required String? value,
    required bool isSelected,
  }) {
    final width = SizeConfig.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        onTap: () => context.read<UsersCubit>().filterByRole(value),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: width * 0.04,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.kPrimaryColor
                : (isDark ? Colors.grey.shade900 : Colors.grey.shade100),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.kPrimaryColor
                  : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.transparent),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
              fontSize: width * 0.032,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  void _showAddUserDialog(BuildContext context) {
    final cubit = context.read<UsersCubit>();
    cubit.resetForm();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider.value(
        value: cubit,
        child: const AddUserDialog(),
      ),
    );
  }

  void _showEditUserDialog(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<UsersCubit>(),
        child: EditUserDialog(user: user),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String userId) {
    final width = SizeConfig.width;
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(width * 0.02),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.warning_amber,
                color: Colors.red.shade400,
                size: width * 0.06,
              ),
            ),
            SizedBox(width: width * 0.03),
            SizedBox(width: width * 0.03),
            Text('delete_user_title'.tr()),
          ],
        ),
        content: Text(
          'delete_user_confirm'.tr(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'cancel'.tr(),
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<UsersCubit>().deleteUser(userId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'delete_lbl'.tr(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
