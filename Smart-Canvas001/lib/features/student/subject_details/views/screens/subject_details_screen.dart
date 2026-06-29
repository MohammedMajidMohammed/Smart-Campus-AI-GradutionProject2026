import 'package:flutter/material.dart';
import 'package:smart_canvas/core/app_route/route_names.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_canvas/core/di/dependancy_injection.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:smart_canvas/features/admin/material/models/material_model.dart';
import 'package:smart_canvas/features/admin/subjects/models/subject_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:line_icons/line_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:developer';

class SubjectDetailsCubit extends Cubit<SubjectDetailsState> {
  SubjectDetailsCubit() : super(SubjectDetailsInitial());

  List<MaterialModel> materials = [];
  final supabase = getIt<SupabaseClient>();

  Future<void> getMaterials(String subjectId) async {
    try {
      emit(SubjectDetailsLoading());
      final res = await supabase.rpc(
        'get_materials_by_subject',
        params: {'p_subject_id': subjectId},
      );
      final List materialList = res as List;
      materials = materialList.map((e) => MaterialModel.fromJson(e)).toList();
      emit(SubjectDetailsSuccess());
    } catch (e) {
      log(e.toString());
      emit(SubjectDetailsFailure(message: e.toString()));
    }
  }
}

abstract class SubjectDetailsState {}
class SubjectDetailsInitial extends SubjectDetailsState {}
class SubjectDetailsLoading extends SubjectDetailsState {}
class SubjectDetailsSuccess extends SubjectDetailsState {}
class SubjectDetailsFailure extends SubjectDetailsState {
  final String message;
  SubjectDetailsFailure({required this.message});
}

class SubjectDetailsScreen extends StatelessWidget {
  const SubjectDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final subjectModel = SubjectModel.fromJson(args);
    final subjectId = subjectModel.id;

    return BlocProvider(
      create: (_) => SubjectDetailsCubit()..getMaterials(subjectId),
      child: _SubjectDetailsView(subjectModel: subjectModel),
    );
  }
}

class _SubjectDetailsView extends StatelessWidget {
  final SubjectModel subjectModel;
  const _SubjectDetailsView({required this.subjectModel});

  Color _getSubjectColor() {
    final int hash = subjectModel.id.hashCode.abs() % 6;
    final List<Color> colors = [
      AppColors.kPrimaryColor,
      AppColors.kSecondaryColor,
      const Color(0xFF3F51B5),
      const Color(0xFF009688),
      const Color(0xFFE91E63),
      const Color(0xFF9C27B0),
    ];
    return colors[hash];
  }

