import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:flutter/material.dart';

class CustomTextFormField extends StatelessWidget {
  const CustomTextFormField({
    super.key,
    this.hintText,
    this.lable,
    this.controller,
    this.prefixIcon,
    this.suffixIcon,
    this.maxline = 1,
    this.fillColor,
    this.onChanged,
    this.hintStyle,
    this.onTap,
    this.enable = true,
    this.keyboardType,
    this.style,
  });
  final int maxline;
  final String? hintText;
  final String? lable;
  final TextEditingController? controller;
  final Widget? suffixIcon, prefixIcon;
  final Color? fillColor;
  final Function(String)? onChanged;
  final Function()? onTap;
  final bool enable;
  final TextStyle? hintStyle;
  final TextStyle? style;
  final TextInputType? keyboardType;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (lable != null) ...[
          Text(lable!, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          SizedBox(height: SizeConfig.height * 0.008),
        ],
        TextFormField(
          keyboardType: keyboardType,
          style: style ?? Theme.of(context).textTheme.bodyLarge,
          onChanged: onChanged,
          controller: controller,
          onTap: onTap,
          enabled: enable,
          maxLines: maxline,
          decoration: InputDecoration(
            // Label is handled above for better control, or inside decoration if preferred. 
            // We'll keep it consistent with the new design: Label above input.
            // label: lable != null ? Text(lable!) : null, 
            
            fillColor: fillColor ?? (isDark ? const Color(0xFF1E1B15) : Colors.white),
            filled: true,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            hintText: hintText,
            hintStyle: hintStyle ?? Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            contentPadding: EdgeInsets.symmetric(
              horizontal: SizeConfig.width * 0.04,
              vertical: SizeConfig.height * 0.018,
            ),
            border: _buildBorder(context),
            enabledBorder: _buildBorder(context),
            focusedBorder: _buildFocusedBorder(context),
            errorBorder: _buildErrorBorder(context),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _buildBorder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade300,
        width: 1,
      ),
    );
  }

  OutlineInputBorder _buildFocusedBorder(BuildContext context) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: Theme.of(context).primaryColor,
        width: 2,
      ),
    );
  }

  OutlineInputBorder _buildErrorBorder(BuildContext context) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: Theme.of(context).colorScheme.error,
        width: 1,
      ),
    );
  }
}
