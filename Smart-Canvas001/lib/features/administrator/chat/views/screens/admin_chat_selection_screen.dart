import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:line_icons/line_icons.dart';
import 'package:smart_canvas/core/di/dependancy_injection.dart';
import 'package:smart_canvas/features/administrator/collages/view_models/cubit/colleges_cubit.dart';
import 'package:smart_canvas/features/administrator/user_management/view_models/cubit/users_cubit.dart';
import 'package:smart_canvas/features/chat/services/chat_service.dart';
import 'package:smart_canvas/features/chat/views/screens/generic_chat_screen.dart';
import 'package:smart_canvas/features/chat/view_models/cubit/generic_chat_cubit.dart';
import 'package:easy_localization/easy_localization.dart';

class AdminChatManagementScreen extends StatefulWidget {
  const AdminChatManagementScreen({super.key});

  @override
  State<AdminChatManagementScreen> createState() => _AdminChatManagementScreenState();
}

class _AdminChatManagementScreenState extends State<AdminChatManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _stopSearching(BuildContext context) {
    setState(() {
      _isSearching = false;
      _searchController.clear();
    });
    context.read<UsersCubit>().searchUsers('');
    context.read<CollegesCubit>().searchColleges('');
  }

  void _showInfoBottomSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      backgroundColor: isDark ? const Color(0xFF1E1B15) : Colors.white,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E8449).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.school, color: Color(0xFF1E8449), size: 28),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    "Administrative Directory",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                "This portal allows system administrators to communicate directly with university members:\n\n• Professors tab: Start private direct chat rooms with specific faculty members.\n• Colleges tab: Open official group channels for specific college announcements and discussions.",
                style: TextStyle(fontSize: 14, height: 1.5, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E8449),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Got it", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => UsersCubit()..filterByRole('Professor')),
        BlocProvider(create: (context) => CollegesCubit()),
      ],
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: isDark ? const Color(0xFF0F0E0A) : const Color(0xFFFAF9F5),
            appBar: AppBar(
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              centerTitle: true,
              title: _isSearching
                  ? Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        cursorColor: Colors.white,
                        decoration: InputDecoration(
                          hintText: 'search_users_reports'.tr(),
                          border: InputBorder.none,
                          prefixIcon: const Icon(LineIcons.search, color: Colors.white70, size: 20),
                          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 14),
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                        onChanged: (value) {
                          context.read<UsersCubit>().searchUsers(value);
                          context.read<CollegesCubit>().searchColleges(value);
                        },
                      ),
                    )
                  : const Text(
                      'Administrative Chat',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        fontSize: 20,
                        letterSpacing: -0.5,
                      ),
                    ),
              actions: [
                if (_isSearching)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _stopSearching(context);
                    },
                  )
                else
                  IconButton(
                    icon: const Icon(LineIcons.search),
                    onPressed: () {
                      setState(() {
                        _isSearching = true;
                      });
                    },
                  ),
                PopupMenuButton<String>(
                  icon: const Icon(LineIcons.verticalEllipsis),
                  onSelected: (value) {
                    if (value == 'refresh') {
                      context.read<UsersCubit>().fetchUsers();
                      context.read<CollegesCubit>().getColleges();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.sync, color: Colors.white),
                              const SizedBox(width: 8),
                              Text('refreshing_data'.tr()),
                            ],
                          ),
                          backgroundColor: const Color(0xFF1E8449),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    } else if (value == 'info') {
                      _showInfoBottomSheet(context);
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem(
                      value: 'refresh',
                      child: Row(
                        children: [
                          const Icon(Icons.refresh, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text('refresh'.tr()),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'info',
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text('about_chat'.tr()),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              bottom: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  color: Colors.white.withValues(alpha: 0.15),
                ),
                indicatorPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LineIcons.userTie, size: 20),
                        const SizedBox(width: 8),
                        Text('Professors'.tr(), style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LineIcons.university, size: 20),
                        const SizedBox(width: 8),
                        Text('Colleges'.tr(), style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                ],
                indicatorColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withValues(alpha: 0.65),
                labelStyle: const TextStyle(fontWeight: FontWeight.w900),
              ),
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1E1B15), const Color(0xFF0F0E0A)]
                        : [const Color(0xFF1E8449), const Color(0xFF1E8449)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildProfessorsTab(isDark),
                _buildCollegesTab(isDark),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfessorsTab(bool isDark) {
    return BlocBuilder<UsersCubit, UsersState>(
      builder: (context, state) {
        if (state is UsersLoading) return const Center(child: CircularProgressIndicator());
        if (state is UsersFailure) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                state.message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
              ),
            ),
          );
        }

        final cubit = context.read<UsersCubit>();
        final professors = cubit.filteredUsers.where((u) {
          final role = u.roleName?.toLowerCase();
          return role == 'professor' || role == 'doctor';
        }).toList();

        // Sort professors: Online first, then alphabetical by name
        professors.sort((a, b) {
          final aOnline = cubit.onlineUserIds.contains(a.id);
          final bOnline = cubit.onlineUserIds.contains(b.id);
          if (aOnline && !bOnline) return -1;
          if (!aOnline && bOnline) return 1;
          return a.fullName.compareTo(b.fullName);
        });

        if (professors.isEmpty) {
          if (state is UsersInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LineIcons.search, size: 64, color: Colors.grey.withValues(alpha: 0.4)),
                const SizedBox(height: 16),
                Text('no_professors_found'.tr(), style: TextStyle(fontSize: 16, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
              ],
            ),
          );
        }
        
        return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            itemCount: professors.length,
            itemBuilder: (context, index) {
              final prof = professors[index];
              final isOnline = cubit.onlineUserIds.contains(prof.id);

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1B15) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.grey.shade200,
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                  border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.08)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  leading: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: isOnline 
                                ? [const Color(0xFF1E8449), const Color(0xFF10B981)] 
                                : [Colors.grey.shade400, Colors.grey.shade600],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 26,
                          backgroundColor: isDark ? const Color(0xFF1E1B15) : Colors.white,
                          backgroundImage: prof.image != null && prof.image!.isNotEmpty
                              ? NetworkImage(prof.image!)
                              : null,
                          child: prof.image == null || prof.image!.isEmpty
                              ? Text(
                                  prof.fullName.substring(0, 1).toUpperCase(),
                                  style: TextStyle(
                                    color: isOnline ? const Color(0xFF1E8449) : Colors.grey.shade600, 
                                    fontWeight: FontWeight.w900, 
                                    fontSize: 20
                                  ),
                                )
                              : null,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 13,
                          height: 13,
                          decoration: BoxDecoration(
                            color: isOnline ? const Color(0xFF10B981) : Colors.grey.shade400,
                            shape: BoxShape.circle,
                            border: Border.all(color: isDark ? const Color(0xFF1E1B15) : Colors.white, width: 2.5),
                            boxShadow: isOnline ? [
                              BoxShadow(
                                color: const Color(0xFF10B981).withValues(alpha: 0.4),
                                blurRadius: 4,
                                spreadRadius: 1,
                              )
                            ] : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          prof.fullName,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: isDark ? Colors.white : const Color(0xFF0F0E0A),
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isOnline 
                              ? const Color(0xFF10B981).withValues(alpha: 0.08) 
                              : Colors.grey.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isOnline ? "Online" : "Away",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: isOnline ? const Color(0xFF10B981) : Colors.grey.shade500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        prof.email,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (prof.collegeName != null) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E8449).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            prof.collegeName!,
                            style: const TextStyle(
                              color: Color(0xFF1E8449),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E8449).withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF1E8449).withValues(alpha: 0.12)),
                    ),
                    child: const Icon(LineIcons.paperPlane, color: Color(0xFF1E8449), size: 18),
                  ),
                  onTap: () => _openChat(context, type: 'private_admin_prof', targetId: prof.id, title: prof.fullName),
                ),
              ).animate().fadeIn(delay: (index * 40).ms).slideY(begin: 0.08);
            },
          );
      },
    );
  }

  Widget _buildCollegesTab(bool isDark) {
    return BlocBuilder<CollegesCubit, CollegesState>(
      builder: (context, state) {
        if (state is GetCollegesLoading) return const Center(child: CircularProgressIndicator());
        if (state is GetCollegesSuccess) {
          final colleges = context.read<CollegesCubit>().filteredColleges;
          if (colleges.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LineIcons.search, size: 64, color: Colors.grey.withValues(alpha: 0.4)),
                  const SizedBox(height: 16),
                  Text('no_colleges_found'.tr(), style: TextStyle(fontSize: 16, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            itemCount: colleges.length,
            itemBuilder: (context, index) {
              final college = colleges[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1B15) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.grey.shade200,
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                  border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.08)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E8449).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF1E8449).withValues(alpha: 0.12)),
                    ),
                    child: const Icon(LineIcons.university, color: Color(0xFF1E8449), size: 24),
                  ),
                  title: Text(
                    college.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: isDark ? Colors.white : const Color(0xFF0F0E0A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        college.abbreviation,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E8449).withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF1E8449).withValues(alpha: 0.12)),
                    ),
                    child: const Icon(LineIcons.users, color: Color(0xFF1E8449), size: 18),
                  ),
                  onTap: () => _openChat(context, type: 'college_group', targetId: college.id, title: college.name, subtitle: 'College Community'),
                ),
              ).animate().fadeIn(delay: (index * 40).ms).slideY(begin: 0.08);
            },
          );
        }
        return const SizedBox();
      },
    );
  }

  Future<void> _openChat(BuildContext context, {required String type, required String targetId, required String title, String? subtitle}) async {
    final chatService = getIt<ChatService>();
    
    // Show loading
    showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));
    
    try {
      final room = await chatService.getOrCreateRoom(type: type, targetId: targetId);
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BlocProvider(
            create: (context) => getIt<GenericChatCubit>(),
            child: GenericChatScreen(
              roomId: room.id,
              roomTitle: title,
              roomSubtitle: subtitle,
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}
