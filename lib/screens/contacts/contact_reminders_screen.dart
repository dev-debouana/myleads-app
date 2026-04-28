import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/l10n/app_l10n.dart';
import '../../models/reminder.dart';
import '../../providers/reminders_provider.dart';
import '../reminders/reminder_detail_screen.dart';

class ContactRemindersScreen extends ConsumerWidget {
  final String contactId;

  const ContactRemindersScreen({super.key, required this.contactId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(l10nProvider);
    final pending = ref
        .watch(remindersProvider)
        .getRemindersForContact(contactId)
        .where((r) => !r.isCompleted)
        .toList();
    // getRemindersForContact already sorts ascending by startDateTime

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 10,
              bottom: 24,
              left: 24,
              right: 24,
            ),
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  l10n.allPendingReminders,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: pending.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.alarm_off_rounded,
                            size: 48, color: AppColors.hint(context)),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noPendingReminders,
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.hint(context),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: pending.length,
                    itemBuilder: (context, index) =>
                        _reminderCard(context, ref, pending[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _reminderCard(
      BuildContext context, WidgetRef ref, Reminder reminder) {
    Color priorityColor;
    switch (reminder.priority) {
      case 'very_important':
        priorityColor = AppColors.hot;
        break;
      case 'important':
        priorityColor = AppColors.warm;
        break;
      default:
        priorityColor = AppColors.success;
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProviderScope(
            parent: ProviderScope.containerOf(context),
            child: ReminderDetailScreen(reminderId: reminder.id),
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceColor(context),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 44,
              decoration: BoxDecoration(
                color: priorityColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reminder.note,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface(context),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd MMM yyyy HH:mm')
                        .format(reminder.startDateTime),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.hint(context),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: AppColors.hint(context), size: 20),
          ],
        ),
      ),
    );
  }
}
