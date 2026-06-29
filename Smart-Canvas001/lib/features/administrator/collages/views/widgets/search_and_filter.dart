import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';

class SearchAndFilter extends StatefulWidget {
  const SearchAndFilter({
    super.key,
    required this.hintText,
    this.onPressedFilter,
    this.onChanged,
    this.controller,
  });
  final String hintText;
  final Function()? onPressedFilter;
  final Function(String)? onChanged;
  final TextEditingController? controller;

  @override
  State<SearchAndFilter> createState() => _SearchAndFilterState();
}

class _SearchAndFilterState extends State<SearchAndFilter> {
  late final TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(() {
      final hasText = _controller.text.isNotEmpty;
      if (hasText != _hasText) {
        setState(() => _hasText = hasText);
      }
    });
  }

  @override
  void dispose() {
    // Only dispose if we created it ourselves
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: TextField(
              controller: _controller,
              onChanged: (v) {
                widget.onChanged?.call(v);
              },
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                prefixIcon: const Icon(LineIcons.search, color: Colors.grey),
                suffixIcon: _hasText
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.grey, size: 18),
                        onPressed: () {
                          _controller.clear();
                          widget.onChanged?.call('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ),
        if (widget.onPressedFilter != null) ...[
          const SizedBox(width: 12),
          GestureDetector(
            onTap: widget.onPressedFilter,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.2),
                    Colors.white.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(LineIcons.filter, color: Colors.white),
            ),
          ),
        ],
      ],
    );
  }
}
