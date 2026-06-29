import 'package:flutter/material.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';

class CustomDropDownButtonFormField<T> extends StatelessWidget {
  const CustomDropDownButtonFormField({
    super.key,
    required this.items,
    this.controller,
    this.hintText,
    this.title,
    this.onChanged,
    this.fillColor,
    this.filled,
    this.itemLabelBuilder,
    this.value,
    this.prefixIcon,
    this.textColor,
    this.iconColor,
    this.titleColor,
  });

  final List<T> items;
  final T? value; 
  final IconData? prefixIcon;

  final TextEditingController? controller;
  final String? hintText;
  final String? title;
  final Function(T?)? onChanged;
  final Color? fillColor;
  final bool? filled;
  final Color? textColor;
  final Color? iconColor;
  final Color? titleColor;

  final String Function(T)? itemLabelBuilder;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(
            title!, 
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: titleColor ?? (isDark ? Colors.white : Colors.black87),
              fontSize: 13,
            ),
          ),
          SizedBox(height: SizeConfig.height * 0.006),
        ],
        DropdownButtonFormField<T>(
          initialValue: value,
          hint: Text(
            hintText ?? "Select",
            style: TextStyle(
              color: textColor?.withValues(alpha: 0.7) ?? (isDark ? Colors.white70 : Colors.black54),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          items: items
              .map(
                (e) => DropdownMenuItem<T>(
                  value: e,
                  child: Text(
                    itemLabelBuilder != null
                        ? itemLabelBuilder!(e)
                        : e.toString(),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              )
              .toList(),
          selectedItemBuilder: (context) => items
              .map(
                (e) => Text(
                  itemLabelBuilder != null
                      ? itemLabelBuilder!(e)
                      : e.toString(),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: textColor ?? (isDark ? Colors.white : Colors.black87),
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              )
              .toList(),

          onChanged: (val) {
            if (controller != null) {
              controller!.text = val.toString();
            }
            if (onChanged != null) onChanged!(val);
          },
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded, 
            color: iconColor ?? (isDark ? Colors.white70 : Colors.black54),
          ),
          dropdownColor: isDark ? const Color(0xFF1E1B15) : Colors.white,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: textColor ?? (isDark ? Colors.white : Colors.black87),
          ),
          decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(
              horizontal: SizeConfig.width * 0.04,
              vertical: SizeConfig.height * 0.014,
            ),
            filled: filled ?? true,
            fillColor: fillColor ?? (isDark ? const Color(0xFF1E1B15) : Colors.white),
            border: _buildBorder(context),
            enabledBorder: _buildBorder(context),
            focusedBorder: _buildFocusedBorder(context),
            errorBorder: _buildErrorBorder(context),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: iconColor ?? Theme.of(context).primaryColor, size: 20)
                : null,
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _buildBorder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade300,
        width: 1,
      ),
    );
  }

  OutlineInputBorder _buildFocusedBorder(BuildContext context) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: Theme.of(context).primaryColor,
        width: 1.5,
      ),
    );
  }
  
  OutlineInputBorder _buildErrorBorder(BuildContext context) {
     return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: Theme.of(context).colorScheme.error,
        width: 1,
      ),
    );
  }
}
