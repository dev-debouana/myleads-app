import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// A reusable badge widget that displays the lead status (HOT, WARM, COLD)
/// with appropriate color coding and styling.
class StatusBadge extends StatelessWidget {
  /// The lead status string: 'hot', 'warm', or 'cold'.
  final String status;

  /// Optional font size override. Defaults to 10.
  final double fontSize;

  /// Whether to display as a compact dot + text or full badge.
  final bool compact;

  const StatusBadge({
    super.key,
    required this.status,
    this.fontSize = 10,
    this.compact = false,
  });

  Color get _color {
    switch (status.toLowerCase()) {
      case 'hot':
        return AppColors.hot;
      case 'warm':
        return AppColors.warm;
      case 'cold':
        return AppColors.cold;
      default:
        return AppColors.cold;
    }
  }

  Color get _backgroundColor {
    switch (status.toLowerCase()) {
      case 'hot':
        return AppColors.hot.withOpacity(0.12);
      case 'warm':
        return AppColors.warm.withOpacity(0.12);
      case 'cold':
        return AppColors.cold.withOpacity(0.12);
      default:
        return AppColors.cold.withOpacity(0.12);
    }
  }

  String get _label {
    switch (status.toLowerCase()) {
      case 'hot':
        return 'HOT';
      case 'warm':
        return 'WARM';
      case 'cold':
        return 'COLD';
      default:
        return status.toUpperCase();
    }
  }

  IconData get _icon {
    switch (status.toLowerCase()) {
      case 'hot':
        return Icons.local_fire_department_rounded;
      case 'warm':
        return Icons.wb_sunny_rounded;
      case 'cold':
        return Icons.ac_unit_rounded;
      default:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompact();
    }
    return _buildFull();
  }

  Widget _buildFull() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _color.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _icon,
            size: fontSize + 2,
            color: _color,
          ),
          const SizedBox(width: 4),
          Text(
            _label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: _color,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompact() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: _color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _color.withOpacity(0.4),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          _label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: _color,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
