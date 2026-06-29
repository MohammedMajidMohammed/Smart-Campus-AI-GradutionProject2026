import 'package:flutter/material.dart';

class GButtonModel {
  final int index;
  final String title;
  final IconData icon;
  final Function? onPressed;

  GButtonModel({
    required this.title,
    required this.icon,
    this.onPressed,
    required this.index,
  });

  factory GButtonModel.fromJson(Map<String, dynamic> json) {
    return GButtonModel(
      title: json['title'],
      icon: json['icon'],
      index: json['index'],
    );
  }

  toJson() => {'title': title, 'icon': icon, 'index': index};
}
