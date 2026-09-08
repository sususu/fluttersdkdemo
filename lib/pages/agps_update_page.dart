import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sdkdemo/sdk/sdk.dart';

class AgpsUpdatePage extends StatefulWidget {
  const AgpsUpdatePage({super.key});
  @override
  State<AgpsUpdatePage> createState() => _AgpsUpdatePageState();
}

class _AgpsUpdatePageState extends State<AgpsUpdatePage> {
  final _sdk = HwBleSdk.instance;
  StreamSubscription<Map<String, dynamic>>? _events;
  Map<String, dynamic> _gps = {};
  final _logs = <String>[];
  String _status = '就绪';
  double _progress = 0;
  bool _busy = false, _updating = false, _cancelling = false;
  bool get _supported => defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    if (!_supported) return;
    _events = _sdk.agpsUpdateEvents().listen(
      (event) {
        if (!mounted || !_updating) return;
        final phase = event['phase'];
        if (phase != 'preparing' && phase != 'transferring') return;
        setState(() {
          _progress = (event['progress'] as num).toDouble().clamp(0, 1);
          _status = phase == 'preparing' ? '正在下载并准备星历…' : '正在更新星历…';
        });
      },
      onError: (Object error) {
        if (mounted) setState(() => _logs.add('进度监听失败：${_error(error)}'));
      },
    );
    _refresh();
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

  String _date(dynamic value) {
    final millis = (value as num?)?.toInt() ?? 0;
    if (millis <= 0) return '未知';
    return DateTime.fromMillisecondsSinceEpoch(
      millis,
    ).toLocal().toString().split('.').first;
  }

  Future<void> _readStatus() async {
    final gps = await _sdk.getDeviceGpsStatus();
    if (mounted) setState(() => _gps = gps);
  }

  Future<void> _refresh() async {
    if (_busy || !_supported) return;
    setState(() => _busy = true);
    try {
      await _readStatus();
    } catch (error) {
      if (mounted) setState(() => _logs.add('状态查询失败：${_error(error)}'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _update() async {
    if (_busy || !_supported) return;
    setState(() {
      _busy = _updating = true;
      _progress = 0;
      _status = '正在下载并准备星历…';
    });
    try {
      await _sdk.updateAgps();
      if (!mounted) return;
      setState(() {
        _updating = false;
        _progress = 1;
        _status = 'AGPS 更新成功';
        _logs.add('更新成功');
      });
      try {
        await _readStatus();
      } catch (error) {
        if (mounted) setState(() => _logs.add('更新成功，状态刷新失败：${_error(error)}'));
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _status = error is PlatformException && error.code == 'CANCELLED'
            ? '已取消更新'
            : 'AGPS 更新失败';
        _logs.add(_error(error));
      });
    } finally {
      if (mounted)
        setState(() {
          _busy = _updating = _cancelling = false;
        });
    }
  }

  Future<void> _cancel() async {
    if (!_updating || _cancelling) return;
    setState(() => _cancelling = true);
    try {
      await _sdk.cancelAgpsUpdate();
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
        appBar: AppBar(title: const Text('AGPS 更新（思澈）')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(_supported ? _status : '当前仅支持 iOS 思澈设备'),
            const SizedBox(height: 12),
            Text(
              'GPS 芯片：${_gps['gpsClipType'] == null || _gps['gpsClipType'] == '' ? '未知' : _gps['gpsClipType']}',
            ),
            Text(
              'GPS 固件：${_gps['gpsFirmwareVersion'] ?? '未知'}（${_gps['gpsFirmwareBuild'] ?? '—'}）',
            ),
            Text(
              '有效期：${_date(_gps['agpsValidStartTimeMs'])}\n至 ${_date(_gps['agpsValidEndTimeMs'])}',
            ),
            const SizedBox(height: 16),
            button('刷新状态', _supported && !_busy ? _refresh : null),
            button(
              '开始更新',
              _supported && !_busy ? _update : null,
              primary: true,
            ),
            button(
              _cancelling ? '正在取消…' : '取消更新',
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