  IconData _getSubjectIcon() {
    final name = subjectModel.name.toLowerCase();
    if (name.contains('math')) return Icons.calculate_rounded;
    if (name.contains('comput') || name.contains('tech') || name.contains('internet')) return Icons.terminal_rounded;
    if (name.contains('market') || name.contains('busin')) return Icons.trending_up_rounded;
    if (name.contains('design') || name.contains('art')) return Icons.palette_rounded;
    if (name.contains('science')) return Icons.science_rounded;
    return Icons.menu_book_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subjectColor = _getSubjectColor();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0E0A) : const Color(0xFFFAF9F5),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(context, isDark, subjectColor),
          _buildStatsBar(isDark, subjectColor),
          _buildMaterialsList(isDark, subjectColor),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      bottomNavigationBar: _buildBottomActions(context, isDark, subjectColor),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, bool isDark, Color subjectColor) {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      elevation: 0,
      stretch: true,
      backgroundColor: isDark ? const Color(0xFF1E1B15) : subjectColor,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF1E1B15), const Color(0xFF0F0E0A)]
                  : [subjectColor, _darken(subjectColor, 0.25)],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                right: -60, top: -60,
                child: Container(
                  width: 200, height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
              ),
              Positioned(
                left: -30, bottom: -30,
                child: Container(
                  width: 140, height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.03),
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 2),
                      ),
                      child: Icon(_getSubjectIcon(), size: 40, color: Colors.white),
                    ).animate().scale(delay: 200.ms, curve: Curves.elasticOut),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        subjectModel.name,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          shadows: [Shadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 10)],
                        ),
                      ),
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
                    if (subjectModel.code != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          subjectModel.code!.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsBar(bool isDark, Color subjectColor) {
    return SliverToBoxAdapter(
      child: BlocBuilder<SubjectDetailsCubit, SubjectDetailsState>(
        builder: (context, state) {
          final materials = context.read<SubjectDetailsCubit>().materials;
          final lectures = materials.where((m) => m.materialType == "Lecture").length;
          final labs = materials.where((m) => m.materialType != "Lecture").length;

          return Container(
            margin: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1B15) : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade100,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                _StatItem(
                  icon: Icons.play_lesson_rounded,
                  label: "Lectures",
                  value: "$lectures",
                  color: subjectColor,
                  isDark: isDark,
                ),
                _divider(isDark),
                _StatItem(
                  icon: Icons.science_rounded,
                  label: "Labs & Others",
                  value: "$labs",
                  color: AppColors.kSecondaryColor,
                  isDark: isDark,
                ),
                _divider(isDark),
                _StatItem(
                  icon: Icons.folder_rounded,
                  label: "Total",
                  value: "${materials.length}",
                  color: const Color(0xFF3F51B5),
                  isDark: isDark,
                ),
              ],
            ),
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1);
        },
      ),
    );
  }

  Widget _divider(bool isDark) {
    return Container(
      width: 1,
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
    );
  }

  Widget _buildMaterialsList(bool isDark, Color subjectColor) {
    return BlocBuilder<SubjectDetailsCubit, SubjectDetailsState>(
      builder: (context, state) {
        if (state is SubjectDetailsLoading) {
          return SliverFillRemaining(
            child: Center(child: CircularProgressIndicator(color: subjectColor)),
          );
        }

        final materials = context.read<SubjectDetailsCubit>().materials;
        if (materials.isEmpty) {
          return SliverFillRemaining(child: _buildEmptyState(isDark));
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        Text(
                          "Materials",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : const Color(0xFF0F0E0A),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.sort_rounded, size: 18, color: isDark ? Colors.white24 : Colors.grey.shade300),
                      ],
                    ),
                  );
                }
                final material = materials[index - 1];
                return _MaterialCard(material: material, isDark: isDark, subjectColor: subjectColor)
                    .animate()
                    .fadeIn(delay: (80 * index).ms)
                    .slideX(begin: 0.08);
              },
              childCount: materials.length + 1,
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(LineIcons.folderOpen, size: 80, color: Colors.grey.withValues(alpha: 0.15)),
        const SizedBox(height: 20),
        Text(
          'no_materials_yet'.tr(),
          style: TextStyle(
            color: isDark ? Colors.white38 : Colors.grey.shade400,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions(BuildContext context, bool isDark, Color subjectColor) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(context).padding.bottom + 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1B15) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white54 : Colors.grey.shade500, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'back_to_subjects'.tr(),
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.grey.shade500,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  RouteNames.subjectChatScreen,
                  arguments: {
                    'subjectId': subjectModel.id,
                    'subjectName': subjectModel.name,
                  },
                );
              },
              borderRadius: BorderRadius.circular(18),
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [subjectColor, _darken(subjectColor, 0.15)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: subjectColor.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LineIcons.comments, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      "Subject Chat",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _darken(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F0E0A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white30 : Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}

class _MaterialCard extends StatelessWidget {
  final MaterialModel material;
  final bool isDark;
  final Color subjectColor;

  const _MaterialCard({
    required this.material,
    required this.isDark,
    required this.subjectColor,
  });

  Future<void> _handleDownload() async {
    final Uri url = Uri.parse(material.fileUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch ${material.fileUrl}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLecture = material.materialType == "Lecture";
    final color = isLecture ? subjectColor : AppColors.kSecondaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1B15) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade100,
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _handleDownload,
            child: Column(
              children: [
                // Content
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                  child: Row(
                    children: [
                      Container(
                        width: 50, height: 50,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          material.isLink ? LineIcons.link : (isLecture ? LineIcons.fileAlt : LineIcons.flask),
                          color: color,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              material.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                color: isDark ? Colors.white : const Color(0xFF0F0E0A),
                                letterSpacing: -0.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                material.materialType.toUpperCase(),
                                style: TextStyle(
                                  color: color,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Bottom bar
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 12, 14, 12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.02) : const Color(0xFFFAFBFC),
                    border: Border(
                      top: BorderSide(
                        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade100,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.schedule_rounded, size: 13, color: isDark ? Colors.white24 : Colors.grey.shade300),
                      const SizedBox(width: 6),
                      Text(
                        material.createdAt?.toLocal().toString().split(' ')[0] ?? 'N/A',
                        style: TextStyle(
                          color: isDark ? Colors.white24 : Colors.grey.shade400,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      // Download button
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.85)]),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LineIcons.download, color: Colors.white, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              material.isLink ? "OPEN" : "GET FILE",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
