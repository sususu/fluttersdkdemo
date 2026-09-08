import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sdkdemo/sdk/sdk.dart';

class MusicTransferPage extends StatefulWidget {
  const MusicTransferPage({super.key});
  @override
  State<MusicTransferPage> createState() => _MusicTransferPageState();
}

class _MusicTransferPageState extends State<MusicTransferPage> {
  final _sdk = HwBleSdk.instance;
  StreamSubscription<Map<String, dynamic>>? _events;
  String _status = '就绪';
  String _storage = '—';
  final _logs = <String>[];
  List<Map<String, dynamic>> _files = [];
  bool _busy = false;
  bool _transferring = false;
  bool _cancelling = false;
  double _progress = 0;
  bool get _supported => defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    if (!_supported) return;
    _events = _sdk.musicTransferEvents().listen(
      (event) {
        if (!mounted || !_transferring) return;
        final phase = event['phase'];
        if (phase != 'preparing' && phase != 'transferring') return;
        setState(() {
          _progress = (event['progress'] as num).toDouble().clamp(0, 1);
          _status = phase == 'preparing'
              ? '正在准备音乐…'
              : '推送中 ${(_progress * 100).toStringAsFixed(0)}%';
        });
      },
      onError: (Object error) {
        if (mounted) setState(() => _logs.add('进度监听失败：$error'));
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

  Future<void> _storageResult() async {
    final data = await _sdk.getMusicStorage();
    if (!mounted) return;
    setState(() {
      _storage =
          '可用 ${(data['availableKb']! / 1024).toStringAsFixed(2)} MB / 总计 ${(data['totalKb']! / 1024).toStringAsFixed(2)} MB';
    });
  }

  Future<void> _refresh() async {
    if (_busy || !_supported) return;
    setState(() => _busy = true);
    try {
      await _storageResult();
      if (mounted) setState(() => _logs.add('容量查询成功'));
    } catch (error) {
      if (mounted)
        setState(() {
          _storage = '容量查询失败';
          _logs.add(_error(error));
        });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pick() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final files = await _sdk.pickMusicFiles();
      if (mounted && files != null)
        setState(() {
          _files = files;
          _status = '已选择 ${files.length} 首音乐';
          _logs.addAll(
            files.map(
              (f) =>
                  '${f['name']}（${((f['sizeBytes'] as num) / 1024 / 1024).toStringAsFixed(2)} MB）',
            ),
          );
        });
    } catch (error) {
      if (mounted)
        setState(() {
          _status = '选择失败';
          _logs.add(_error(error));
        });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _push() async {
    if (_busy || _files.isEmpty) return;
    setState(() {
      _busy = true;
      _transferring = true;
      _progress = 0;
      _status = '正在准备音乐…';
    });
    try {
      await _sdk.pushMusicSifli();
      if (!mounted) return;
      setState(() {
        _transferring = false;
        _progress = 1;
        _status = '音乐推送成功';
        _logs.add('推送成功');
      });
      try {
        await _storageResult();
      } catch (error) {
        if (mounted) setState(() => _logs.add('推送成功，容量刷新失败：${_error(error)}'));
      }
    } catch (error) {
      if (!mounted) return;
      final cancelled = error is PlatformException && error.code == 'CANCELLED';
      setState(() {
        _status = cancelled ? '已取消音乐推送' : '音乐推送失败';
        _logs.add(_error(error));
      });
    } finally {
      if (mounted)
        setState(() {
          _busy = false;
          _transferring = false;
          _cancelling = false;
        });
    }
  }

  Future<void> _cancel() async {
    if (!_transferring || _cancelling) return;
    setState(() => _cancelling = true);
    try {
      await _sdk.cancelMusicTransfer();
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
        appBar: AppBar(title: const Text('音乐推送（思澈）')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(_supported ? _status : '当前仅支持 iOS 思澈设备'),
            const SizedBox(height: 10),
            Text(_storage),
            const SizedBox(height: 10),
            button('查询音乐容量', _busy || !_supported ? null : _refresh),
            button('选择 MP3 文件', _busy || !_supported ? null : _pick),
            button(
              '开始推送',
              _busy || !_supported || _files.isEmpty ? null : _push,
              primary: true,
            ),
            button('取消推送', !_transferring || _cancelling ? null : _cancel),
            LinearProgressIndicator(value: _progress),
            const SizedBox(height: 10),
            Container(
              constraints: const BoxConstraints(minHeight: 180),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _logs.join('\n'),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
