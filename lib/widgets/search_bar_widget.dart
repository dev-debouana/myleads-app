import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// A custom search bar widget with configurable appearance for both
/// dark headers (translucent white) and light screens (standard background).
class SearchBarWidget extends StatelessWidget {
  /// Callback when the text changes.
  final ValueChanged<String>? onChanged;

  /// Callback when the search bar is tapped (useful for navigating to a
  /// dedicated search screen).
  final VoidCallback? onTap;

  /// Placeholder text. Defaults to 'Rechercher un contact...'.
  final String hintText;

  /// Whether the search bar sits on a dark background (e.g., a gradient
  /// header). When true, uses a translucent white style.
  final bool isDark;

  /// An optional [TextEditingController] for external control.
  final TextEditingController? controller;

  /// Whether the text field is read-only (tap-to-navigate mode).
  final bool readOnly;

  /// An optional suffix widget (e.g., a filter icon button).
  final Widget? suffixIcon;

  /// Whether to autofocus the text field.
  final bool autofocus;

  const SearchBarWidget({
    super.key,
    this.onChanged,
    this.onTap,
    this.hintText = 'Rechercher un contact...',
    this.isDark = false,
    this.controller,
    this.readOnly = false,
    this.suffixIcon,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isDark
        ? Colors.white.withOpacity(0.15)
        : AppColors.inputBg;

    final borderColor = isDark
        ? Colors.white.withOpacity(0.1)
        : AppColors.border;

    final iconColor = isDark
        ? Colors.white.withOpacity(0.7)
        : AppColors.textLight;

    final hintColor = isDark
        ? Colors.white.withOpacity(0.5)
        : AppColors.textLight;

    final textColor = isDark ? AppColors.white : AppColors.textDark;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor,
          width: isDark ? 1 : 1.5,
        ),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onTap: onTap,
        readOnly: readOnly,
        autofocus: autofocus,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
        cursorColor: isDark ? AppColors.accent : AppColors.primary,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: hintColor,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 14, right: 10),
            child: Icon(
              Icons.search_rounded,
              size: 20,
              color: iconColor,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 44,
            minHeight: 44,
          ),
          suffixIcon: suffixIcon != null
              ? Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: suffixIcon,
                )
              : null,
          suffixIconConstraints: suffixIcon != null
              ? const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 0,
            vertical: 14,
          ),
          isDense: true,
        ),
      ),
    );
  }
}
