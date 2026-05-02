import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:workmanager/workmanager.dart';

import 'database_service.dart';
import 'notification_service.dart';
import 'storage_service.dart';

const _kPeriodicTaskName = 'myleads_notification_check';

/// Entry point called by WorkManager in a background isolate.
/// Must be a top-level function annotated with @pragma('vm:entry-point').
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, _) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      tz.initializeTimeZones();

      await StorageService.init();
      await NotificationService.init();

      final ownerId = StorageService.currentUserId;
      if (ownerId.isEmpty) return true;

      final reminders = await DatabaseService.getAllRemindersForOwner(ownerId);
      final contacts = await DatabaseService.getAllContactsForOwner(ownerId);

      await NotificationService.runPeriodicCheck(
        reminders: reminders,
        contacts: contacts,
      );
      return true;
    } catch (_) {
      return false;
    }
  });
}

/// Registers WorkManager and the periodic notification-check task.
/// Only runs on Android — iOS background refresh is OS-controlled.
Future<void> initBackgroundTasks() async {
  if (kIsWeb || !Platform.isAndroid) return;
  try {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
    await Workmanager().registerPeriodicTask(
      _kPeriodicTaskName,
      _kPeriodicTaskName,
      frequency: const Duration(hours: 1),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      constraints: Constraints(networkType: NetworkType.notRequired),
    );
  } catch (_) {}
}
