import 'dart:async';
import 'package:sdkdemo/pages/custom_watchface_editor.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sdkdemo/sdk/sdk.dart';

class WatchfacePage extends StatefulWidget {
  const WatchfacePage({super.key});
  @override
  State<WatchfacePage> createState() => _WatchfacePageState();
}

class _WatchfacePageState extends State<WatchfacePage> {
  final _sdk = HwBleSdk.instance;
  StreamSubscription<Map<String, dynamic>>? _events;
  List<Map<String, dynamic>> _items = [];
  final _logs = <String>[];
  String _status = '就绪';
  bool _busy = false, _installing = false, _cancelling = false;
  double _progress = 0;
  bool _custom = false, _customBusy = false;
  bool get _supported => defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    if (!_supported) return;
    _events = _sdk.watchfaceTransferEvents().listen(
      (event) {
        if (!mounted || !_installing) return;
        const labels = {
          'preparing': '正在准备…',
          'checking': '正在检查已安装表盘…',
          'switching': '正在切换表盘…',
          'downloading': '正在下载表盘…',
          'transferring': '正在安装表盘…',
        };
        final label = labels[event['phase']];
        if (label == null) return;
        setState(() {
          _status = label;
          _progress = (event['progress'] as num).toDouble().clamp(0, 1);
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

  Future<void> _refresh() async {
    if (_busy || !_supported) return;
    setState(() {
      _busy = true;
      _items = [];
      _status = '正在加载表盘…';
    });
    try {
      final items = await _sdk.getOnlineWatchfaces();
      if (mounted)
        setState(() {
          _items = items;
          _status = items.isEmpty ? '暂无可用表盘' : '共 ${items.length} 款表盘';
        });
    } catch (error) {
      if (mounted)
        setState(() {
          _status = '加载失败';
          _logs.add(_error(error));
        });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _choose(Map<String, dynamic> item) async {
    if (_busy) return;
    final install = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item['name'] as String,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text('${item['sizeKb']} KB'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('安装表盘'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
            ],
          ),
        ),
      ),
    );
    if (install != true || !mounted || _busy) return;
    setState(() {
      _busy = _installing = true;
      _progress = 0;
      _status = '正在准备…';
      _logs.add('选择表盘：${item['name']}');
    });
    try {
      await _sdk.installOnlineWatchface(item['id'] as String);
      if (mounted)
        setState(() {
          _installing = false;
          _progress = 1;
          _status = '表盘安装成功';
          _logs.add('已完成：${item['name']}');
        });
    } catch (error) {
      if (mounted)
        setState(() {
          _status = error is PlatformException && error.code == 'CANCELLED'
              ? '已取消安装'
              : '表盘安装失败';
          _logs.add(_error(error));
        });
    } finally {
      if (mounted)
        setState(() {
          _busy = _installing = _cancelling = false;
        });
    }
  }

  Future<void> _cancel() async {
    if (!_installing || _cancelling) return;
    setState(() => _cancelling = true);
    try {
      await _sdk.cancelWatchfaceTransfer();
    } catch (error) {
      if (mounted)
        setState(() {
          _cancelling = false;
          _logs.add('取消失败：${_error(error)}');
        });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy && !_customBusy,
    child: Scaffold(
      appBar: AppBar(title: const Text('表盘（思澈）')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('自定义')),
                  ButtonSegment(value: false, label: Text('在线')),
                ],
                selected: {_custom},
                onSelectionChanged: _busy || _customBusy
                    ? null
                    : (values) => setState(() => _custom = values.single),
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: _custom ? 1 : 0,
                children: [
                  _onlineBody(context),
                  CustomWatchfaceEditor(
                    active: _custom,
                    onBusyChanged: (value) =>
                        setState(() => _customBusy = value),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _onlineBody(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_supported ? _status : '当前仅支持 iOS 思澈设备'),
          const SizedBox(height: 8),
          FilledButton.tonal(
            onPressed: _supported && !_busy ? _refresh : null,
            child: const Text('刷新列表'),
          ),
          if (_installing) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(value: _progress),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${(_progress * 100).toStringAsFixed(0)}%'),
                TextButton(
                  onPressed: _cancelling ? null : _cancel,
                  child: Text(_cancelling ? '正在取消…' : '取消安装'),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              itemCount: _items.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.82,
              ),
              itemBuilder: (context, index) {
                final item = _items[index];
                final thumbnail = item['thumbnail'] as String;
                return Material(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: _busy ? null : () => _choose(item),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Column(
                        children: [
                          Expanded(
                            child: thumbnail.isEmpty
                                ? const Center(
                                    child: Icon(Icons.watch_outlined, size: 48),
                                  )
                                : Image.network(
                                    thumbnail,
                                    fit: BoxFit.contain,
                                    width: double.infinity,
                                    errorBuilder: (_, _, _) => const Center(
                                      child: Icon(
                                        Icons.broken_image_outlined,
                                        size: 40,
                                      ),
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['name'] as String,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 110,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              reverse: true,
              child: SelectableText(_logs.isEmpty ? '暂无日志' : _logs.join('\n')),
            ),
          ),
        ],
      ),
    ),
  );
}
