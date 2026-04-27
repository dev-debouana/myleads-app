import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../models/app_notification.dart';
import '../../providers/notifications_provider.dart';
import '../contacts/contact_detail_screen.dart';
import '../reminders/reminder_detail_screen.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<AppNotification> _filtered(List<AppNotification> visible) {
    if (_query.trim().isEmpty) return visible;
    final q = _query.toLowerCase();
    return visible
        .where(
            (n) => n.title.toLowerCase().contains(q) || n.body.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    // Watch sync provider so it re-runs when reminders/contacts change
    ref.watch(notificationsSyncProvider);

    final state = ref.watch(notificationsProvider);
    final items = _filtered(state.visible);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          if (state.unreadCount > 0)
            TextButton(
              onPressed: () async {
                for (final n in state.visible.where((n) => !n.isRead)) {
                  await ref.read(notificationsProvider.notifier).markRead(n.id);
                }
              },
              child: const Text(
                'Tout lire',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v),
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.textDark),
                  cursorColor: AppColors.primary,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    hintText: 'Rechercher une notification…',
                    hintStyle: const TextStyle(
                        fontSize: 14, color: AppColors.textLight),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppColors.textLight, size: 20),
                    suffixIcon: _query.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchCtrl.clear();
                              setState(() => _query = '');
                            },
                            child: const Icon(Icons.close_rounded,
                                color: AppColors.textLight, size: 18),
                          )
                        : null,
                  ),
                ),
              ),
            ),

            // List
            Expanded(
              child: state.loading
                  ? const Center(child: CircularProgressIndicator())
                  : items.isEmpty
                      ? _buildEmpty()
                      : RefreshIndicator(
                          onRefresh: () =>
                              ref.read(notificationsProvider.notifier).refresh(),
                          child: ListView.builder(
                            padding:
                                const EdgeInsets.fromLTRB(20, 4, 20, 100),
                            itemCount: items.length,
                            itemBuilder: (_, i) =>
                                _NotificationCard(notification: items[i]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.notifications_off_outlined,
                size: 36, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucune notification',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark),
          ),
          const SizedBox(height: 6),
          Text(
            _query.isNotEmpty
                ? 'Aucun résultat pour "$_query"'
                : 'Vos alertes et rappels apparaîtront ici.',
            textAlign: TextAlign.center,
            style:
                const TextStyle(fontSize: 13, color: AppColors.textMid),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends ConsumerWidget {
  final AppNotification notification;

  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = notification;
    final isRead = n.isRead;
    final accent = _accentForType(n.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isRead ? AppColors.card : AppColors.primary.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isRead ? AppColors.border : AppColors.primary.withOpacity(0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            // Mark as read
            if (!isRead) {
              await ref.read(notificationsProvider.notifier).markRead(n.id);
            }
            // Navigate
            if (!context.mounted) return;
            _navigate(context, n);
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon badge
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_iconForType(n.type), color: accent, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              n.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isRead
                                    ? FontWeight.w600
                                    : FontWeight.w800,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        n.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textMid),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _labelForType(n.type),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('dd MMM yyyy • HH:mm')
                            .format(n.scheduledAt),
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textLight),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigate(BuildContext context, AppNotification n) {
    if (n.referenceId == null) return;
    switch (n.type) {
      case 'reminder_upcoming':
      case 'reminder_overdue':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProviderScope(
              parent: ProviderScope.containerOf(context),
              child: ReminderDetailScreen(reminderId: n.referenceId!),
            ),
          ),
        );
        break;
      case 'contact_incomplete':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProviderScope(
              parent: ProviderScope.containerOf(context),
              child: ContactDetailScreen(contactId: n.referenceId!),
            ),
          ),
        );
        break;
    }
  }

  Color _accentForType(String type) {
    switch (type) {
      case 'reminder_overdue':
        return AppColors.hot;
      case 'reminder_upcoming':
        return AppColors.primary;
      case 'contact_incomplete':
        return AppColors.warm;
      default:
        return AppColors.primary;
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'reminder_overdue':
        return Icons.alarm_off_rounded;
      case 'reminder_upcoming':
        return Icons.alarm_rounded;
      case 'contact_incomplete':
        return Icons.person_outline_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  String _labelForType(String type) {
    switch (type) {
      case 'reminder_overdue':
        return 'RAPPEL EN RETARD';
      case 'reminder_upcoming':
        return 'RAPPEL À VENIR';
      case 'contact_incomplete':
        return 'PROFIL INCOMPLET';
      default:
        return 'NOTIFICATION';
    }
  }
}
