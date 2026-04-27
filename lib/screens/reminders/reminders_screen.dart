import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../models/reminder.dart';
import '../../providers/contacts_provider.dart';
import '../../providers/reminders_provider.dart';
import '../../services/calendar_service.dart';
import 'create_reminder_screen.dart';
import 'reminder_detail_screen.dart';

class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({super.key});
  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen> {
  String _activeTab = 'today';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(remindersProvider);
    List<Reminder> current;
    switch (_activeTab) {
      case 'week':
        current = state.weekReminders;
        break;
      case 'later':
        current = state.laterReminders;
        break;
      case 'late':
        current = state.lateReminders;
        break;
      case 'done':
        current = state.doneReminders;
        break;
      default:
        current = state.todayReminders;
    }

    final tabs = <(String, String, int)>[
      ('today', "Aujourd'hui", state.todayReminders.length),
      ('week', 'Semaine', state.weekReminders.length),
      ('later', 'Plus tard', state.laterReminders.length),
      ('late', 'En retard', state.lateReminders.length),
      ('done', 'Termines', state.doneReminders.length),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          bottom: 88 + MediaQuery.of(context).padding.bottom,
        ),
        child: FloatingActionButton.extended(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProviderScope(
                  parent: ProviderScope.containerOf(context),
                  child: const CreateReminderScreen(),
                ),
              ),
            );
          },
          icon: const Icon(Icons.add_rounded),
          label: const Text('Nouveau rappel',
              style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.notifications_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Rappels',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark)),
                        Text('Vos taches et suivis',
                            style: TextStyle(fontSize: 13, color: AppColors.textMid)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: tabs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final t = tabs[i];
                  final active = t.$1 == _activeTab;
                  return GestureDetector(
                    onTap: () => setState(() => _activeTab = t.$1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: active ? AppColors.primaryGradient : null,
                        color: active ? null : AppColors.card,
                        borderRadius: BorderRadius.circular(22),
                        border: active ? null : Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Text(t.$2,
                              style: TextStyle(
                                color: active ? Colors.white : AppColors.textMid,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              )),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: active
                                  ? Colors.white.withOpacity(0.25)
                                  : AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('${t.$3}',
                                style: TextStyle(
                                  color: active ? Colors.white : AppColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                )),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: current.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      onRefresh: () => ref.read(remindersProvider.notifier).refresh(),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        itemCount: current.length,
                        itemBuilder: (_, i) => _ReminderCard(reminder: current[i]),
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
          const Text('Aucun rappel',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
          const SizedBox(height: 6),
          const Text('Appuyez sur + pour en creer un.',
              style: TextStyle(fontSize: 13, color: AppColors.textMid)),
        ],
      ),
    );
  }
}

class _ReminderCard extends ConsumerWidget {
  final Reminder reminder;
  const _ReminderCard({required this.reminder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
    IconData actionIcon;
    switch (reminder.toDoAction) {
      case 'sms':
        actionIcon = Icons.sms_rounded;
        break;
      case 'whatsapp':
        actionIcon = Icons.chat_rounded;
        break;
      case 'email':
        actionIcon = Icons.email_rounded;
        break;
      default:
        actionIcon = Icons.phone_rounded;
    }

    final contacts = ref.watch(contactsProvider).contacts;
    final linked = contacts.where((c) => reminder.contactIds.contains(c.id)).toList();
    final contactLabel = linked.isEmpty
        ? 'Contact supprime'
        : linked.length == 1
            ? linked.first.fullName
            : '${linked.first.fullName} +${linked.length - 1}';

    final dateLabel = DateFormat('dd MMM HH:mm').format(reminder.startDateTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProviderScope(
                parent: ProviderScope.containerOf(context),
                child: ReminderDetailScreen(reminderId: reminder.id),
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 48,
                  decoration: BoxDecoration(
                      color: priorityColor, borderRadius: BorderRadius.circular(4)),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(actionIcon, color: priorityColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder.note,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.person_outline_rounded,
                              size: 12, color: AppColors.textLight),
                          const SizedBox(width: 3),
                          Expanded(
                              child: Text(contactLabel,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 11, color: AppColors.textMid))),
                          const SizedBox(width: 8),
                          const Icon(Icons.access_time_rounded,
                              size: 12, color: AppColors.textLight),
                          const SizedBox(width: 3),
                          Text(dateLabel,
                              style: const TextStyle(fontSize: 11, color: AppColors.textMid)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    CalendarService.addReminderToCalendar(reminder);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Ajoute au calendrier'),
                          backgroundColor: AppColors.primary),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.calendar_month_rounded,
                        size: 16, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
