import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:smart_canvas/core/utilies/extensions/app_extensions.dart';
import 'package:smart_canvas/core/utilies/styles/app_text_styles.dart';
import 'package:flutter/material.dart';

class CustomTextFormFieldWithTitle extends StatefulWidget {
  const CustomTextFormFieldWithTitle({
    super.key,
    this.onChanged,
    this.enable = true,
    required this.hintText,
    this.title,
    this.isPassword = false,
    this.controller,
    this.enableValidator = true,
    this.maxLines = 1,
    this.prefixIcon,
    this.keyboardType,
  });
  final String hintText;
  final String? title;
  final TextInputType? keyboardType;
  final bool isPassword, enableValidator;
  final TextEditingController? controller;
  final int maxLines;
  final bool? enable;
  final IconData? prefixIcon;
  final Function(String)? onChanged;
  @override
  State<CustomTextFormFieldWithTitle> createState() =>
      _CustomTextFormFieldWithTitleState();
}

class _CustomTextFormFieldWithTitleState
    extends State<CustomTextFormFieldWithTitle> {
  bool isPassword = true;
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title != null) ...[
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: AppTextStyles.title18BlackW600.copyWith(
              color: _isFocused
                  ? AppColors.kPrimaryColor
                  : (isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87),
              fontSize: 15,
            ),
            child: Text(widget.title!),
          ),
          const SizedBox(height: 8),
        ],
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _isFocused
                    ? AppColors.kPrimaryColor.withValues(alpha: isDark ? 0.15 : 0.08)
                    : Colors.transparent,
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            focusNode: _focusNode,
            style: AppTextStyles.title18Black.copyWith(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 16,
            ),
            enabled: widget.enable,
            cursorColor: AppColors.kPrimaryColor,
            controller: widget.controller,
            onChanged: widget.onChanged,
            validator: widget.enableValidator
                ? (value) =>
                      value!.isEmpty ? "Field ${widget.title ?? ''} is required" : null
                : null,
            obscureText: widget.isPassword ? isPassword : false,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            keyboardType: widget.keyboardType,
            decoration: InputDecoration(
              hintText: widget.hintText,
              filled: true,
              fillColor: isDark
                  ? (_isFocused ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.03))
                  : (_isFocused ? Colors.white : Colors.grey.shade50.withValues(alpha: 0.8)),
              contentPadding: EdgeInsets.symmetric(
                horizontal: context.screenWidth * 0.04,
                vertical: context.screenHeight * 0.016,
              ),
              prefixIcon: widget.prefixIcon == null
                  ? null
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: AnimatedScale(
                        scale: _isFocused ? 1.08 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutBack,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _isFocused
                                ? AppColors.kPrimaryColor.withValues(alpha: 0.15)
                                : AppColors.kPrimaryColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            widget.prefixIcon,
                            color: AppColors.kPrimaryColor,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 40,
              ),
              hintStyle: AppTextStyles.title14Grey.copyWith(
                color: isDark ? Colors.white38 : Colors.black38,
              ),
              border: buildBorder(isDark),
              enabledBorder: buildBorder(isDark),
              focusedBorder: buildBorder(isDark, color: AppColors.kPrimaryColor, width: 1.8),
              errorBorder: buildBorder(isDark, color: Colors.redAccent, width: 1.2),
              focusedErrorBorder: buildBorder(isDark, color: Colors.redAccent, width: 1.8),
              suffixIcon: widget.isPassword
                  ? Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: IconButton(
                        onPressed: () {
                          setState(() {
                            isPassword = !isPassword;
                          });
                        },
                        icon: Icon(
                          isPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: isDark ? Colors.white60 : Colors.grey.shade500,
                          size: 20,
                        ),
                      ),
                    )
                  : null,
            ),
            textAlignVertical: TextAlignVertical.center,
            maxLines: widget.maxLines,
          ),
        ),
      ],
    );
  }

  OutlineInputBorder buildBorder(bool isDark, {Color? color, double width = 1.0}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: color ?? (isDark ? Colors.white10 : Colors.grey.shade300),
        width: width,
      ),
    );
  }
}
