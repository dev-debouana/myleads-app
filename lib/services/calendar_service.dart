import 'package:add_2_calendar/add_2_calendar.dart';
import '../models/reminder.dart';

/// Adds a [Reminder] to the device's native calendar app.
class CalendarService {
  CalendarService._();

  static Future<void> addReminderToCalendar(Reminder reminder) async {
    final event = Event(
      title: reminder.title,
      description: reminder.description ?? '',
      location: '',
      startDate: reminder.dueDate,
      endDate: reminder.dueDate.add(const Duration(minutes: 30)),
      allDay: false,
      iosParams: const IOSParams(reminder: Duration(minutes: 15)),
      androidParams: const AndroidParams(emailInvites: []),
    );
    Add2Calendar.addEvent2Cal(event);
  }
}
