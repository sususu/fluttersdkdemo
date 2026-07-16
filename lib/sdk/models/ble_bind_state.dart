enum BleBindState {
  none(0),
  done(1),
  ota(0x81);

  const BleBindState(this.value);
  final int value;

  static BleBindState fromValue(int value) {
    if (value == 0x81) return BleBindState.ota;
    return BleBindState.values.firstWhere(
      (e) => e.value == value,
      orElse: () => BleBindState.none,
    );
  }
}
