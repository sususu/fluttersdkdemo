import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sdkdemo/sdk/sdk.dart';

class OtaUpgradePage extends StatefulWidget {
  const OtaUpgradePage({super.key});
  @override
  State<OtaUpgradePage> createState() => _OtaUpgradePageState();
}

class _OtaUpgradePageState extends State<OtaUpgradePage> {
  final _sdk = HwBleSdk.instance;
  StreamSubscription<Map<String, dynamic>>? _events;
  Map<String, dynamic> _info = {};
  final _logs = <String>[];
  String _status = '就绪';
  double _progress = 0;
  bool _busy = false, _updating = false, _cancelling = false;
  bool get _supported => defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    if (!_supported) return;
    _events = _sdk.otaEvents().listen(
      (event) {
        if (!mounted || !_updating) return;
        if (![
          'preparing',
          'downloading',
          'transferring',
        ].contains(event['phase']))
          return;
        setState(() {
          _progress = (event['progress'] as num).toDouble().clamp(0, 1);
          _status = event['message'] as String? ?? '正在升级…';
        });
      },
      onError: (Object error) {
        if (mounted) setState(() => _logs.add('进度监听失败：${_error(error)}'));
      },
    );
    _query(false);
  }

  @override
  void dispose() {
    _events?.cancel();
    super.dispose();
  }

  String _error(Object error) => error is MissingPluginException
      ? '接口未加载，请停止 App 后重新运行'
      : error is PlatformException
      ? error.message ?? error.code
      : '$error';

  Future<void> _query(bool check) async {
    if (_busy || !_supported) return;
    setState(() {
      _busy = true;
      _info = {..._info, 'available': false};
      _status = check ? '正在检查更新…' : '正在刷新设备信息…';
    });
    try {
      final info = check ? await _sdk.checkOta() : await _sdk.refreshOtaInfo();
      if (!mounted) return;
      setState(() {
        _info = info;
        _status = check
            ? (info['available'] == true ? '发现新版本' : '暂无可用更新')
            : '设备信息已刷新';
      });
    } catch (error) {
      if (mounted)
        setState(() {
          _status = '查询失败';
          _logs.add(_error(error));
        });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _start() async {
    if (_busy || !_supported || _info['available'] != true) return;
    setState(() {
      _busy = _updating = true;
      _progress = 0;
      _status = '正在准备升级…';
    });
    try {
      await _sdk.startOta();
      if (!mounted) return;
      setState(() {
        _updating = false;
        _progress = 1;
        _status = 'OTA 升级完成';
        _logs.add('升级完成，请等待手表重启，返回首页连接后刷新固件版本。');
      });
    } catch (error) {
      if (mounted)
        setState(() {
          _status = error is PlatformException && error.code == 'CANCELLED'
              ? '已取消升级'
              : 'OTA 升级失败';
          _logs.add(_error(error));
        });
    } finally {
      if (mounted)
        setState(() {
          _busy = _updating = _cancelling = false;
          _info = {..._info, 'available': false};
        });
    }
  }

  Future<void> _cancel() async {
    if (!_updating || _cancelling) return;
    setState(() => _cancelling = true);
    try {
      await _sdk.cancelOta();
    } catch (error) {
      if (mounted)
        setState(() {
          _cancelling = false;
          _logs.add('取消失败：${_error(error)}');
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget button(String label, VoidCallback? action, {bool primary = false}) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              backgroundColor: primary
                  ? null
                  : Theme.of(context).colorScheme.surfaceContainerLow,
              foregroundColor: primary
                  ? null
                  : Theme.of(context).colorScheme.onSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: action,
            child: Text(label),
          ),
        );
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(title: const Text('OTA 升级（思澈）')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(_supported ? _status : '当前仅支持 iOS 思澈设备'),
            const SizedBox(height: 12),
            Text('MAC：${_info['mac'] ?? '—'}'),
            Text('当前固件：${_info['firmware'] ?? '—'}'),
            if (_info['available'] == true) ...[
              Text('新版本：${_info['version']}（${_info['build']}）'),
              Text(_info['content'] as String? ?? ''),
            ],
            const SizedBox(height: 16),
            button('刷新设备信息', _supported && !_busy ? () => _query(false) : null),
            button('检查更新', _supported && !_busy ? () => _query(true) : null),
            button(
              '开始升级',
              _supported && !_busy && _info['available'] == true
                  ? _start
                  : null,
              primary: true,
            ),
            button(
              _cancelling ? '正在取消…' : '取消升级',
              _updating && !_cancelling ? _cancel : null,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: _progress),
            const SizedBox(height: 8),
            Text('${(_progress * 100).toStringAsFixed(0)}%'),
            const SizedBox(height: 16),
            Container(
              constraints: const BoxConstraints(minHeight: 180),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: SelectableText(_logs.isEmpty ? '暂无日志' : _logs.join('\n')),
            ),
          ],
        ),
      ),
    );
  }
}
