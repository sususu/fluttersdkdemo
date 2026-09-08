class BleNotificationSwitch {
  const BleNotificationSwitch({required this.type, required this.enabled});
  // Native adapters must map platform-specific identifiers to these SDK type codes.
  final int type;
  final bool enabled;
  factory BleNotificationSwitch.fromMap(Map map) => BleNotificationSwitch(
    type: (map['type'] as num).toInt(),
    enabled: map['enabled'] as bool,
  );
  String get name =>
      const {
        0: '未接来电',
        1: '短信',
        2: '社交消息',
        3: '邮件',
        4: '日历',
        5: '来电',
        6: '来电挂断',
        7: '微信',
        8: 'Viber',
        9: 'Snapchat',
        10: 'WhatsApp',
        11: 'QQ',
        12: 'Facebook',
        14: 'Gmail',
        15: 'Messenger',
        16: 'Instagram',
        17: 'Twitter',
        20: 'Line',
        21: 'Skype',
        26: 'Telegram',
        49: '其他',
        84: '微博',
        87: 'TikTok',
        93: '钉钉',
        103: '小红书',
      }[type] ??
      '通知类型 $type';
}

class BleContact {
  const BleContact({required this.name, required this.phone});
  final String name;
  final String phone;
  Map<String, String> toMap() => {'name': name.trim(), 'phone': phone.trim()};
}
