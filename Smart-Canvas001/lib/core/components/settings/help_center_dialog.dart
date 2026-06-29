import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';

class HelpCenterDialog extends StatelessWidget {
  const HelpCenterDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.help_outline, color: AppColors.kPrimaryColor),
          SizedBox(width: 10),
          Text("Help Center"),
        ],
      ),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Need assistance? Contact our support team."),
          SizedBox(height: 20),
          ListTile(
            leading: Icon(Icons.email, color: AppColors.kPrimaryColor),
            title: Text("Email"),
            subtitle: Text("support@smartcampus.com"),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
          ListTile(
            leading: Icon(Icons.phone, color: AppColors.kPrimaryColor),
            title: Text("Phone"),
            subtitle: Text("+20 123 456 7890"),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
          ListTile(
            leading: Icon(FontAwesomeIcons.whatsapp, color: Colors.green),
            title: Text("WhatsApp"),
            subtitle: Text("+20 123 456 7890"),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Close"),
        ),
      ],
    );
  }
}
