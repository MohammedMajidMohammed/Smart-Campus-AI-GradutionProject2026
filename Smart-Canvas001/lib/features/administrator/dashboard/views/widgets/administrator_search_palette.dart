import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:smart_canvas/core/app_route/route_names.dart';
import 'package:smart_canvas/core/utilies/extensions/app_extensions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_canvas/features/administrator/home/view_models/cubit/administrator_bottom_nav_bar_cubit.dart';

class AdministratorSearchPalette extends StatefulWidget {
  const AdministratorSearchPalette({super.key});

  static void show(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Command Palette",
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) {
        return const AdministratorSearchPalette();
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: 0.95 + 0.05 * anim1.value,
          child: Opacity(
            opacity: anim1.value,
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<AdministratorSearchPalette> createState() => _AdministratorSearchPaletteState();
}

class _AdministratorSearchPaletteState extends State<AdministratorSearchPalette> {
  final TextEditingController _searchController = TextEditingController();
  String _query = "";

  late final List<Map<String, dynamic>> _destinations;

  @override
  void initState() {
    super.initState();
    _destinations = [
      {
        "title": "users".tr(),
        "subtitle": "Manage students, professors, and administrative staff",
        "icon": Icons.people_rounded,
        "color": const Color(0xFF2ECC71),
        "route": RouteNames.usersScreen,
      },
      {
        "title": "buildings".tr(),
        "subtitle": "Configure and map university campus halls and towers",
        "icon": Icons.apartment_rounded,
        "color": const Color(0xFF1E8449),
        "route": RouteNames.buildingsScreen,
      },
      {
        "title": "rooms".tr(),
        "subtitle": "Manage classrooms, lecture rooms, and labs",
        "icon": Icons.meeting_room_rounded,
        "color": const Color(0xFF10B981),
        "route": RouteNames.roomsScreen,
      },
      {
        "title": "colleges".tr(),
        "subtitle": "Configure colleges, departments, and faculties",
        "icon": Icons.school_rounded,
        "color": const Color(0xFF8B5CF6),
        "route": RouteNames.collegesScreen,
      },
      {
        "title": "schedules".tr(),
        "subtitle": "Manage lecture timetables and schedules",
        "icon": Icons.table_chart_rounded,
        "color": const Color(0xFFF59E0B),
        "route": RouteNames.tablesScreen,
      },
      {
        "title": "news".tr(),
        "subtitle": "Send announcements and university campus broadcasts",
        "icon": Icons.campaign_rounded,
        "color": const Color(0xFF06B6D4),
        "route": RouteNames.enhancedNotificationsScreen,
      },
      {
        "title": "Administrative Chat",
        "subtitle": "Direct channels with students and professors",
        "icon": LineIcons.facebookMessenger,
        "color": const Color(0xFF3B82F6),
        "index": 1,
      },
      {
        "title": "Notifications Log",
        "subtitle": "View system notifications and broadcasts history",
        "icon": LineIcons.bell,
        "color": const Color(0xFFEC4899),
        "index": 2,
      },
      {
        "title": "System Settings",
        "subtitle": "App configuration, themes, and account security",
        "icon": LineIcons.cog,
        "color": Colors.grey,
        "index": 3,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final filtered = _destinations.where((item) {
      final titleMatch = item['title'].toString().toLowerCase().contains(_query.toLowerCase());
      final subtitleMatch = item['subtitle'].toString().toLowerCase().contains(_query.toLowerCase());
      return titleMatch || subtitleMatch;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.65,
            ),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1B15) : Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Search Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      Icon(LineIcons.search, color: isDark ? Colors.white54 : Colors.grey.shade400),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16),
                          decoration: InputDecoration(
                            hintText: "Search shortcuts instantly...",
                            hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.grey.shade400, fontSize: 14),
                            border: InputBorder.none,
                          ),
                          onChanged: (val) {
                            setState(() {
                              _query = val;
                            });
                          },
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: isDark ? Colors.white38 : Colors.grey),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Divider(color: isDark ? Colors.white10 : Colors.grey.shade200, height: 1),
                
                // Result list
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            "No results for \"$_query\"",
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                          itemCount: filtered.length,
                          separatorBuilder: (context, index) => Divider(
                            color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.grey.withValues(alpha: 0.02), 
                            height: 1
                          ),
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            final color = item['color'] as Color;
                            return ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(item['icon'] as IconData, color: color, size: 22),
                              ),
                              title: Text(
                                item['title'] as String,
                                style: TextStyle(
                                  color: isDark ? Colors.white : const Color(0xFF1E1B15),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                item['subtitle'] as String,
                                style: TextStyle(
                                  color: isDark ? Colors.white38 : Colors.grey.shade500,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Icon(Icons.arrow_forward_ios_rounded, color: isDark ? Colors.white24 : Colors.grey.shade300, size: 12),
                              onTap: () {
                                Navigator.pop(context); // Close palette
                                if (item['index'] != null) {
                                  context.read<AdministratorBottomNavBarCubit>().changeIndex(item['index'] as int);
                                } else {
                                  context.pushScreen(item['route'] as String);
                                }
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
