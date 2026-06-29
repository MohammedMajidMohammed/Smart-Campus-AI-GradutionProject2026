import 'package:flutter/material.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:smart_canvas/core/utilies/styles/app_text_styles.dart';

class CustomFailureMesage extends StatelessWidget {
  const CustomFailureMesage({
    super.key,
    required this.errorMessage,
  });
  final String errorMessage; 
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: SizeConfig.width * 0.1),
          SizedBox(height: SizeConfig.height * 0.02),
          Text( 
            errorMessage,
            style: AppTextStyles.title20PrimaryColorBold,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

