import 'package:flutter/material.dart';

class AdministratorActionModel {
  final String title;
  final String image;
  final String route;
  final IconData? icon;

  AdministratorActionModel({
    required this.title,
    required this.image,
    required this.route,
    this.icon,
  });
}
