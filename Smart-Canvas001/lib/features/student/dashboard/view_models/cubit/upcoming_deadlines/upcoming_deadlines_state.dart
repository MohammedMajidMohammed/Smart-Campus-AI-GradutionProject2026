import 'package:flutter/material.dart';

class DeadlineItem {
  final String id;
  final String title;
  final String subject;
  final DateTime dueDate;
  final DateTime? endDate; // Added to handle visibility after event ends
  final IconData icon;
  final Color color;
  final String type; // 'exam', 'assignment', 'session'

  DeadlineItem({
    required this.id,
    required this.title,
    required this.subject,
    required this.dueDate,
    this.endDate,
    required this.icon,
    required this.color,
    required this.type,
  });
}

@immutable
abstract class UpcomingDeadlinesState {}

class UpcomingDeadlinesInitial extends UpcomingDeadlinesState {}

class UpcomingDeadlinesLoading extends UpcomingDeadlinesState {}

class UpcomingDeadlinesLoaded extends UpcomingDeadlinesState {
  final List<DeadlineItem> deadlines;
  UpcomingDeadlinesLoaded(this.deadlines);
}

class UpcomingDeadlinesError extends UpcomingDeadlinesState {
  final String message;
  UpcomingDeadlinesError(this.message);
}
