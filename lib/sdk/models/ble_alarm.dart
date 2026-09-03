class BleAlarm {
  const BleAlarm({
    required this.id,
    required this.hour,
    required this.minute,
    required this.isOn,
    required this.content,
    required this.week,
    required this.weekDescription,
    required this.snooze,
  });

  final int id;
  final int? hour;
  final int? minute;
  final bool isOn;
  final String content;
  final int week;
  final String weekDescription;
  final int snooze;

  factory BleAlarm.fromMap(Map<dynamic, dynamic> map) {
    return BleAlarm(
      id: _intValue(map['id']),
      hour: _nullableIntValue(map['hour']),
      minute: _nullableIntValue(map['minute']),
      isOn: map['isOn'] as bool? ?? false,
      content: map['content'] as String? ?? '',
      week: _intValue(map['week']),
      weekDescription: map['weekDescription'] as String? ?? '',
      snooze: _intValue(map['snooze']),
    );
  }
}

int _intValue(dynamic value) => value is num ? value.toInt() : 0;

int? _nullableIntValue(dynamic value) => value is num ? value.toInt() : null;
