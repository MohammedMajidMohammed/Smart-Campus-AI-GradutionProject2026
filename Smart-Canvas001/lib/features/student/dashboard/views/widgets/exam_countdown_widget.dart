import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class LectureCountdownWidget extends StatefulWidget {
  final String title;
  final DateTime startTime;
  final DateTime? endTime;
  final bool isExam;

  const LectureCountdownWidget({
    super.key,
    required this.title,
    required this.startTime,
    this.endTime,
    this.isExam = false,
  });

  @override
  State<LectureCountdownWidget> createState() => _LectureCountdownWidgetState();
}

class _LectureCountdownWidgetState extends State<LectureCountdownWidget> {
  late Timer _timer;
  late Duration _timeLeft;
  bool _isOngoing = false;

  @override
  void initState() {
    super.initState();
    _calculateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _calculateTime();
    });
  }

  void _calculateTime() {
    if (!mounted) return;
    final now = DateTime.now();
    setState(() {
      if (now.isBefore(widget.startTime)) {
        _timeLeft = widget.startTime.difference(now);
        _isOngoing = false;
      } else if (widget.endTime != null && now.isBefore(widget.endTime!)) {
        _timeLeft = widget.endTime!.difference(now);
        _isOngoing = true;
      } else {
        _timeLeft = Duration.zero;
        _isOngoing = false;
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_timeLeft == Duration.zero && !_isOngoing) return const SizedBox();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = _isOngoing ? const Color(0xFFEF4444) : const Color(0xFF2ECC71);
    
    final bgGradient = _isOngoing
        ? [const Color(0xFFFEF2F2), const Color(0xFFFEE2E2)]
        : [const Color(0xFFFAF9F5), const Color(0xFFF1F5F9)];

    final darkBgGradient = _isOngoing
        ? [const Color(0xFF450A0A), const Color(0xFF7F1D1D)]
        : [const Color(0xFF1E1B15), const Color(0xFF0F0E0A)];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark ? darkBgGradient : bgGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30, top: -20,
            child: Icon(Icons.timer_outlined, size: 120, color: accentColor.withValues(alpha: 0.04)),
          ),
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: accentColor.withValues(alpha: 0.15)),
                      ),
                      child: Text(
                        _isOngoing 
                            ? "${"live_now".tr()} ⚡" 
                            : (widget.isExam ? "upcoming_exam".tr() : "upcoming_lecture".tr()),
                        style: TextStyle(
                          color: accentColor, 
                          fontWeight: FontWeight.w900, 
                          fontSize: 11, 
                          letterSpacing: 1.2
                        ),
                      ),
                    ),
                    Icon(Icons.more_horiz, color: accentColor.withValues(alpha: 0.3)),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  widget.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w900, fontSize: 26,
                    color: isDark ? Colors.white : const Color(0xFF1E1B15),
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTimeBox(_timeLeft.inDays, "days_lbl".tr(), accentColor, isDark),
                    _buildTimeBox(_timeLeft.inHours % 24, "hours_lbl".tr(), accentColor, isDark),
                    _buildTimeBox(_timeLeft.inMinutes % 60, "mins_lbl".tr(), accentColor, isDark),
                    _buildTimeBox(_timeLeft.inSeconds % 60, "Secs", accentColor, isDark), // Keeping 'Secs' short for UI
                  ],
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: isDark ? 0.05 : 0.03),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03)),
                  ),
                  child: Row(
                    children: [
                      _buildMiniInfo(Icons.play_circle_fill, "Starts", DateFormat('hh:mm a').format(widget.startTime), accentColor, isDark),
                      const Spacer(),
                      if (widget.endTime != null)
                        _buildMiniInfo(Icons.stop_circle_rounded, "Ends", DateFormat('hh:mm a').format(widget.endTime!), accentColor, isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeBox(int value, String label, Color color, bool isDark) {
    return Column(
      children: [
        Text(
          value.toString().padLeft(2, '0'),
          style: TextStyle(
            fontSize: 32, fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : const Color(0xFF1E1B15),
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color.withValues(alpha: 0.6), letterSpacing: 0.8),
        ),
      ],
    );
  }

  Widget _buildMiniInfo(IconData icon, String label, String value, Color color, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isDark ? Colors.white38 : Colors.black45)),
            Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF1E1B15))),
          ],
        ),
      ],
    );
  }
}
