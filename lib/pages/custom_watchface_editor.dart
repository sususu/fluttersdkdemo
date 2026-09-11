import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sdkdemo/sdk/sdk.dart';

class CustomWatchfaceEditor extends StatefulWidget {
  const CustomWatchfaceEditor({
    super.key,
    required this.active,
    this.jieli = false,
    required this.onBusyChanged,
  });
  final bool active;
  final bool jieli;
  final ValueChanged<bool> onBusyChanged;
  @override
  State<CustomWatchfaceEditor> createState() => _CustomWatchfaceEditorState();
}

class _CustomWatchfaceEditorState extends State<CustomWatchfaceEditor> {
  final _sdk = HwBleSdk.instance;
  final _fields = <String, TextEditingController>{
    'name': TextEditingController(text: 'custom'),
    'width': TextEditingController(text: '466'),
    'height': TextEditingController(text: '466'),
    'corner': TextEditingController(text: '233'),
    'thumbWidth': TextEditingController(text: '264'),
    'thumbHeight': TextEditingController(text: '264'),
    'thumbCorner': TextEditingController(text: '132'),
  };
  final _widgets = {
    'date': true,
    'week': true,
    'step': false,
    'weather': false,
    'pointer': false,
  };
  Uint8List? _background, _preview;
  final _backgrounds = <Uint8List>[];
  final _components = [1, 2, 3, 4];
  int _displayMode = 0, _pointerStyle = 0, _cover = 0;
  String _color = "FFFFFF";
  Timer? _debounce;
  StreamSubscription<Map<String, dynamic>>? _events;
  int _revision = 0;
  bool _busy = false, _pushing = false, _cancelling = false, _dirty = true;
  double _progress = 0;
  String _status = '就绪';
  final _logs = <String>[];
  bool get _supported => defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    if (!_supported) return;
    _events = _sdk.customWatchfaceEvents().listen(
      (event) {
        if (!mounted || !_pushing) return;
        if (![
          'preparing',
          'transferring',
          'configuring',
        ].contains(event['phase']))
          return;
        setState(() {
          _progress = (event['progress'] as num).toDouble().clamp(0, 1);
          _status = event['phase'] == 'configuring'
              ? '正在写入表盘配置…'
              : event['phase'] == 'preparing'
              ? '正在生成表盘…'
              : '正在推送表盘…';
        });
      },
      onError: (Object error) {
        if (mounted) setState(() => _logs.add('进度监听失败：${_error(error)}'));
      },
    );
    if (widget.active) _schedulePreview();
  }

  @override
  void didUpdateWidget(covariant CustomWatchfaceEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) _schedulePreview();
    if (!widget.active) {
      _debounce?.cancel();
      _revision++;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _events?.cancel();
    for (final field in _fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  String _error(Object error) => error is MissingPluginException
      ? '接口未加载，请停止 App 后重新运行'
      : error is PlatformException
      ? error.message ?? error.code
      : '$error';
  Map<String, dynamic> _config() => {
    for (final entry in _fields.entries)
      entry.key: entry.key == 'name'
          ? entry.value.text.trim()
          : int.tryParse(entry.value.text.trim()) ?? -1,
    ..._widgets,
    if (widget.jieli) ...{
      'jieli': true,
      'backgrounds': _backgrounds,
      'cover': _cover,
      'displayMode': _displayMode,
      'pointerStyle': _pointerStyle,
      'components': _components,
      'color': _color,
    },
    if (_background != null) 'background': _background,
  };
  void _schedulePreview() {
    if (!_supported || !widget.active || _busy) return;
    _debounce?.cancel();
    final revision = ++_revision;
    _dirty = true;
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      try {
        final png = await _sdk.previewCustomWatchface(_config());
        if (mounted && revision == _revision)
          setState(() {
            _preview = png;
            _dirty = false;
            _status = '就绪';
          });
      } catch (error) {
        if (mounted && revision == _revision)
          setState(() {
            _preview = null;
            _status = _error(error);
          });
      }
    });
  }

  void _setBusy(bool value) {
    setState(() => _busy = value);
    widget.onBusyChanged(value);
  }

  Future<void> _pick() async {
    if (_busy) return;
    _debounce?.cancel();
    _revision++;
    _setBusy(true);
    try {
      final image = await _sdk.pickCustomWatchfaceBackground();
      if (mounted && image != null)
        setState(() {
          if (widget.jieli) {
            _backgrounds.add(image);
          } else {
            _background = image;
          }
        });
    } catch (error) {
      if (mounted) setState(() => _logs.add(_error(error)));
    } finally {
      if (mounted) {
        _setBusy(false);
        _schedulePreview();
      }
    }
  }

  void _preset(int index) {
    const sizes = [
      [466, 466, 233, 264, 264, 132],
      [480, 480, 240, 264, 264, 132],
      [410, 502, 108, 200, 244, 50],
    ];
    const keys = [
      'width',
      'height',
      'corner',
      'thumbWidth',
      'thumbHeight',
      'thumbCorner',
    ];
    setState(() {
      for (var i = 0; i < keys.length; i++) {
        _fields[keys[i]]!.text = '${sizes[index][i]}';
      }
      _schedulePreview();
    });
  }

  Future<void> _push() async {
    if (_busy || _dirty || !_supported) return;
    FocusScope.of(context).unfocus();
    _debounce?.cancel();
    _revision++;
    _setBusy(true);
    setState(() {
      _pushing = true;
      _progress = 0;
      _status = '正在生成表盘…';
    });
    try {
      await _sdk.pushCustomWatchface(_config());
      if (mounted)
        setState(() {
          _pushing = false;
          _progress = 1;
          _status = '自定义表盘推送成功';
          _logs.add('推送成功');
        });
    } catch (error) {
      if (mounted)
        setState(() {
          _status = error is PlatformException && error.code == 'CANCELLED'
              ? '已取消推送'
              : '自定义表盘推送失败';
          _logs.add(_error(error));
        });
    } finally {
      if (mounted) {
        setState(() {
          _pushing = _cancelling = false;
        });
        _setBusy(false);
      }
    }
  }

  Future<void> _cancel() async {
    if (!_pushing || _cancelling) return;
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

  List<Widget> _jieliOptions() {
    Widget choice(
      String label,
      List<String> labels,
      int selected,
      ValueChanged<int> change,
    ) => DropdownButtonFormField<int>(
      initialValue: selected,
      decoration: InputDecoration(labelText: label),
      items: [
        for (var i = 0; i < labels.length; i++)
          DropdownMenuItem(value: i, child: Text(labels[i])),
      ],
      onChanged: _busy
          ? null
          : (value) => setState(() {
              change(value!);
              _schedulePreview();
            }),
    );
    return [
      choice(
        '显示模式',
        ['单张', '顺序轮播', '随机轮播'],
        _displayMode,
        (v) => _displayMode = v,
      ),
      choice(
        '指针样式',
        ['无', '样式 1', '样式 2', '样式 3'],
        _pointerStyle,
        (v) => _pointerStyle = v,
      ),
      TextFormField(
        initialValue: _color,
        enabled: !_busy,
        maxLength: 6,
        decoration: const InputDecoration(labelText: '颜色（RGB）'),
        onChanged: (v) => setState(() {
          _color = v;
          _schedulePreview();
        }),
      ),
      for (var i = 0; i < 4; i++)
        choice(
          '组件 ${i + 1}',
          ['关闭', '时间', '心率', '步数', '热量', '电量', '天气', '距离', '日期'],
          _components[i],
          (v) => _components[i] = v,
        ),
      if (_backgrounds.isNotEmpty)
        Wrap(
          spacing: 8,
          children: [
            for (var i = 0; i < _backgrounds.length; i++)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: _busy
                        ? null
                        : () => setState(() {
                            _cover = i;
                            _schedulePreview();
                          }),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _cover == i
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Image.memory(
                        _backgrounds[i],
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                            _backgrounds.removeAt(i);
                            _cover = 0;
                            _schedulePreview();
                          }),
                    child: Text('删除 ${i + 1}'),
                  ),
                ],
              ),
          ],
        ),
      const Text('点选背景设为封面；预览为布局示意。'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    Widget field(String key, String label) => Expanded(
      child: TextField(
        key: ValueKey('custom_$key'),
        controller: _fields[key],
        enabled: !_busy && _supported,
        keyboardType: key == 'name' ? TextInputType.text : TextInputType.number,
        inputFormatters: key == 'name'
            ? null
            : [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: const OutlineInputBorder(),
        ),
        onChanged: (_) => setState(_schedulePreview),
      ),
    );
    Widget row(String a, String al, String b, String bl) =>
        Row(children: [field(a, al), const SizedBox(width: 8), field(b, bl)]);
    return ListView(
      padding: const EdgeInsets.all(12),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        Text(_supported ? _status : '当前仅支持 iOS 设备'),
        const SizedBox(height: 8),
        SizedBox(
          height: 220,
          child: _preview == null
              ? const Center(child: Icon(Icons.watch_outlined, size: 64))
              : Image.memory(
                  _preview!,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final (index, label) in [
              '466×466',
              '480×480',
              '410×502',
            ].indexed)
              OutlinedButton(
                onPressed: _busy || !_supported ? null : () => _preset(index),
                child: Text(label),
              ),
          ],
        ),
        const SizedBox(height: 8),
        row('width', '宽度', 'height', '高度'),
        const SizedBox(height: 10),
        widget.jieli
            ? Row(children: [field('corner', '圆角'), const Spacer()])
            : row('corner', '圆角', 'name', '表盘名称'),
        const SizedBox(height: 10),
        row('thumbWidth', '缩略图宽度', 'thumbHeight', '缩略图高度'),
        const SizedBox(height: 10),
        Row(children: [field('thumbCorner', '缩略图圆角'), const Spacer()]),
        const SizedBox(height: 6),
        if (widget.jieli) ..._jieliOptions(),
        if (!widget.jieli)
          for (final entry in {
            'date': '日期',
            'week': '星期',
            'step': '步数',
            'weather': '天气',
            'pointer': '指针',
          }.entries)
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(entry.value),
              value: _widgets[entry.key]!,
              onChanged: _busy || !_supported
                  ? null
                  : (value) => setState(() {
                      _widgets[entry.key] = value;
                      _schedulePreview();
                    }),
            ),
        Row(
          children: [
            Expanded(
              child: FilledButton.tonal(
                onPressed:
                    _busy ||
                        !_supported ||
                        (widget.jieli && _backgrounds.length >= 8)
                    ? null
                    : _pick,
                child: Text(
                  widget.jieli ? '添加背景（${_backgrounds.length}/8）' : '选择背景图',
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.tonal(
                onPressed:
                    _busy ||
                        (widget.jieli
                            ? _backgrounds.isEmpty
                            : _background == null)
                    ? null
                    : () => setState(() {
                        _background = null;
                        _backgrounds.clear();
                        _cover = 0;
                        _schedulePreview();
                      }),
                child: const Text('清除背景'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: _busy || _dirty || !_supported ? null : _push,
          child: const Text('推送自定义表盘'),
        ),
        if (_pushing) ...[
          LinearProgressIndicator(value: _progress),
          Text('${(_progress * 100).toStringAsFixed(0)}%'),
          TextButton(
            onPressed: _cancelling ? null : _cancel,
            child: Text(_cancelling ? '正在取消…' : '取消推送'),
          ),
        ],
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          constraints: const BoxConstraints(minHeight: 100),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(8),
          ),
          child: SelectableText(_logs.isEmpty ? '暂无日志' : _logs.join('\n')),
        ),
      ],
    );
  }
}
