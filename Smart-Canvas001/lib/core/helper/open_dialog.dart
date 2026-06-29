import 'package:flutter/material.dart';

Future openDialog({
  required BuildContext context,
  required Widget widget,
  bool isDismissable = true,
}) async {
  return await showGeneralDialog(
    barrierLabel: 'Dialog',
    barrierDismissible: isDismissable,
    context: context,
    pageBuilder: (ctx, anim1, anim2) => widget,
    transitionBuilder: (ctx, anim1, anim2, child) => ScaleTransition(
      scale: anim1,
      child: child,
    ),
  );
}
