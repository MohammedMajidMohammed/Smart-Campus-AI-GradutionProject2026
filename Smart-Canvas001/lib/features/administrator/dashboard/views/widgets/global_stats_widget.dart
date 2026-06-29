import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:smart_canvas/core/di/dependancy_injection.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GlobalStatsWidget extends StatefulWidget {
  const GlobalStatsWidget({super.key});

  @override
  GlobalStatsWidgetState createState() => GlobalStatsWidgetState();
}

class GlobalStatsWidgetState extends State<GlobalStatsWidget> {
  bool _isLoading = true;
  int _studentsCount = 0;
  int _professorsCount = 0;
  int _adminsCount = 0;
  int _totalCount = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    fetchStats();
  }

  Future<void> fetchStats() async {
    try {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final supabase = getIt<SupabaseClient>();

      // Fetch roles and users in parallel
      final results = await Future.wait([
        supabase.from('roles').select('id, name'),
        supabase.from('users').select('role_id'),
      ]);

      final roles = List<Map<String, dynamic>>.from(results[0]);
      final users = List<Map<String, dynamic>>.from(results[1]);

      int students = 0;
      int professors = 0;
      int admins = 0;

      for (var u in users) {
        final roleId = u['role_id'];
        final role = roles.firstWhere(
          (r) => r['id'] == roleId,
          orElse: () => <String, dynamic>{},
        );
        if (role.isNotEmpty) {
          final roleName = role['name'].toString().toLowerCase();
          if (roleName == 'student') {
            students++;
          } else if (roleName == 'professor' || roleName == 'doctor') {
            professors++;
          } else if (roleName == 'admin' || roleName == 'administrator') {
            admins++;
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _studentsCount = students;
        _professorsCount = professors;
        _adminsCount = admins;
        _totalCount = users.length;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Container(
        width: double.infinity,
        height: 340,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1B15) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.withValues(alpha: 0.06)),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF1E8449),
          ),
        ),
      );
    }

    final double total = _totalCount.toDouble();
    final double studentPercent = total == 0 ? 0.0 : (_studentsCount / total) * 100;
    final double professorPercent = total == 0 ? 0.0 : (_professorsCount / total) * 100;
    final double adminPercent = total == 0 ? 0.0 : (_adminsCount / total) * 100;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1B15) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "USER DISTRIBUTION",
                      style: TextStyle(
                        fontWeight: FontWeight.w900, 
                        color: isDark ? Colors.white38 : Colors.grey.shade400, 
                        fontSize: 10, 
                        letterSpacing: 1.5
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Campus Population",
                      style: TextStyle(
                        fontWeight: FontWeight.w900, 
                        fontSize: 20, 
                        color: isDark ? Colors.white : const Color(0xFF0F0E0A),
                        letterSpacing: -0.5
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E8449).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(LineIcons.users, color: Color(0xFF1E8449), size: 24),
                ),
              ],
            ),
          ),
          
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Text(
                "Error loading stats: $_errorMessage",
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            )
          else
            SizedBox(
              height: 240,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 6,
                      centerSpaceRadius: 60,
                      startDegreeOffset: 270,
                      sections: _totalCount == 0
                          ? [
                              PieChartSectionData(
                                color: Colors.grey.shade400,
                                value: 1,
                                radius: 20,
                                showTitle: false,
                              )
                            ]
                          : [
                              PieChartSectionData(
                                color: const Color(0xFF1E8449),
                                value: _studentsCount == 0 ? 0.1 : _studentsCount.toDouble(),
                                radius: 24,
                                showTitle: false,
                                badgeWidget: _buildPercentageBadge("${studentPercent.toStringAsFixed(0)}%", const Color(0xFF1E8449)),
                                badgePositionPercentageOffset: 1.5,
                              ),
                              PieChartSectionData(
                                color: const Color(0xFF1E8449),
                                value: _professorsCount == 0 ? 0.1 : _professorsCount.toDouble(),
                                radius: 20,
                                showTitle: false,
                                badgeWidget: _buildPercentageBadge("${professorPercent.toStringAsFixed(0)}%", const Color(0xFF1E8449)),
                                badgePositionPercentageOffset: 1.5,
                              ),
                              PieChartSectionData(
                                color: const Color(0xFF10B981),
                                value: _adminsCount == 0 ? 0.1 : _adminsCount.toDouble(),
                                radius: 16,
                                showTitle: false,
                                badgeWidget: _buildPercentageBadge("${adminPercent.toStringAsFixed(0)}%", const Color(0xFF10B981)),
                                badgePositionPercentageOffset: 1.5,
                              ),
                            ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "TOTAL".tr(), 
                        style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 2)
                      ),
                      Text(
                        NumberFormat('#,###').format(_totalCount), 
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 32, letterSpacing: -1)
                      ),
                    ],
                  ),
                ],
              ),
            ),
          
          Container(
             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
             decoration: BoxDecoration(
               color: isDark ? Colors.black.withValues(alpha: 0.15) : Colors.grey.shade50,
               borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
             ),
             child: Row(
               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
               children: [
                 _buildLegend(const Color(0xFF1E8449), "Students ($_studentsCount)"),
                 _buildLegend(const Color(0xFF1E8449), "Professors ($_professorsCount)"),
                 _buildLegend(const Color(0xFF10B981), "Admins ($_adminsCount)"),
               ],
             ),
          ),
        ],
      ),
    );
  }

  Widget _buildPercentageBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8)],
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey)),
      ],
    );
  }
}
