import 'package:flutter/material.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:smart_canvas/core/utilies/styles/app_text_styles.dart';
import 'package:smart_canvas/features/admin/subjects/models/subject_model.dart';

class SubjectCard extends StatelessWidget {
  const SubjectCard({super.key, required this.subject});
  final SubjectModel subject;


  // دالة للحصول على أيقونة مجردة (غير مباشرة للتمويه)
  IconData _getObscureIcon() {
    final int hash = subject.id.hashCode;
    final List<IconData> icons = [
      Icons.category,
      Icons.folder,
      Icons.bookmark,
      Icons.star,
      Icons.lightbulb,
      Icons.pie_chart,
    ];
    return icons[hash % icons.length];
  }

  @override
  Widget build(BuildContext context) {
    final String collegeAbbrev = subject.college?.abbreviation ?? 'N/A';
    final String academicYear = subject.academicYearModel?.name ?? 'غير محدد';
    final String createdDate = subject.createdAt?.toLocal().toString().split(' ')[0] ?? 'غير محدد';

    final Color obscureColor = AppColors.kPrimaryColor.withValues(alpha: 0.7);

    return Container(
      height: SizeConfig.h(18),  // ارتفاع مناسب للبيانات الأساسية
      margin: EdgeInsets.symmetric(
        horizontal: SizeConfig.w(3),
        vertical: SizeConfig.h(1),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),  // زوايا ناعمة لشكل غامض
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: obscureColor.withValues(alpha: 0.1),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: obscureColor.withValues(alpha: 0.2),
          width: 1.5,
          style: BorderStyle.solid,  // خط رفيع للتمويه
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: EdgeInsets.all(SizeConfig.w(4)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // أيقونة مجردة مع تأثير تمويه (دائرة بلون عشوائي)
              Container(
                width: SizeConfig.w(18),
                height: SizeConfig.w(18),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: obscureColor.withValues(alpha: 0.1),
                  border: Border.all(
                    color: obscureColor,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: obscureColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  _getObscureIcon(),
                  size: SizeConfig.w(8),
                  color: obscureColor,
                ),
              ),
              SizedBox(width: SizeConfig.w(4)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // الاسم الرئيسي (أهم بيانات) مع تمويه خفيف
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            subject.name,
                            style: AppTextStyles.title22WhiteColorBold.copyWith(
                              color: Colors.black87,
                              fontWeight: FontWeight.w700,
                              fontSize: SizeConfig.fontSize(16),  // حجم مناسب
                              letterSpacing: 0.5,  // مسافة للتمويه
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: SizeConfig.w(2)),
                        // رمز صغير للتمويه (مثل نجمة)
                        Icon(
                          Icons.star_border,
                          size: SizeConfig.w(4),
                          color: obscureColor.withValues(alpha: 0.6),
                        ),
                      ],
                    ),
                    SizedBox(height: SizeConfig.h(0.8)),
                    // سطر لاختصار الكلية والسنة الدراسية (بيانات أساسية مختصرة)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // اختصار الكلية
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: SizeConfig.w(2.5),
                            vertical: SizeConfig.h(0.8),
                          ),
                          decoration: BoxDecoration(
                            color: obscureColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: obscureColor.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            collegeAbbrev,
                            style: AppTextStyles.title12White70.copyWith(
                              color: obscureColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        // السنة الدراسية مختصرة
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: SizeConfig.w(2.5),
                            vertical: SizeConfig.h(0.8),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            academicYear.substring(0, academicYear.length > 10 ? 10 : academicYear.length) + (academicYear.length > 10 ? '...' : ''),
                            style: AppTextStyles.title14White.copyWith(
                              color: Colors.grey[700],
                              fontSize: SizeConfig.fontSize(11),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: SizeConfig.h(0.8)),
                    // تاريخ الإنشاء (بيانات إضافية مختصرة)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // تاريخ مختصر
                        Text(
                          createdDate,
                          style: AppTextStyles.title14White.copyWith(
                            color: Colors.grey[600],
                            fontSize: SizeConfig.fontSize(12),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        // رمز إضافي للتمويه
                        Icon(
                          Icons.access_time,
                          size: SizeConfig.w(4),
                          color: Colors.grey[400],
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
    );
  }
}