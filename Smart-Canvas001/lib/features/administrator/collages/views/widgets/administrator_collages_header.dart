import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_canvas/features/administrator/collages/view_models/cubit/colleges_cubit.dart';
import 'package:smart_canvas/features/administrator/collages/views/widgets/search_and_filter.dart';
import 'package:easy_localization/easy_localization.dart';

class AdministratorCollagesHeader extends StatelessWidget {
  const AdministratorCollagesHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16, right: 16, bottom: 16,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1B15) : const Color(0xFF1E8449),
        gradient: LinearGradient(
          colors: isDark 
              ? [const Color(0xFF1E1B15), const Color(0xFF0F0E0A)]
              : [const Color(0xFF1E8449), const Color(0xFF1E8449)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopRow(context, isDark),
          const SizedBox(height: 14),
          SearchAndFilter(
            hintText: "search_college_hint".tr(),
            onChanged: (value) {
              context.read<CollegesCubit>().searchColleges(value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTopRow(BuildContext context, bool isDark) {
    final canPop = Navigator.canPop(context);
    return Row(
      children: [
        if (canPop) ...[
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "colleges_title".tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              BlocBuilder<CollegesCubit, CollegesState>(
                builder: (context, state) {
                  final colleges = context.read<CollegesCubit>().colleges;
                  final count = colleges.length;
                  
                  return Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "$count Colleges",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "•",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "manage_institution".tr(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.school_rounded, color: Colors.white, size: 20),
        ),
      ],
    );
  }
}

