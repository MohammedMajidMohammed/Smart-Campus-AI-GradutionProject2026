import 'package:flutter/material.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:smart_canvas/core/utilies/styles/app_text_styles.dart';
import 'package:smart_canvas/features/student/study_chatbot/models/message_model.dart';
import 'package:smart_canvas/features/student/study_chatbot/views/widgets/helper_message.dart';

class ChatMessageBubble extends StatefulWidget {
  final MessageModel message;
  final bool isHelperMessage;
  final bool isRegulations;
  final VoidCallback? onSend;
  final void Function(String faculty, String? department)? onFacultySelected;

  const ChatMessageBubble({
    super.key,
    required this.message,
    this.isHelperMessage = false,
    this.isRegulations = false,
    this.onSend,
    this.onFacultySelected,
  });

  @override
  State<ChatMessageBubble> createState() => _ChatMessageBubbleState();
}

class _ChatMessageBubbleState extends State<ChatMessageBubble> {
  String? _selectedFaculty;

  static const Map<String, List<String>> _facultyDepartments = {
    'كلية الحاسبات والذكاء الاصطناعي': [
      'برنامج ذكاء الآلة (Machine Intelligence)',
      'برنامج علم البيانات (Data Science)',
      'برنامج إنترنت الأشياء وتحليل البيانات الضخمة',
    ],
    'كلية الهندسة': [
      'برنامج هندسة الحاسب (Computer Engineering)',
      'برنامج هندسة المواد وإدارة التصنيع',
      'برنامج التخطيط العمراني وهندسة المدن الذكية',
    ],
    'كلية الصيدلة': [
      'برنامج دكتور صيدلي (Pharm.D)',
      'برنامج الصيدلة الإكلينيكية (Clinical Pharmacy)',
    ],
    'كلية التمريض': [
      'برنامج تمريض القبالة (Midwifery Nursing)',
      'برنامج تمريض حديثي الولادة (Neonatal Nursing)',
      'برنامج تمريض الطوارئ (Emergency Nursing)',
    ],
    'كلية تكنولوجيا العلوم الصحية التطبيقية': [
      'برنامج تكنولوجيا الأشعة والتصوير الطبي',
      'برنامج تكنولوجيا الأجهزة الطبية الحيوية',
      'برنامج تكنولوجيا البصريات (Optical Technology)',
      'برنامج تكنولوجيا الرعاية التنفسية (Respiratory Care)',
      'برنامج تكنولوجيا المختبرات الطبية',
      'برنامج تكنولوجيا صناعة تركيبات الأسنان',
    ],
    'كلية العلوم الإنسانية والاجتماعية': [
      'برنامج اللغة الإنجليزية والترجمة التخصصية',
    ],
    'كلية طب الأسنان': [
      'برنامج طب وجراحة الفم والأسنان (Oral & Dental)',
    ],
    'كلية الطب البشري': [
      'برنامج الطب والجراحة (Medicine & Surgery)',
    ],
    'كلية العلاج الطبيعي': [
      'برنامج العلاج الطبيعي (Physical Therapy)',
    ],
    'كلية الطب البيطري': [
      'برنامج الطب البيطري (Veterinary Medicine)',
    ],
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Align(
      alignment: widget.isHelperMessage
          ? Alignment.center
          : (widget.message.isUser ? Alignment.centerRight : Alignment.centerLeft),
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: SizeConfig.height * 0.008,
          horizontal: SizeConfig.width * 0.02,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              constraints: BoxConstraints(
                maxWidth: widget.isHelperMessage ? SizeConfig.width * 0.88 : SizeConfig.width * 0.75,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.width * 0.045,
                vertical: SizeConfig.height * 0.016,
              ),
              decoration: widget.isHelperMessage
                  ? BoxDecoration(
                      color: isDark ? const Color(0xFF1E1B15) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.06),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    )
                  : BoxDecoration(
                      gradient: widget.message.isUser
                          ? AppColors.studyGradient
                          : null,
                      color: widget.message.isUser
                          ? null
                          : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.7)),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(22),
                        topRight: const Radius.circular(22),
                        bottomLeft: widget.message.isUser ? const Radius.circular(22) : const Radius.circular(4),
                        bottomRight: widget.message.isUser ? const Radius.circular(4) : const Radius.circular(22),
                      ),
                      border: Border.all(
                        color: widget.message.isUser
                            ? Colors.white.withValues(alpha: 0.1)
                            : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.4)),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
              child: widget.isHelperMessage
                  ? HelperMessage(
                      message: widget.message.message!,
                      onSend: widget.onSend,
                      isRegulations: widget.isRegulations,
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.message.message != null && widget.message.message!.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(
                              bottom: SizeConfig.height * 0.01,
                            ),
                            child: _buildParsedMessageText(
                              widget.message.message!,
                              AppTextStyles.title16Black.copyWith(
                                color: widget.message.isUser
                                    ? Colors.white
                                    : (isDark ? Colors.white.withValues(alpha: 0.95) : Colors.black87),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        if (widget.message.image != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              widget.message.image!,
                              width: SizeConfig.width * 0.5,
                              height: SizeConfig.height * 0.25,
                              fit: BoxFit.cover,
                            ),
                          ),
                        if (widget.message.file != null)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: SizeConfig.width * 0.02,
                              vertical: SizeConfig.height * 0.01,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.insert_drive_file,
                                  color: widget.message.isUser
                                      ? Colors.white
                                      : (isDark ? Colors.white70 : Colors.black87),
                                ),
                                SizedBox(width: SizeConfig.width * 0.02),
                                Flexible(
                                  child: Text(
                                    widget.message.file!.path.split('/').last,
                                    style: AppTextStyles.title14Black.copyWith(
                                      color: widget.message.isUser
                                          ? Colors.white
                                          : (isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),
            // ── Faculty / Department chips for CLARIFY messages ──────────────
            if (widget.message.isClarify && widget.message.clarifyFaculties.isNotEmpty && widget.onFacultySelected != null)
              Padding(
                padding: EdgeInsets.only(top: SizeConfig.height * 0.012),
                child: SizedBox(
                  width: SizeConfig.width * 0.8,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _selectedFaculty == null
                        ? Column(
                            key: const ValueKey('faculty_select'),
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "اختر الكلية للبدء:",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: widget.message.clarifyFaculties.map((faculty) {
                                  return GestureDetector(
                                    onTap: () {
                                      if (_facultyDepartments.containsKey(faculty)) {
                                        setState(() {
                                          _selectedFaculty = faculty;
                                        });
                                      } else {
                                        widget.onFacultySelected!(faculty, null);
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        gradient: AppColors.studyGradient,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.kPrimaryColor.withValues(alpha: 0.15),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        faculty,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          )
                        : Column(
                            key: const ValueKey('dept_select'),
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.school,
                                    size: 16,
                                    color: isDark ? Colors.white70 : AppColors.kPrimaryColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      "الكلية: $_selectedFaculty",
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : AppColors.kPrimaryColor,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _selectedFaculty = null;
                                      });
                                    },
                                    icon: const Icon(Icons.edit, size: 14),
                                    label: const Text(
                                      "تغيير",
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 16, thickness: 0.5),
                              Text(
                                "الآن اختر القسم أو التخصص:",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  ...(_facultyDepartments[_selectedFaculty] ?? []).map((dept) {
                                    return GestureDetector(
                                      onTap: () {
                                        widget.onFacultySelected!(_selectedFaculty!, dept);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        decoration: BoxDecoration(
                                          gradient: AppColors.studyGradient,
                                          borderRadius: BorderRadius.circular(20),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.kPrimaryColor.withValues(alpha: 0.15),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          dept,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                  GestureDetector(
                                    onTap: () {
                                      widget.onFacultySelected!(_selectedFaculty!, null);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: isDark ? Colors.white24 : Colors.grey.shade400,
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Text(
                                        "تخطي / اللائحة العامة",
                                        style: TextStyle(
                                          color: isDark ? Colors.white70 : Colors.black87,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildParsedMessageText(String text, TextStyle baseStyle) {
    final List<TextSpan> spans = [];
    final RegExp regex = RegExp(r'\*\*(.*?)\*\*');
    int start = 0;
    
    for (final Match match in regex.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ));
      start = match.end;
    }
    
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }
    
    final isArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(text);
    
    return Text.rich(
      TextSpan(children: spans),
      style: baseStyle,
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
    );
  }
}

