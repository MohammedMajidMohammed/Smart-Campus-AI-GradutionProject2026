import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:smart_canvas/features/administrator/collages/models/academic_year_model.dart';
import 'package:smart_canvas/features/administrator/collages/models/collage_model.dart';
import 'package:smart_canvas/features/administrator/collages/views/widgets/administrator_collages_list_view.dart';
import 'package:smart_canvas/features/administrator/collages/views/widgets/custom_failure_message.dart';
import 'package:smart_canvas/features/admin/subjects/models/subject_model.dart';
import 'package:smart_canvas/features/admin/subjects/view_models/cubit/subjects_cubit.dart';
import 'package:smart_canvas/features/admin/subjects/views/widgets/subject_card.dart';

class DoctorSubjectsListView extends StatelessWidget {
  const DoctorSubjectsListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: BlocBuilder<SubjectsCubit, SubjectsState>(
        builder: (context, state) {
          if (state is GetSubjectsLoading) {
            return const CustomLoadingIndecator();  // تأكد من إن ده موجود، أو غيره بـ CircularProgressIndicator()
          }
          if (state is GetSubjectsFailure) {
            return CustomFailureMesage(errorMessage: state.message);
          }
          var subjects = context.read<SubjectsCubit>().filteredSubjects;
          return RefreshIndicator(
            onRefresh: () async => context.read<SubjectsCubit>().getSubjects(),
            backgroundColor: AppColors.kPrimaryColor,
            color: Colors.white,
            child: ListView.builder(
              padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.width * 0.025,
                vertical: SizeConfig.height * 0.015,
              ),
              itemCount: subjects.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      context: context,
                      builder: (context) {
                        return SubjectDetailsBottomSheetBody(
                          subject: subjects[index],  // غيرت من room إلى subject
                        );
                      },
                    );
                  },
                  child: SubjectCard(
                    key: Key(subjects[index].id.toString()),
                    subject: subjects[index],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class SubjectDetailsBottomSheetBody extends StatelessWidget {
  const SubjectDetailsBottomSheetBody({super.key, required this.subject});  // غيرت من room إلى subject
  final SubjectModel subject;

  // دالة للحصول على لون النوع (افتراضي للـ subject، ممكن تخصيص حسب الكلية لاحقاً)
  Color _getTypeColor() {
    return AppColors.kPrimaryColor;  // أو حسب abbreviation الكلية، مثلاً
  }

  // دالة للحصول على أيقونة النوع (للـ subject عامة)
  IconData _getTypeIcon() {
    return Icons.book;  // أيقونة كتاب للـ subjects
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 25,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Stack(
            children: [
              SingleChildScrollView(
                controller: scrollController,
                padding: EdgeInsets.fromLTRB(
                  SizeConfig.width * 0.04,
                  SizeConfig.height * 0.05,
                  SizeConfig.width * 0.04,
                  SizeConfig.height * 0.02,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar with primary accent
                    Center(
                      child: Container(
                        margin: EdgeInsets.symmetric(
                          vertical: SizeConfig.height * 0.01,
                        ),
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppColors.kPrimaryColor.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    // Subject Image/Placeholder (استخدم صورة الكلية)
                    Center(
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(25),
                            child: Container(
                              width: double.infinity,
                              height: SizeConfig.height * 0.28,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: AppColors.kPrimaryColor.withValues(alpha: 0.3),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.kPrimaryColor.withValues(alpha: 0.2),
                                    blurRadius: 15,
                                    offset: const Offset(5, 10),
                                  ),
                                ],
                                image: subject.college?.image != null
                                    ? DecorationImage(
                                        image: NetworkImage(subject.college!.image),
                                        fit: BoxFit.cover,
                                      )
                                    : null,  // لو مفيش صورة، هيبقى فارغ أو أضف placeholder
                              ),
                              child: subject.college?.image == null
                                  ? Center(
                                      child: Icon(
                                        _getTypeIcon(),
                                        size: 80,
                                        color: _getTypeColor().withValues(alpha: 0.3),
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          // Subject type badge with primary color
                          Positioned(
                            bottom: 10,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.kPrimaryColor,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getTypeIcon(),
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 2),
                                  const Text(
                                    'SUBJECT',  // أو حسب نوع الـ subject لو عندك enum
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: SizeConfig.height * 0.025),
                    // Subject Name with primary accent
                    Center(
                      child: Column(
                        children: [
                          Text(
                            subject.name,  // اسم الـ subject
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: SizeConfig.width * 0.065,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: SizeConfig.height * 0.035),
                    // College Section Widget
                    _CollegeSection(college: subject.college),
                    SizedBox(height: SizeConfig.height * 0.02),
                    // Academic Year Section Widget
                    _AcademicYearSection(academicYear: subject.academicYearModel),
                    SizedBox(height: SizeConfig.height * 0.02),
                    // Created At Section Widget
                    _CreatedAtSection(
                      createdAt: subject.createdAt ?? DateTime.now(),
                    ),
                    SizedBox(height: SizeConfig.height * 0.06),
                  ],
                ),
              ),
              // Close Button with primary color
              Positioned(
                top: SizeConfig.height * 0.015,
                right: SizeConfig.width * 0.04,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.kPrimaryColor.withValues(alpha: 0.5),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.kPrimaryColor.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.close,
                      color: AppColors.kPrimaryColor,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Widget for College Section
class _CollegeSection extends StatelessWidget {
  const _CollegeSection({required this.college});
  final CollegeModel? college;

  @override
  Widget build(BuildContext context) {
    if (college == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'College'),
        SizedBox(height: SizeConfig.height * 0.015),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(SizeConfig.width * 0.035),
          decoration: BoxDecoration(
            color: AppColors.kPrimaryColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.kPrimaryColor.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: AppColors.kPrimaryColor.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.kPrimaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.school, color: Colors.white, size: 20),
              ),
              SizedBox(width: SizeConfig.width * 0.03),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      college!.name,
                      style: TextStyle(
                        fontSize: SizeConfig.width * 0.045,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (college!.abbreviation.isNotEmpty)
                      Text(
                        college!.abbreviation,
                        style: TextStyle(
                          fontSize: SizeConfig.width * 0.035,
                          color: AppColors.kPrimaryColor.withValues(alpha: 0.7),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Widget for Academic Year Section
class _AcademicYearSection extends StatelessWidget {
  const _AcademicYearSection({required this.academicYear});
  final AcademicYearModel? academicYear;

  @override
  Widget build(BuildContext context) {
    if (academicYear == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Academic Year'),
        SizedBox(height: SizeConfig.height * 0.015),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(SizeConfig.width * 0.035),
          decoration: BoxDecoration(
            color: AppColors.kPrimaryColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.kPrimaryColor.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: AppColors.kPrimaryColor.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.kPrimaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.school, color: Colors.white, size: 20),
              ),
              SizedBox(width: SizeConfig.width * 0.03),
              Expanded(
                child: Text(
                  academicYear!.name,
                  style: TextStyle(
                    fontSize: SizeConfig.width * 0.045,
                    color: AppColors.kPrimaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Widget for Created At Section (unchanged)
class _CreatedAtSection extends StatelessWidget {
  const _CreatedAtSection({required this.createdAt});
  final DateTime createdAt;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Created At'),
        SizedBox(height: SizeConfig.height * 0.015),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(SizeConfig.width * 0.04),
          decoration: BoxDecoration(
            color: AppColors.kPrimaryColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.kPrimaryColor.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: AppColors.kPrimaryColor.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: AppColors.kPrimaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.calendar_today,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              SizedBox(width: SizeConfig.width * 0.03),
              Expanded(
                child: Text(
                  'Created on: ${createdAt.toLocal().toString().split(' ')[0]}',
                  style: TextStyle(
                    fontSize: SizeConfig.width * 0.045,
                    color: AppColors.kPrimaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Widget for Section Title (unchanged)
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 5,
          height: SizeConfig.height * 0.03,
          decoration: BoxDecoration(
            color: AppColors.kPrimaryColor,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        SizedBox(width: SizeConfig.width * 0.025),
        Text(
          title,
          style: TextStyle(
            fontSize: SizeConfig.width * 0.055,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}