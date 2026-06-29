import 'dart:async';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';

class SystemHealthWidget extends StatefulWidget {
  const SystemHealthWidget({super.key});

  @override
  SystemHealthWidgetState createState() => SystemHealthWidgetState();
}

class SystemHealthWidgetState extends State<SystemHealthWidget> {
  Timer? _timer;
  double _currentLoad = 32.0;
  final List<FlSpot> _spots = [
    const FlSpot(0, 2.0),
    const FlSpot(1, 1.5),
    const FlSpot(2, 3.0),
    const FlSpot(3, 2.5),
    const FlSpot(4, 3.5),
    const FlSpot(5, 4.0),
    const FlSpot(6, 3.2),
  ];

  @override
  void initState() {
    super.initState();
    _startSimulation();
  }

  void _startSimulation() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) return;
      setState(() {
        // Shift spots left
        for (int i = 0; i < _spots.length - 1; i++) {
          _spots[i] = FlSpot(_spots[i].x, _spots[i + 1].y);
        }
        // Generate new value between 1.0 and 5.0
        final random = Random();
        final nextValue = 1.0 + random.nextDouble() * 4.0;
        _spots[_spots.length - 1] = FlSpot(_spots[_spots.length - 1].x, nextValue);

        // Map 1.0 -> 20% CPU load, 5.0 -> 98% CPU load
        _currentLoad = 20.0 + ((nextValue - 1.0) / 4.0) * 78.0;
      });
    });
  }

  // Method to allow manually forcing a refresh/ping (like when pull to refresh is triggered)
  void fetchStats() {
    final random = Random();
    setState(() {
      for (int i = 0; i < _spots.length; i++) {
        _spots[i] = FlSpot(_spots[i].x, 1.0 + random.nextDouble() * 4.0);
      }
      _currentLoad = 20.0 + (random.nextDouble() * 50.0);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isHighLoad = _currentLoad >= 75.0;
    final Color statusColor = isHighLoad ? Colors.orange : const Color(0xFF10B981);
    final String statusText = isHighLoad ? "WARNING" : "OPTIMAL";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1B15) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "INFRASTRUCTURE HEALTH",
                    style: TextStyle(
                      fontWeight: FontWeight.w900, 
                      color: isDark ? Colors.white38 : Colors.grey.shade400, 
                      fontSize: 10, 
                      letterSpacing: 1.5
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "System Load",
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
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(LineIcons.barChart, color: statusColor, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _spots,
                    isCurved: true,
                    gradient: const LinearGradient(colors: [Color(0xFF2ECC71), Color(0xFF10B981)]),
                    barWidth: 4,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [const Color(0xFF2ECC71).withValues(alpha: 0.2), const Color(0xFF10B981).withValues(alpha: 0.01)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildStatusIndicator("SERVER STATUS", statusText, statusColor, isDark),
          const SizedBox(height: 12),
          _buildStatusIndicator("CPU LOAD", "${_currentLoad.toStringAsFixed(1)}%", statusColor, isDark),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(String label, String status, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withValues(alpha: 0.1) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 0.5)),
          Row(
            children: [
              Container(
                width: 8, height: 8, 
                decoration: BoxDecoration(
                  color: color, 
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 2)],
                ),
              ),
              const SizedBox(width: 10),
              Text(status, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900)),
            ],
          ),
        ],
      ),
    );
  }
}
