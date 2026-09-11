import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sdkdemo/sdk/sdk.dart';

class AiWatchfaceEditor extends StatefulWidget {
  const AiWatchfaceEditor({
    super.key,
    required this.active,
    required this.jieli,
    required this.onBusyChanged,
  });
  final bool active, jieli;
  final ValueChanged<bool> onBusyChanged;
  @override
  State<AiWatchfaceEditor> createState() => _AiWatchfaceEditorState();
}

class _AiWatchfaceEditorState extends State<AiWatchfaceEditor> {
  final _sdk = HwBleSdk.instance;
  final _fields = {
    'width': TextEditingController(text: '480'),
    'height': TextEditingController(text: '480'),
    'corner': TextEditingController(text: '240'),
    'thumbWidth': TextEditingController(text: '264'),
    'thumbHeight': TextEditingController(text: '264'),
    'thumbCorner': TextEditingController(text: '132'),
  };
  StreamSubscription<Map<String, dynamic>>? _events;
  bool _running = false, _sending = false, _command = false;
  int _style = 3;
  double _progress = 0;
  String _status = '启动后，请在手表上发起 AI 表盘生成', _deviceId = '';
  Uint8List? _image, _preview;
  final _logs = <String>[];
  bool get _supported => defaultTargetPlatform == TargetPlatform.iOS;
  bool get _busy => _command || _sending;
  @override
  void initState() {
    super.initState();
    if (!_supported) return;
    _events = _sdk.aiWatchfaceEvents().listen(
      (event) {
        if (!mounted || !widget.active) return;
        final wasBusy = _busy;
        setState(() {
          _running = event['running'] == true;
          _sending = event['installing'] == true;
          _progress = (event['progress'] as num? ?? 0).toDouble().clamp(0, 1);
          _deviceId = event['deviceId'] as String? ?? '';
          _image = event['resultImage'] as Uint8List?;
          _preview = event['previewImage'] as Uint8List?;
          final message = event['message'] as String? ?? '';
          if (message.isNotEmpty && message != _status) {
            _status = message;
            _logs.add(message);
            if (_logs.length > 100) _logs.removeAt(0);
          }
        });
        if (wasBusy != _busy) widget.onBusyChanged(_busy);
      },
      onError: (Object error) {
        if (mounted) setState(() => _status = _error(error));
      },
    );
  }

  @override
  void dispose() {
    if (_supported) unawaited(_sdk.stopAiWatchface().catchError((Object _) {}));
    _events?.cancel();
    for (final field in _fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  String _error(Object e) =>
      e is PlatformException ? e.message ?? e.code : '$e';
  Future<void> _run(bool start) async {
    if (_command) return;
    setState(() => _command = true);
    widget.onBusyChanged(true);
    try {
      await _sdk.stopAiWatchface();
      if (start) {
        await _sdk.startAiWatchface({
          'jieli': widget.jieli,
          'style': _style,
          for (final e in _fields.entries)
            e.key: int.tryParse(e.value.text) ?? -1,
        });
      }
    } catch (error) {
      if (mounted)
        setState(() {
          _status = _error(error);
          _logs.add(_status);
        });
    } finally {
      if (mounted) {
        setState(() => _command = false);
        widget.onBusyChanged(_busy);
      }
    }
  }

  void _preset(int index) {
    const sizes = [
      [480, 480, 240, 264, 264, 132],
      [466, 466, 233, 264, 264, 132],
      [410, 502, 108, 200, 244, 50],
    ];
    setState(() {
      var i = 0;
      for (final field in _fields.values) {
        field.text = '${sizes[index][i++]}';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget field(String key, String label) => Expanded(
      child: TextField(
        controller: _fields[key],
        enabled: _supported && !_busy,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
    Widget row(String a, String al, String b, String bl) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [field(a, al), const SizedBox(width: 8), field(b, bl)],
      ),
    );
    Widget picture(String label, Uint8List? bytes) => Column(
      children: [
        Text(label),
        SizedBox(
          height: 160,
          child: bytes == null
              ? const Center(child: Icon(Icons.image_outlined, size: 48))
              : Image.memory(bytes, fit: BoxFit.contain),
        ),
      ],
    );
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text(_supported ? _status : '当前仅支持 iOS 设备'),
        if (_deviceId.isNotEmpty) Text('设备 ID：$_deviceId'),
        Wrap(
          spacing: 8,
          children: [
            for (final (i, label) in ['480×480', '466×466', '410×502'].indexed)
              OutlinedButton(
                onPressed: _busy ? null : () => _preset(i),
                child: Text(label),
              ),
          ],
        ),
        row('width', '宽度', 'height', '高度'),
        row('corner', '圆角', 'thumbCorner', '缩略图圆角'),
        row('thumbWidth', '缩略图宽度', 'thumbHeight', '缩略图高度'),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 3, label: Text('动漫')),
            ButtonSegment(value: 9, label: Text('铅笔画')),
          ],
          selected: {_style},
          onSelectionChanged: _busy
              ? null
              : (v) => setState(() => _style = v.single),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: _supported && !_busy ? () => _run(true) : null,
                child: Text(_running ? '应用配置' : '启动 AI'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: _supported && !_command && _running
                    ? () => _run(false)
                    : null,
                child: const Text('停止 AI'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        picture('生成结果', _image),
        picture('表盘预览', _preview),
        if (_sending || _progress > 0) ...[
          LinearProgressIndicator(value: _progress),
          Text('${(_progress * 100).toStringAsFixed(0)}%'),
        ],
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
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
