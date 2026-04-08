import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/contact.dart';
import 'status_badge.dart';

/// A contact/lead card widget that displays an avatar with initials (using a
/// gradient background derived from [Contact.avatarColor] or status), the
/// contact's name, company/role subtitle, a [StatusBadge], and optional
/// quick-action buttons for calling and WhatsApp.
class LeadCard extends StatelessWidget {
  /// The contact data to display.
  final Contact contact;

  /// Callback when the entire card is tapped.
  final VoidCallback? onTap;

  /// Callback for the phone quick-action button. If null, the button is hidden.
  final VoidCallback? onCall;

  /// Callback for the WhatsApp quick-action button. If null, the button is hidden.
  final VoidCallback? onWhatsApp;

  /// Whether to show the quick action buttons. Defaults to true.
  final bool showActions;

  /// Whether to display in a compact style (list tile). Defaults to false.
  final bool compact;

  const LeadCard({
    super.key,
    required this.contact,
    this.onTap,
    this.onCall,
    this.onWhatsApp,
    this.showActions = true,
    this.compact = false,
  });

  /// Resolves the avatar gradient. If [Contact.avatarColor] is set, builds
  /// a gradient from that hex value; otherwise falls back to a status-based
  /// gradient from [AppColors].
  LinearGradient _avatarGradient() {
    if (contact.avatarColor != null && contact.avatarColor!.isNotEmpty) {
      final hex = contact.avatarColor!.replaceAll('#', '');
      final colorValue = int.tryParse('FF$hex', radix: 16);
      if (colorValue != null) {
        final base = Color(colorValue);
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            base,
            HSLColor.fromColor(base)
                .withLightness(
                  (HSLColor.fromColor(base).lightness + 0.15).clamp(0.0, 1.0),
                )
                .toColor(),
          ],
        );
      }
    }
    return AppColors.avatarGradient(contact.status);
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompact(context);
    }
    return _buildFull(context);
  }

  // ---------- Full card layout ----------

  Widget _buildFull(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            splashColor: AppColors.primary.withOpacity(0.05),
            highlightColor: AppColors.primary.withOpacity(0.03),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Avatar
                  _buildAvatar(size: 50),
                  const SizedBox(width: 14),

                  // Name, subtitle, badge
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name row + badge
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                contact.fullName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            StatusBadge(status: contact.status),
                          ],
                        ),

                        // Subtitle
                        if (contact.subtitle.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            contact.subtitle,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textMid,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],

                        // Tags row
                        if (contact.tags.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          _buildTagRow(),
                        ],
                      ],
                    ),
                  ),

                  // Quick actions
                  if (showActions && (onCall != null || onWhatsApp != null)) ...[
                    const SizedBox(width: 8),
                    _buildActionColumn(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------- Compact list-tile layout ----------

  Widget _buildCompact(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            _buildAvatar(size: 42),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.fullName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (contact.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      contact.subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMid,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            StatusBadge(status: contact.status, compact: true, fontSize: 9),
            if (onTap != null)
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppColors.textLight,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ---------- Shared sub-widgets ----------

  Widget _buildAvatar({required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: _avatarGradient(),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _avatarGradient().colors.first.withOpacity(0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          contact.initials,
          style: TextStyle(
            fontSize: size * 0.36,
            fontWeight: FontWeight.w800,
            color: AppColors.white,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildTagRow() {
    final displayTags = contact.tags.take(2).toList();
    final remaining = contact.tags.length - displayTags.length;

    return Row(
      children: [
        ...displayTags.map(
          (tag) => Container(
            margin: const EdgeInsets.only(right: 4),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.07),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              tag,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        if (remaining > 0)
          Text(
            '+$remaining',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textLight,
            ),
          ),
      ],
    );
  }

  Widget _buildActionColumn() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onCall != null)
          _ActionIcon(
            icon: Icons.phone_rounded,
            color: AppColors.success,
            onTap: onCall!,
            tooltip: 'Appeler',
          ),
        if (onCall != null && onWhatsApp != null) const SizedBox(height: 6),
        if (onWhatsApp != null)
          _ActionIcon(
            icon: Icons.chat_rounded,
            color: const Color(0xFF25D366),
            onTap: onWhatsApp!,
            tooltip: 'WhatsApp',
          ),
      ],
    );
  }
}

/// A small circular icon button used for inline quick actions on the card.
class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;

  const _ActionIcon({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color.withOpacity(0.1),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          splashColor: color.withOpacity(0.2),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              size: 16,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
