import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:smart_canvas/core/utilies/extensions/app_extensions.dart';
import 'package:smart_canvas/core/utilies/styles/app_text_styles.dart';
import 'package:flutter/material.dart';

class CustomElevatedButton extends StatefulWidget {
  const CustomElevatedButton({
    super.key,
    required this.name,
    this.onPressed,
    this.textStyle,
    this.hPadding,
    this.wPadding,
    this.height,
    this.width,
    this.backgroundColor,
    this.forgroundColor,
    this.icon,
  });

  final String name;
  final Function()? onPressed;
  final TextStyle? textStyle;
  final double? hPadding, wPadding;
  final double? height, width;
  final Color? backgroundColor;
  final Color? forgroundColor;
  final IconData? icon;

  @override
  State<CustomElevatedButton> createState() => _CustomElevatedButtonState();
}

class _CustomElevatedButtonState extends State<CustomElevatedButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.96 : (_isHovered ? 1.03 : 1.0),
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: (widget.backgroundColor ?? AppColors.kPrimaryColor)
                      .withValues(alpha: _isHovered ? 0.35 : 0.15),
                  blurRadius: _isHovered ? 16 : 8,
                  offset: Offset(0, _isHovered ? 6 : 4),
                ),
              ],
            ),
            child: widget.icon != null
                ? ElevatedButton.icon(
                    style: _buttonStyle(context),
                    onPressed: widget.onPressed,
                    icon: Icon(widget.icon, color: widget.forgroundColor ?? Colors.white),
                    label: Text(
                      widget.name,
                      style: widget.textStyle ?? AppTextStyles.title20WhiteW500,
                    ),
                  )
                : ElevatedButton(
                    style: _buttonStyle(context),
                    onPressed: widget.onPressed,
                    child: Text(
                      widget.name,
                      style: widget.textStyle ?? AppTextStyles.title20WhiteW500,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  ButtonStyle _buttonStyle(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: widget.backgroundColor ?? AppColors.kPrimaryColor,
      foregroundColor: widget.forgroundColor,
      elevation: 0, // Handled by Custom Box Shadow for premium look
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: widget.wPadding ?? context.screenWidth * 0.05,
        vertical: widget.hPadding ?? context.screenHeight * 0.01,
      ),
      minimumSize: (widget.width != null || widget.height != null)
          ? Size(widget.width ?? 0, widget.height ?? 0)
          : null,
    );
  }
}
