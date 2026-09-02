enum BleGoalType {
  step(0),
  calorie(1),
  distance(2),
  sleep(3),
  duration(4);

  const BleGoalType(this.value);

  final int value;
}