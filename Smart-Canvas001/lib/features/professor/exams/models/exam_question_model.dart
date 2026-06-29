class ExamQuestionModel {
  final String id;
  final String examId;
  final String questionType; // 'mcq' or 'essay'
  final String questionText;
  final List<String>? options; // MCQ options
  final String correctAnswer;
  final int points;
  final int sortOrder;

  ExamQuestionModel({
    required this.id,
    required this.examId,
    required this.questionType,
    required this.questionText,
    this.options,
    required this.correctAnswer,
    this.points = 1,
    this.sortOrder = 0,
  });

  bool get isMcq => questionType == 'mcq';
  bool get isEssay => questionType == 'essay';

  factory ExamQuestionModel.fromJson(Map<String, dynamic> json) {
    List<String>? opts;
    if (json['options'] != null) {
      if (json['options'] is List) {
        opts = (json['options'] as List).map((e) => e.toString()).toList();
      }
    }

    return ExamQuestionModel(
      id: json['id']?.toString() ?? '',
      examId: json['exam_id']?.toString() ?? '',
      questionType: json['question_type']?.toString() ?? 'mcq',
      questionText: json['question_text']?.toString() ?? '',
      options: opts,
      correctAnswer: json['correct_answer']?.toString() ?? '',
      points: json['points'] as int? ?? 1,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'exam_id': examId,
        'question_type': questionType,
        'question_text': questionText,
        'options': options,
        'correct_answer': correctAnswer,
        'points': points,
        'sort_order': sortOrder,
      };

  /// Grade a student's answer
  double gradeAnswer(String studentAnswer) {
    if (isMcq) {
      return studentAnswer.trim().toLowerCase() == correctAnswer.trim().toLowerCase()
          ? points.toDouble()
          : 0.0;
    } else {
      // Essay: keyword matching (case-insensitive)
      final keywords = correctAnswer
          .split(',')
          .map((k) => k.trim().toLowerCase())
          .where((k) => k.isNotEmpty)
          .toList();
      if (keywords.isEmpty) return 0;

      final answer = studentAnswer.toLowerCase();
      int matched = 0;
      for (final keyword in keywords) {
        if (answer.contains(keyword)) matched++;
      }
      final ratio = matched / keywords.length;
      return (ratio * points).roundToDouble();
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExamQuestionModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
