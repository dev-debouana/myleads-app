import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_notification.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import 'contacts_provider.dart';
import 'reminders_provider.dart';

class NotificationsState {
  final List<AppNotification> notifications;
  final bool loading;

  const NotificationsState({
    this.notifications = const [],
    this.loading = false,
  });

  /// Only notifications whose scheduledAt <= now are visible in the screen.
  List<AppNotification> get visible {
    final now = DateTime.now();
    return notifications.where((n) => !n.scheduledAt.isAfter(now)).toList();
  }

  int get unreadCount => visible.where((n) => !n.isRead).length;

  NotificationsState copyWith({
    List<AppNotification>? notifications,
    bool? loading,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      loading: loading ?? this.loading,
    );
  }
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  NotificationsNotifier() : super(const NotificationsState()) {
    _load();
  }

  Future<void> _load() async {
    final ownerId = StorageService.currentUserId;
    if (ownerId.isEmpty) return;
    final list = await DatabaseService.getAllNotificationsForOwner(ownerId);
    // Sort: unread first, then by scheduledAt descending
    list.sort((a, b) {
      if (a.isRead != b.isRead) return a.isRead ? 1 : -1;
      return b.scheduledAt.compareTo(a.scheduledAt);
    });
    state = state.copyWith(notifications: list);
  }

  Future<void> markRead(String id) async {
    await DatabaseService.markNotificationRead(id);
    state = state.copyWith(
      notifications: state.notifications
          .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
          .toList(),
    );
  }

  Future<void> delete(String id) async {
    await DatabaseService.deleteNotification(id);
    state = state.copyWith(
      notifications: state.notifications.where((n) => n.id != id).toList(),
    );
  }

  Future<void> refresh() => _load();
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  return NotificationsNotifier();
});

/// Watches reminders + contacts and triggers a periodic check to generate
/// any missing notifications, then refreshes the notifications list.
final notificationsSyncProvider = Provider<void>((ref) {
  final remindersState = ref.watch(remindersProvider);
  final contactsState = ref.watch(contactsProvider);

  // Schedule the async work outside the current build frame to avoid
  // "state modified during build" errors.
  SchedulerBinding.instance.addPostFrameCallback((_) async {
    await NotificationService.runPeriodicCheck(
      reminders: remindersState.reminders,
      contacts: contactsState.contacts,
    );
    ref.read(notificationsProvider.notifier).refresh();
  });
});
