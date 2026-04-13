import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/reminder.dart';
import '../../providers/reminders_provider.dart';
import '../../services/calendar_service.dart';

class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(remindersProvider);
    final reminders = state.activeReminders;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 10,
              left: 24,
              right: 24,
              bottom: 24,
            ),
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  AppStrings.remindersTitle,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppStrings.remindersSubtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // Tabs
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildTab(
                  ref,
                  state.todayReminders.length.toString(),
                  AppStrings.today,
                  'today',
                  state.activeTab,
                ),
                const SizedBox(width: 8),
                _buildTab(
                  ref,
                  state.overdueReminders.length.toString(),
                  AppStrings.overdue,
                  'overdue',
                  state.activeTab,
                  isOverdue: true,
                ),
                const SizedBox(width: 8),
                _buildTab(
                  ref,
                  state.weekReminders.length.toString(),
                  AppStrings.thisWeek,
                  'week',
                  state.activeTab,
                ),
              ],
            ),
          ),

          // Reminders List
          Expanded(
            child: reminders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline,
                            size: 64, color: AppColors.success.withOpacity(0.4)),
                        const SizedBox(height: 16),
                        const Text(
                          'Tout est à jour !',
                          style: TextStyle(
                            color: AppColors.textMid,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: reminders.length,
                    itemBuilder: (context, index) {
                      return _buildReminderItem(context, ref, reminders[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(
    WidgetRef ref,
    String count,
    String label,
    String value,
    String active, {
    bool isOverdue = false,
  }) {
    final isActive = active == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(remindersProvider.notifier).setActiveTab(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? AppColors.primary : AppColors.border,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Text(
                count,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isActive
                      ? Colors.white
                      : isOverdue
                          ? AppColors.hot
                          : AppColors.textDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isActive
                      ? Colors.white.withOpacity(0.6)
                      : AppColors.textMid,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReminderItem(BuildContext context, WidgetRef ref, Reminder reminder) {
    Color priorityColor;
    switch (reminder.priority) {
      case 'urgent':
        priorityColor = AppColors.hot;
        break;
      case 'soon':
        priorityColor = AppColors.warm;
        break;
      default:
        priorityColor = AppColors.success;
    }

    final timeText = reminder.isOverdue
        ? 'En retard'
        : DateFormat('HH:mm').format(reminder.dueDate);

    return Dismissible(
      key: Key(reminder.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        ref.read(remindersProvider.notifier).completeReminder(reminder.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rappel terminé !')),
        );
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.success,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.check, color: Colors.white, size: 28),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left border indicator
            Container(
              width: 4,
              height: 50,
              decoration: BoxDecoration(
                color: priorityColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 14),

            // Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [priorityColor, priorityColor.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  reminder.description?.split(' ').take(2).map((w) => w.isNotEmpty ? w[0] : '').join() ?? '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reminder.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  if (reminder.description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      reminder.description!,
                      style: const TextStyle(fontSize: 12, color: AppColors.textMid),
                    ),
                  ],
                ],
              ),
            ),

            // Calendar sync button
            GestureDetector(
              onTap: () {
                CalendarService.addReminderToCalendar(reminder);
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.calendar_month, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text('Ajouté au calendrier'),
                        ],
                      ),
                      backgroundColor: AppColors.primary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
              },
              child: Container(
                width: 36,
                height: 36,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.calendar_month, size: 18, color: AppColors.primary),
              ),
            ),

            // Time badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: priorityColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                timeText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: priorityColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
