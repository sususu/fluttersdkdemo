import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sdkdemo/sdk/sdk.dart';

class AlbumTransferPage extends StatefulWidget {
  const AlbumTransferPage({super.key});
  @override
  State<AlbumTransferPage> createState() => _AlbumTransferPageState();
}

class _AlbumTransferPageState extends State<AlbumTransferPage> {
  final _sdk = HwBleSdk.instance;
  final _width = TextEditingController(text: '466');
  final _height = TextEditingController(text: '466');
  StreamSubscription<Map<String, dynamic>>? _events;
  String _status = '就绪';
  final _logs = <String>[];
  int _count = 0;
  bool _busy = false, _transferring = false, _cancelling = false;
  double _progress = 0;
  bool get _supported => defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    if (!_supported) return;
    _events = _sdk.albumTransferEvents().listen(
      (event) {
        if (!mounted || !_transferring) return;
        final phase = event['phase'];
        if (phase != 'preparing' && phase != 'transferring') return;
        setState(() {
          _progress = (event['progress'] as num).toDouble().clamp(0, 1);
          _status = phase == 'preparing'
              ? '正在准备照片…'
              : '推送中 ${(_progress * 100).toStringAsFixed(0)}%';
        });
      },
      onError: (Object error) {
        if (mounted) setState(() => _logs.add('进度监听失败：${_error(error)}'));
      },
    );
  }

  @override
  void dispose() {
    _events?.cancel();
    _width.dispose();
    _height.dispose();
    super.dispose();
  }

  String _error(Object error) => error is MissingPluginException
      ? '接口未加载，请停止 App 后重新运行'
      : error is PlatformException
      ? error.message ?? error.code
      : '$error';

  Future<void> _readIds() async {
    final ids = await _sdk.getAlbumFileIds();
    if (mounted)
      setState(
        () => _logs.add(ids.isEmpty ? '相册暂无照片' : '已用位置：${ids.join(', ')}'),
      );
  }

  Future<void> _query() async {
    if (_busy || !_supported) return;
    setState(() => _busy = true);
    try {
      await _readIds();
    } catch (error) {
      if (mounted) setState(() => _logs.add('查询失败：${_error(error)}'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pick() async {
    if (_busy || !_supported) return;
    setState(() => _busy = true);
    try {
      final count = await _sdk.pickAlbumImages();
      if (mounted && count != null)
        setState(() {
          _count = count;
          _status = '就绪';
          _logs.add('已选择 $count 张照片');
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
    if (_busy || _count == 0 || !_supported) return;
    final width = int.tryParse(_width.text.trim()) ?? 0;
    final height = int.tryParse(_height.text.trim()) ?? 0;
    if (width < 1 || width > 4096 || height < 1 || height > 4096) {
      setState(() => _status = '宽高须为 1–4096 像素');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _transferring = true;
      _progress = 0;
      _status = '正在准备照片…';
      _logs.add('目标尺寸：$width × $height');
    });
    try {
      await _sdk.pushAlbumSifli(width: width, height: height);
      if (!mounted) return;
      setState(() {
        _transferring = false;
        _progress = 1;
        _status = '相册推送成功';
        _logs.add('推送成功');
      });
      try {
        await _readIds();
      } catch (error) {
        if (mounted) setState(() => _logs.add('推送成功，位置刷新失败：${_error(error)}'));
      }
    } catch (error) {
      if (!mounted) return;
      final cancelled = error is PlatformException && error.code == 'CANCELLED';
      setState(() {
        _status = cancelled ? '已取消相册推送' : '相册推送失败';
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
      await _sdk.cancelAlbumTransfer();
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
    Widget dimension(String label, TextEditingController controller) =>
        Expanded(
          child: TextField(
            controller: controller,
            enabled: !_busy && _supported,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
        );
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
        appBar: AppBar(title: const Text('相册推送（思澈）')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            Text(_supported ? _status : '当前仅支持 iOS 思澈设备'),
            const SizedBox(height: 10),
            Text(_count == 0 ? '尚未选择照片' : '已选择 $_count 张照片'),
            const SizedBox(height: 10),
            const Text('目标尺寸（像素）'),
            const SizedBox(height: 8),
            Row(
              children: [
                dimension('宽度', _width),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('×'),
                ),
                dimension('高度', _height),
              ],
            ),
            const SizedBox(height: 10),
            button('查询已用位置', _busy || !_supported ? null : _query),
            button('选择照片', _busy || !_supported ? null : _pick),
            button(
              '开始推送',
              _busy || !_supported || _count == 0 ? null : _push,
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
