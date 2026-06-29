import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';

class CustomBottomNavBar extends StatelessWidget {
  const CustomBottomNavBar({
    super.key,
    required this.taps,
    this.selectedIndex = 0,
  });
  final List<GButton> taps;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final activeGradient = isDark
        ? const LinearGradient(
            colors: [Color(0xFF1E8449), Color(0xFFB89626)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFF2ECC71), Color(0xFF1E8449)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    final activeShadowColor = isDark 
        ? const Color(0xFF1E8449).withValues(alpha: 0.35) 
        : const Color(0xFF1E8449).withValues(alpha: 0.3);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.width * 0.05,
        vertical: SizeConfig.width * 0.03,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
              blurRadius: 25,
              spreadRadius: -2,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              height: 76,
              decoration: BoxDecoration(
                color: isDark 
                    ? const Color(0xFF0F0E0A).withValues(alpha: 0.8) 
                    : Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                  width: 1.5,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final totalWidth = constraints.maxWidth;
                  final tabCount = taps.length;
                  final tabWidth = totalWidth / tabCount;
                  final pillWidth = tabWidth - 12;

                  return Stack(
                    children: [
                      // Sliding Active Pill Background
                      AnimatedPositionedDirectional(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutQuint,
                        start: (selectedIndex * tabWidth) + 6,
                        top: 10,
                        bottom: 10,
                        width: pillWidth,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: activeGradient,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: activeShadowColor,
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Row of Interactive Tabs
                      Row(
                        children: List.generate(tabCount, (index) {
                          final tab = taps[index];
                          final isActive = index == selectedIndex;
                          
                          final iconColor = isActive
                              ? Colors.white
                              : (isDark ? Colors.white.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.35));

                          final textColor = isActive
                              ? Colors.white
                              : (isDark ? Colors.white.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.45));

                          return Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: tab.onPressed != null ? () => tab.onPressed!() : null,
                              child: Center(
                                child: AnimatedScale(
                                  scale: isActive ? 1.05 : 0.95,
                                  duration: const Duration(milliseconds: 200),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        tab.icon,
                                        color: iconColor,
                                        size: isActive ? 20 : 22,
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        tab.text,
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: 10,
                                          fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
                                          letterSpacing: -0.2,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
