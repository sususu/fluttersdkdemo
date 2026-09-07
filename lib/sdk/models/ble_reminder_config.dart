/// Common readback fields for sedentary, drink-water and handwashing reminders.
class BleReminderConfig {
  BleReminderConfig.fromMap(Map<dynamic, dynamic> map)
    : isOn = map['isOn'] as bool,
      startHour = (map['startHour'] as num?)?.toInt(),
      startMinute = (map['startMinute'] as num?)?.toInt(),
      endHour = (map['endHour'] as num?)?.toInt(),
      endMinute = (map['endMinute'] as num?)?.toInt(),
      intervalSeconds = (map['intervalSeconds'] as num).toInt(),
      week = (map['week'] as num).toInt(),
      weekDescription = map['weekDescription'] as String,
      duration = (map['duration'] as num?)?.toInt();

  final bool isOn;
  final int? startHour;
  final int? startMinute;
  final int? endHour;
  final int? endMinute;
  final int intervalSeconds;
  final int week;
  final String weekDescription;

  /// Drink-water/handwashing SDK value, preserved without assuming its unit.
  final int? duration;
}
