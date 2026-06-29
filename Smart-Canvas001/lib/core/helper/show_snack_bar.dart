import 'package:smart_canvas/app/my_app.dart';
import 'package:flutter/material.dart';

showSnackBar({required String title}) {
  ScaffoldMessenger.of(navigatorKey.currentState!.context).showSnackBar(
    SnackBar(
      content: Text(title),
    ),
  );
}
