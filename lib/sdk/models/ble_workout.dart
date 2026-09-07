/// Jieli workout record; timestamps are milliseconds, other values are SDK units.
class BleWorkout {
  BleWorkout.fromMap(Map<dynamic, dynamic> map)
    : startTimeMs = (map['startTimeMs'] as num).toInt(),
      endTimeMs = (map['endTimeMs'] as num).toInt(),
      type = (map['type'] as num).toInt(),
      step = (map['step'] as num).toInt(),
      distance = (map['distance'] as num).toInt(),
      calorie = (map['calorie'] as num).toInt(),
      duration = (map['duration'] as num).toInt(),
      bpm = (map['bpm'] as num).toInt();

  final int startTimeMs;
  final int endTimeMs;
  final int type;
  final int step;
  final int distance;
  final int calorie;
  final int duration;
  final int bpm;
}
