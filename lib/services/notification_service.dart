import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/app_notification.dart';
import '../models/contact.dart';
import '../models/reminder.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';

/// Handles both push notifications (flutter_local_notifications) and
/// in-app notification records persisted in the local DB.
class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  // Android channel IDs
  static const _chHighId = 'myleads_high';
  static const _chMediumId = 'myleads_medium';
  static const _chLowId = 'myleads_low';

  static bool _initialized = false;

  // -----------------------------------------------------------------------
  // Init
  // -----------------------------------------------------------------------

  static Future<void> init() async {
    if (_initialized || kIsWeb) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: android, iOS: ios);

    await _plugin.initialize(settings);

    // Create Android notification channels
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _chHighId,
            'Rappels urgents',
            description: 'Rappels très importants',
            importance: Importance.high,
          ),
        );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _chMediumId,
            'Rappels importants',
            description: 'Rappels importants',
            importance: Importance.defaultImportance,
          ),
        );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _chLowId,
            'Rappels',
            description: 'Rappels normaux et alertes contacts',
            importance: Importance.low,
          ),
        );

    _initialized = true;
  }

  // -----------------------------------------------------------------------
  // Push notification helpers
  // -----------------------------------------------------------------------

  static NotificationDetails _detailsForPriority(String priority) {
    final AndroidNotificationDetails android;
    switch (priority) {
      case 'very_important':
        android = const AndroidNotificationDetails(
          _chHighId,
          'Rappels urgents',
          importance: Importance.high,
          priority: Priority.high,
        );
        break;
      case 'important':
        android = const AndroidNotificationDetails(
          _chMediumId,
          'Rappels importants',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        );
        break;
      default:
        android = const AndroidNotificationDetails(
          _chLowId,
          'Rappels',
          importance: Importance.low,
          priority: Priority.low,
        );
    }
    const ios = DarwinNotificationDetails();
    return NotificationDetails(android: android, iOS: ios);
  }

  static Future<void> _sendPush({
    required int id,
    required String title,
    required String body,
    required String priority,
  }) async {
    if (kIsWeb || !_initialized) return;
    try {
      await _plugin.show(id, title, body, _detailsForPriority(priority));
    } catch (_) {}
  }

  // -----------------------------------------------------------------------
  // Internal: persist an in-app notification (deduplication by id)
  // -----------------------------------------------------------------------

  static Future<void> _persistIfNew(AppNotification n) async {
    final exists = await DatabaseService.notificationExists(n.id);
    if (!exists) {
      await DatabaseService.insertNotification(n);
    }
  }

  // -----------------------------------------------------------------------
  // Public API: schedule upcoming reminder notification (15 min before)
  // -----------------------------------------------------------------------

  /// Call this whenever a reminder is created or updated.
  /// The in-app notification is stored immediately; the push fires at the
  /// actual start time minus 15 min (only future reminders).
  static Future<void> scheduleReminderUpcoming(Reminder reminder) async {
    final ownerId = StorageService.currentUserId;
    if (ownerId.isEmpty) return;

    final scheduledAt =
        reminder.startDateTime.subtract(const Duration(minutes: 15));
    final now = DateTime.now();

    final notifId = 'upcoming_${reminder.id}';
    final title = 'Rappel dans 15 min';
    final body = reminder.note.isNotEmpty
        ? reminder.note
        : 'Rappel prévu à ${_formatTime(reminder.startDateTime)}';

    // Persist in-app notification (visible only at scheduledAt — filtered in provider)
    await _persistIfNew(AppNotification(
      id: notifId,
      ownerId: ownerId,
      type: 'reminder_upcoming',
      title: title,
      body: body,
      scheduledAt: scheduledAt,
      createdAt: now,
      referenceId: reminder.id,
    ));

    // Push: only if the scheduled time is in the future
    if (scheduledAt.isAfter(now)) {
      final pushId = reminder.id.hashCode.abs() % 100000;
      // We use show() immediately only if we're ≤ 1 min away; otherwise
      // we rely on the periodic check in the provider (no background scheduling
      // is available without timezone package / WorkManager).
      // For this implementation, we fire the push at the moment the
      // periodic check first detects scheduledAt has passed.
    }
  }

  /// Called by the periodic check when scheduledAt has just passed.
  static Future<void> firePushIfDue(AppNotification n, String priority) async {
    if (kIsWeb || !_initialized) return;
    final pushId = n.id.hashCode.abs() % 100000;
    await _sendPush(
        id: pushId, title: n.title, body: n.body, priority: priority);
  }

  // -----------------------------------------------------------------------
  // Public API: overdue reminder notification (4+ hours past deadline)
  // -----------------------------------------------------------------------

  static Future<void> createOverdueReminderNotification(
      Reminder reminder) async {
    final ownerId = StorageService.currentUserId;
    if (ownerId.isEmpty) return;

    final notifId = 'overdue_${reminder.id}';
    final deadline = reminder.endDateTime ?? reminder.startDateTime;
    final title = 'Rappel en retard';
    final body = reminder.note.isNotEmpty
        ? reminder.note
        : 'Rappel du ${_formatDate(deadline)} non effectué';

    await _persistIfNew(AppNotification(
      id: notifId,
      ownerId: ownerId,
      type: 'reminder_overdue',
      title: title,
      body: body,
      scheduledAt: deadline.add(const Duration(hours: 4)),
      createdAt: DateTime.now(),
      referenceId: reminder.id,
    ));
  }

  // -----------------------------------------------------------------------
  // Public API: incomplete contact profile notification (3+ days after creation)
  // -----------------------------------------------------------------------

  static Future<void> createIncompleteContactNotification(
      Contact contact) async {
    final ownerId = StorageService.currentUserId;
    if (ownerId.isEmpty) return;
    if (contact.status != 'hot' && contact.status != 'warm') return;

    final missingFields = _missingFields(contact);
    if (missingFields.isEmpty) return;

    final notifId = 'incomplete_${contact.id}';
    final label = contact.status == 'hot' ? 'HOT' : 'WARM';
    final title = 'Profil $label incomplet';
    final body =
        '${contact.fullName} — champs manquants : ${missingFields.join(', ')}';
    final scheduledAt = contact.createdAt.add(const Duration(days: 3));

    await _persistIfNew(AppNotification(
      id: notifId,
      ownerId: ownerId,
      type: 'contact_incomplete',
      title: title,
      body: body,
      scheduledAt: scheduledAt,
      createdAt: DateTime.now(),
      referenceId: contact.id,
    ));
  }

  // -----------------------------------------------------------------------
  // Periodic check — call this on app resume / provider refresh
  // -----------------------------------------------------------------------

  /// Scans all reminders and contacts and creates any missing notifications.
  /// Also fires push notifications for in-app notifications that have just
  /// become due.
  static Future<void> runPeriodicCheck({
    required List<Reminder> reminders,
    required List<Contact> contacts,
  }) async {
    final ownerId = StorageService.currentUserId;
    if (ownerId.isEmpty) return;

    final now = DateTime.now();

    // 1. Upcoming reminder notifications (15 min before start)
    for (final r in reminders) {
      if (r.isCompleted) continue;
      await scheduleReminderUpcoming(r);
    }

    // 2. Overdue reminder notifications (4+ hours past deadline)
    for (final r in reminders) {
      if (r.isCompleted) continue;
      final deadline = r.endDateTime ?? r.startDateTime;
      final overdueThreshold = deadline.add(const Duration(hours: 4));
      if (now.isAfter(overdueThreshold)) {
        await createOverdueReminderNotification(r);
      }
    }

    // 3. Incomplete hot/warm contact notifications (3+ days after creation)
    for (final c in contacts) {
      if (c.status != 'hot' && c.status != 'warm') continue;
      final threshold = c.createdAt.add(const Duration(days: 3));
      if (now.isAfter(threshold)) {
        await createIncompleteContactNotification(c);
      }
    }

    // 4. Fire push notifications for records whose scheduledAt just passed
    //    (within the last 2 minutes to avoid repeated pushes)
    final allNotifs =
        await DatabaseService.getAllNotificationsForOwner(ownerId);
    for (final n in allNotifs) {
      if (n.scheduledAt.isAfter(now)) continue;
      if (n.scheduledAt.isBefore(now.subtract(const Duration(minutes: 2)))) {
        continue;
      }
      // Determine priority from type
      String priority = 'normal';
      if (n.type == 'reminder_upcoming' || n.type == 'reminder_overdue') {
        final matching = reminders.where((r) => r.id == n.referenceId).toList();
        if (matching.isNotEmpty) priority = matching.first.priority;
      } else if (n.type == 'contact_incomplete') {
        final matching = contacts.where((c) => c.id == n.referenceId).toList();
        if (matching.isNotEmpty) {
          priority = matching.first.status == 'hot' ? 'important' : 'normal';
        }
      }
      await firePushIfDue(n, priority);
    }
  }

  // -----------------------------------------------------------------------
  // Helpers
  // -----------------------------------------------------------------------

  static List<String> _missingFields(Contact c) {
    final missing = <String>[];
    if (c.phone == null || c.phone!.trim().isEmpty) missing.add('téléphone');
    if (c.email == null || c.email!.trim().isEmpty) missing.add('email');
    if (c.company == null || c.company!.trim().isEmpty) missing.add('entreprise');
    if (c.jobTitle == null || c.jobTitle!.trim().isEmpty) missing.add('poste');
    if (c.notes == null || c.notes!.trim().isEmpty) missing.add('notes');
    if (c.interest == null || c.interest!.trim().isEmpty)
      missing.add('intérêt');
    if (c.source == null || c.source!.trim().isEmpty) missing.add('source');
    return missing;
  }

  static String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}h${dt.minute.toString().padLeft(2, '0')}';

  static String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}
