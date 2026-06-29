import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:line_icons/line_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smart_canvas/features/admin/material/models/material_model.dart';
import 'package:smart_canvas/features/admin/material/view_models/cubit/materials_cubit.dart';
import 'package:url_launcher/url_launcher.dart';

class DoctorMaterialsListView extends StatelessWidget {
  const DoctorMaterialsListView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: BlocBuilder<MaterialsCubit, MaterialsState>(
        builder: (context, state) {
          if (state is GetMaterialsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final cubit = context.read<MaterialsCubit>();
          final materials = cubit.materials;
          final selectedFolder = cubit.selectedFolder;

          if (materials.isEmpty) {
            return _buildEmptyState(isDark);
          }

          // Group all materials into folders
          final Map<String, List<MaterialModel>> groupedMaterials = {};
          for (var material in materials) {
            final folder = material.folderName ?? "General";
            groupedMaterials.putIfAbsent(folder, () => []).add(material);
          }

          if (selectedFolder == null) {
            // Show Folders View
            final folderNames = groupedMaterials.keys.toList();
            return RefreshIndicator(
              onRefresh: () async => cubit.refresh(),
              child: GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                ),
                itemCount: folderNames.length,
                itemBuilder: (context, index) {
                  final name = folderNames[index];
                  final items = groupedMaterials[name]!;
                  return _FolderCard(
                    name: name,
                    count: items.length,
                    isDark: isDark,
                    onTap: () => cubit.selectFolder(name),
                  ).animate().fadeIn(delay: (50 * index).ms).scale();
                },
              ),
            );
          }

          // Show Files inside selected folder
          final folderItems = groupedMaterials[selectedFolder] ?? [];

          return Column(
            children: [
              _buildFolderNavigationHeader(selectedFolder, isDark, context),
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  itemCount: folderItems.length,
                  itemBuilder: (context, index) {
                    final item = folderItems[index];
                    return _MaterialCard(item: item, isDark: isDark)
                        .animate()
                        .fadeIn(delay: (50 * index).ms)
                        .slideX(begin: 0.05);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LineIcons.folderOpen, size: 100, color: Colors.grey.withValues(alpha: 0.15)),
          const SizedBox(height: 24),
          Text(
            "No resources found",
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.grey.shade400,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Start by adding your first lecture",
            style: TextStyle(
              color: isDark ? Colors.white24 : Colors.grey.shade300,
              fontSize: 13,
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildFolderNavigationHeader(String folderName, bool isDark, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.read<MaterialsCubit>().selectFolder(null),
            icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: isDark ? Colors.white54 : Colors.grey),
          ),
          const SizedBox(width: 4),
          Text(
            folderName,
            style: TextStyle(
              fontSize: 22, 
              fontWeight: FontWeight.w900, 
              color: isDark ? Colors.white : const Color(0xFF1E1B15),
              letterSpacing: -0.8,
            ),
          ),
          const Spacer(),
          Text(
            "Contents",
            style: TextStyle(color: isDark ? Colors.white24 : Colors.grey.shade400, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _FolderCard extends StatelessWidget {
  final String name;
  final int count;
  final bool isDark;
  final VoidCallback onTap;

  const _FolderCard({required this.name, required this.count, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1B15) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.04),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.08),
            width: 1.5,
          ),
        ),
        child: Stack(
          children: [
            // Decorative background circle
            Positioned(
              right: -20,
              bottom: -20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF2ECC71).withValues(alpha: isDark ? 0.02 : 0.03),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2ECC71), Color(0xFF1E8449)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2ECC71).withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(LineIcons.folderOpen, color: Colors.white, size: 28),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: isDark ? Colors.white24 : Colors.black26,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.w900, 
                    color: isDark ? Colors.white : const Color(0xFF1E1B15),
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1, 
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2ECC71).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "$count Items",
                    style: const TextStyle(
                      color: Color(0xFF1E8449),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MaterialCard extends StatelessWidget {
  final MaterialModel item;
  final bool isDark;

  const _MaterialCard({required this.item, required this.isDark});

  Future<void> _handleDownload() async {
    final Uri url = Uri.parse(item.fileUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch ${item.fileUrl}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = item.materialType == "Lecture" ? const Color(0xFF2ECC71) : Colors.amber.shade700;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1B15) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _handleDownload, // Added download functionality
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildFileIcon(statusColor),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w900, 
                            fontSize: 15, 
                            color: isDark ? Colors.white : const Color(0xFF1E1B15),
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _typeBadge(item.materialType, statusColor),
                            const SizedBox(width: 8),
                            Text(
                              item.subjectModel.name,
                              style: TextStyle(
                                color: isDark ? Colors.white38 : Colors.grey.shade500, 
                                fontSize: 11, 
                                fontWeight: FontWeight.w600
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _buildActionIcon(isDark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFileIcon(Color color) {
    return Container(
      width: 52, height: 52,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(
        item.isLink ? LineIcons.link : LineIcons.fileAlt, 
        color: color, 
        size: 26
      ),
    );
  }

  Widget _typeBadge(String type, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        type.toUpperCase(),
        style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildActionIcon(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.shade50,
        shape: BoxShape.circle,
      ),
      child: Icon(
        item.isLink ? LineIcons.link : LineIcons.download, 
        color: isDark ? Colors.white38 : Colors.grey.shade400, 
        size: 20
      ),
    );
  }
}