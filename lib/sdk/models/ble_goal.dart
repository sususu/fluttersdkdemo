class BleGoal {
  const BleGoal({
    required this.step,
    required this.calorie,
    required this.distance,
    required this.sleep,
    required this.duration,
    required this.otDistance,
    required this.otDistanceMile,
  });

  final int step;
  final int calorie;
  final int distance;
  final int sleep;
  final int duration;
  final int otDistance;
  final int otDistanceMile;

  factory BleGoal.fromMap(Map<dynamic, dynamic> map) {
    return BleGoal(
      step: _intValue(map['step']),
      calorie: _intValue(map['calorie']),
      distance: _intValue(map['distance']),
      sleep: _intValue(map['sleep']),
      duration: _intValue(map['duration']),
      otDistance: _intValue(map['otDistance']),
      otDistanceMile: _intValue(map['otDistanceMile']),
    );
  }
}

int _intValue(Object? value) => value is num ? value.toInt() : 0;