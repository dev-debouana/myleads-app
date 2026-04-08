import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// A quick action button displaying an icon inside a colored circle
/// with a label underneath. Used for actions like Call, SMS, WhatsApp, Email.
class QuickActionButton extends StatelessWidget {
  /// The icon to display inside the circle.
  final IconData icon;

  /// The label displayed below the icon.
  final String label;

  /// The accent color for the icon and circle background.
  final Color color;

  /// Callback when the button is tapped.
  final VoidCallback? onTap;

  /// Size of the icon circle. Defaults to 48.
  final double size;

  const QuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon circle
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                customBorder: const CircleBorder(),
                splashColor: color.withOpacity(0.2),
                highlightColor: color.withOpacity(0.1),
                child: Center(
                  child: Icon(
                    icon,
                    color: color,
                    size: size * 0.45,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Label
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textMid,
              letterSpacing: 0.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Pre-built quick action buttons for common actions.
class QuickActions {
  QuickActions._();

  static QuickActionButton call({
    required VoidCallback? onTap,
    double size = 48,
  }) {
    return QuickActionButton(
      icon: Icons.phone_rounded,
      label: 'Appeler',
      color: AppColors.success,
      onTap: onTap,
      size: size,
    );
  }

  static QuickActionButton sms({
    required VoidCallback? onTap,
    double size = 48,
  }) {
    return QuickActionButton(
      icon: Icons.message_rounded,
      label: 'SMS',
      color: AppColors.info,
      onTap: onTap,
      size: size,
    );
  }

  static QuickActionButton whatsapp({
    required VoidCallback? onTap,
    double size = 48,
  }) {
    return QuickActionButton(
      icon: Icons.chat_rounded,
      label: 'WhatsApp',
      color: const Color(0xFF25D366),
      onTap: onTap,
      size: size,
    );
  }

  static QuickActionButton email({
    required VoidCallback? onTap,
    double size = 48,
  }) {
    return QuickActionButton(
      icon: Icons.email_rounded,
      label: 'Email',
      color: AppColors.accent,
      onTap: onTap,
      size: size,
    );
  }

  static QuickActionButton reminder({
    required VoidCallback? onTap,
    double size = 48,
  }) {
    return QuickActionButton(
      icon: Icons.notifications_active_rounded,
      label: 'Rappel',
      color: AppColors.warm,
      onTap: onTap,
      size: size,
    );
  }
}
