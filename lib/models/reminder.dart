/// Reminder entity – v2 schema (multi-contact, full scheduling).
class Reminder {
  final String id;
  final String ownerId;

  /// Primary contact ID (first element of contactIds for backward compat).
  String get contactId => contactIds.isNotEmpty ? contactIds.first : '';

  final List<String> contactIds;
  final DateTime startDateTime;
  final DateTime? endDateTime;
  final String? repeatFrequency;
  final String note;
  final String toDoAction;
  final String priority;
  bool isCompleted;
  final DateTime createdAt;

  Reminder({
    required this.id,
    required this.ownerId,
    required this.contactIds,
    required this.startDateTime,
    this.endDateTime,
    this.repeatFrequency,
    required this.note,
    this.toDoAction = 'call',
    this.priority = 'normal',
    this.isCompleted = false,
    DateTime? createdAt,
  })  : assert(contactIds.isNotEmpty, 'At least one contact is required'),
        createdAt = createdAt ?? DateTime.now();

  bool get isOverdue {
    if (isCompleted) return false;
    return startDateTime.isBefore(DateTime.now());
  }

  bool get isToday {
    final now = DateTime.now();
    return startDateTime.year == now.year &&
        startDateTime.month == now.month &&
        startDateTime.day == now.day;
  }

  bool get isThisWeek {
    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day - (now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
    return startDateTime.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) &&
        startDateTime.isBefore(endOfWeek.add(const Duration(seconds: 1)));
  }

  bool get isLater {
    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day - (now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
    return startDateTime.isAfter(endOfWeek);
  }

  bool get isLate {
    if (isCompleted) return false;
    final deadline = endDateTime ?? startDateTime;
    return deadline.isBefore(DateTime.now());
  }

  DateTime get sortKey => endDateTime ?? startDateTime;

  Reminder copyWith({
    String? id,
    String? ownerId,
    List<String>? contactIds,
    DateTime? startDateTime,
    DateTime? endDateTime,
    String? repeatFrequency,
    String? note,
    String? toDoAction,
    String? priority,
    bool? isCompleted,
  }) {
    return Reminder(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      contactIds: contactIds ?? this.contactIds,
      startDateTime: startDateTime ?? this.startDateTime,
      endDateTime: endDateTime ?? this.endDateTime,
      repeatFrequency: repeatFrequency ?? this.repeatFrequency,
      note: note ?? this.note,
      toDoAction: toDoAction ?? this.toDoAction,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
    );
  }
}
