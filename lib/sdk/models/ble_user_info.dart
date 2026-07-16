import 'ble_gender.dart';

class BleUserInfo {
  const BleUserInfo({
    this.id,
    required this.gender,
    required this.age,
    required this.height,
    required this.weight,
    this.birthdayYear,
    this.birthdayMonth,
    this.birthdayDay,
  });

  final String? id;
  final BleGender gender;
  final int age;
  final int height;
  final int weight;
  final int? birthdayYear;
  final int? birthdayMonth;
  final int? birthdayDay;

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'gender': gender.value,
        'age': age,
        'height': height,
        'weight': weight,
        if (birthdayYear != null) 'birthdayYear': birthdayYear,
        if (birthdayMonth != null) 'birthdayMonth': birthdayMonth,
        if (birthdayDay != null) 'birthdayDay': birthdayDay,
      };
}
