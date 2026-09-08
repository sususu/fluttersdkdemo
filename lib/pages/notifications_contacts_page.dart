import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sdkdemo/sdk/sdk.dart';

class NotificationsContactsPage extends StatefulWidget {
  const NotificationsContactsPage({super.key});

  @override
  State<NotificationsContactsPage> createState() =>
      _NotificationsContactsPageState();
}

class _NotificationsContactsPageState extends State<NotificationsContactsPage> {
  final _sdk = HwBleSdk.instance;
  bool _busy = false;
  String _status = '就绪';
  String _result = '';
  bool get _supported => defaultTargetPlatform == TargetPlatform.iOS;

  Future<void> _run(String label, Future<String> Function() action) async {
    if (_busy || !_supported) return;
    setState(() {
      _busy = true;
      _status = '$label…';
      _result = '';
    });
    try {
      if (!await _sdk.isConnected()) throw StateError('请先连接手表');
      if (!mounted) return;
      final message = await action();
      if (!mounted) return;
      setState(() {
        _status = '成功';
        _result = message;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _status = '失败';
        _result = error is MissingPluginException
            ? '原生接口未加载，请停止 App 后重新运行。'
            : '$error';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String> _read() async {
    final switches = await _sdk.getSocialSwitches();
    final enabled = switches.where((item) => item.enabled);
    return enabled.isEmpty
        ? '暂无已开启的通知开关'
        : enabled
              .map((item) => 'type=${item.type} on=${item.enabled}')
              .join('\n');
  }

  Future<String> _enableDemo() async {
    // 微信 → 短信 → 来电，失败即停止后续写入。
    for (final item in const [(7, '微信'), (1, '短信'), (5, '来电')]) {
      try {
        await _sdk.setSocialSwitch(item.$1, true);
      } catch (error) {
        throw StateError('${item.$2}设置失败，前面已成功的设置保留：$error');
      }
    }
    return '已开启微信、短信、来电通知；可点击获取通知开关核对';
  }

  Widget _button(String title, Future<String> Function() action) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        minimumSize: const Size.fromHeight(44),
        padding: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      onPressed: _busy || !_supported ? null : () => _run(title, action),
      child: Text(title),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('通知 / 通讯录')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text(
          _supported ? _status : '当前页面仅接入 iOS，Android 原生接口待适配。',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        _button('获取通知开关', _read),
        _button('开启 Demo 通知开关', _enableDemo),
        _button('设置 Demo 通讯录', () async {
          await _sdk.setContacts(const [
            BleContact(name: 'Demo A', phone: '10086'),
            BleContact(name: 'Demo B', phone: '10010'),
          ]);
          return '通讯录设置成功：Demo A / 10086，Demo B / 10010';
        }),
        _button('设置紧急联系人', () async {
          await _sdk.setEmergencyContact(
            const BleContact(name: 'Emergency', phone: '120'),
          );
          return '紧急联系人设置成功：Emergency / 120';
        }),
        const SizedBox(height: 4),
        Text(
          _result,
          key: const Key('notifyResult'),
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}
