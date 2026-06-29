import 'package:flutter/material.dart';
import 'package:smart_canvas/core/helper/launch_link.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:smart_canvas/core/utilies/styles/app_text_styles.dart';
import 'package:smart_canvas/features/admin/material/models/material_model.dart';

class MaterialCard extends StatelessWidget {
  const MaterialCard({super.key, required this.material});
  final MaterialModel material;

  // دالة للحصول على أيقونة مجردة (غير مباشرة للتمويه)
  IconData _getObscureIcon() {
    final int hash = material.id.hashCode;
    final List<IconData> icons = [
      Icons.article,
      Icons.description,
      Icons.folder_open,
      Icons.library_books,
      Icons.note,
      Icons.sticky_note_2,
    ];
    return icons[hash % icons.length];
  }

  @override
  Widget build(BuildContext context) {
    final String subjectName = material.subjectModel.name;
    final String uploaderName = material.uploadedBy.fullName;  // أو استخدم اختصار إذا أردت تمويه أكثر
    final String createdDate = material.createdAt?.toLocal().toString().split(' ')[0] ?? 'غير محدد';
    final String descSnippet = material.description!.length > 50
        ? '${material.description!.substring(0, 50)}...'
        : material.description ?? 'لا يوجد وصف';

    final Color obscureColor = AppColors.kPrimaryColor.withValues(alpha: 0.7);

    return Container(
      height: SizeConfig.height * 0.22,  // ارتفاع مناسب لعرض البيانات مع التمويه
      margin: EdgeInsets.symmetric(
        horizontal: SizeConfig.width * 0.03,
        vertical: SizeConfig.height * 0.00,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),  // زوايا ناعمة لشكل عام وغامض
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: obscureColor.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: obscureColor.withValues(alpha: 0.15),
          width: 1,
          style: BorderStyle.solid,  // خط خفيف للتمويه
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: EdgeInsets.all(SizeConfig.width * 0.04),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // أيقونة مجردة مع تأثير تمويه (دائرة بلون مجرد)
                  Container(
                    width: SizeConfig.width * 0.16,
                    height: SizeConfig.width * 0.16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: obscureColor.withValues(alpha: 0.1),
                      border: Border.all(
                        color: obscureColor,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: obscureColor.withValues(alpha: 0.2),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Icon(
                      _getObscureIcon(),
                      size: SizeConfig.width * 0.07,
                      color: obscureColor,
                    ),
                  ),
                  SizedBox(width: SizeConfig.width * 0.04),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // العنوان (أهم بيانات) مع تمويه خفيف
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                material.title,
                                style: AppTextStyles.title22WhiteColorBold.copyWith(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  letterSpacing: 0.3,  // مسافة خفيفة للتمويه
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: SizeConfig.width * 0.02),
                            // رمز صغير للتمويه (مثل علامة)
                            Icon(
                              Icons.info_outline,
                              size: SizeConfig.width * 0.045,
                              color: obscureColor.withValues(alpha: 0.5),
                            ),
                          ],
                        ),
                        SizedBox(height: SizeConfig.height * 0.01),
                        // الوصف المختصر (بيانات إضافية)
                        Text(
                          descSnippet,
                          style: AppTextStyles.title14White.copyWith(
                            color: Colors.black54,
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: SizeConfig.height * 0.01),
                        // سطر لاسم الموضوع والمرفع (بيانات أساسية مختصرة مع تمويه)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // اسم الموضوع مختصر
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: SizeConfig.width * 0.025,
                                vertical: SizeConfig.height * 0.008,
                              ),
                              decoration: BoxDecoration(
                                color: obscureColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: obscureColor.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                subjectName.length > 12 ? '${subjectName.substring(0, 12)}...' : subjectName,
                                style: AppTextStyles.title14White.copyWith(
                                  color: obscureColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            // اسم المرفع مختصر (تمويه بالاختصار)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: SizeConfig.width * 0.025,
                                vertical: SizeConfig.height * 0.008,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                uploaderName.length > 10 ? '${uploaderName.substring(0, 10)}...' : uploaderName,
                                style: AppTextStyles.title14White.copyWith(
                                  color: Colors.grey[700],
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // تاريخ مختصر
                            Text(
                              createdDate,
                              style: AppTextStyles.title14White.copyWith(
                                color: Colors.grey[600],
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            // زر الملف المجرد (للتمويه)
                            IconButton(
                              onPressed: () async {
                                await launchUrlSocialMedia(url: material.fileUrl);
                              },
                              icon: Icon(
                                Icons.download_outlined,
                                size: SizeConfig.width * 0.05,
                                color: obscureColor,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'عرض المحتوى',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}