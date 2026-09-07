import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../sdk/sdk.dart';

class JieliHealthPage extends StatefulWidget {
  const JieliHealthPage({super.key});

  @override
  State<JieliHealthPage> createState() => _JieliHealthPageState();
}

class _JieliHealthPageState extends State<JieliHealthPage> {
  final _sdk = HwBleSdk.instance;
  bool _running = false;
  bool _confirmingDelete = false;
  String? _resultCategory;
  String _status = '连接杰理设备后，选择要读取的数据';
  List<(String, String)> _rows = const [];

  String _time(int timeMs) =>
      DateTime.fromMillisecondsSinceEpoch(timeMs).toString().split('.').first;

  Future<void> _read<T>(
    String label,
    Future<List<T>> Function() load,
    int Function(T) time,
    (String, String) Function(T) row, {
    String Function(List<T>)? summary,
  }) async {
    if (_running) return;
    setState(() {
      _running = true;
      _rows = const [];
      _resultCategory = null;
      _status = '正在读取杰理$label…';
    });
    try {
      if (!await _sdk.isConnected()) throw StateError('设备未连接，请先连接杰理设备');
      final items = await load();
      items.sort((a, b) => time(b).compareTo(time(a)));
      final rows = items.map(row).toList();
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _resultCategory = label;
        _status = items.isEmpty
            ? '读取完成，暂无$label'
            : '$label读取完成，共 ${items.length} 条${summary == null ? '' : '，${summary(items)}'}';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _status = error is MissingPluginException
            ? '当前平台尚未接入杰理$label接口'
            : '读取杰理$label失败：$error';
      });
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  Future<void> _delete(String label, Future<void> Function() remove) async {
    if (_running || _confirmingDelete) return;
    _confirmingDelete = true;
    bool? confirmed;
    try {
      confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('删除$label？'),
          content: Text('将清除手表上的全部$label，删除后无法恢复。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('确认删除'),
            ),
          ],
        ),
      );
    } finally {
      _confirmingDelete = false;
    }
    if (!mounted || confirmed != true || _running) return;
    setState(() {
      _running = true;
      _status = '正在删除$label…';
    });
    try {
      if (!await _sdk.isConnected()) throw StateError('设备未连接');
      if (!mounted) return;
      await remove();
      if (!mounted) return;
      setState(() {
        if (_resultCategory == label) {
          _rows = const [];
          _resultCategory = null;
        }
        _status = '$label删除完成，请重新读取确认';
      });
    } on MissingPluginException {
      if (!mounted) return;
      setState(() => _status = '原生删除接口未加载，请完全停止应用后重新运行；热重载或热重启不会更新 Swift。');
    } catch (error) {
      if (!mounted) return;
      setState(() => _status = '删除$label失败：$error');
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final actions = <(String, VoidCallback)>[
      (
        '读取活动',
        () => _read<BleActivity>(
          '活动数据',
          _sdk.getActivitiesV2,
          (a) => a.timeMs,
          (a) => (
            '步数：${a.step}  距离：${a.distance} 米',
            '卡路里：${a.calorie}  时长：${a.duration} 分钟\n'
                '平均心率：${a.avgBpm} bpm\n时间：${_time(a.timeMs)}',
          ),
          summary: (items) =>
              '步数合计 ${items.fold<int>(0, (sum, a) => sum + a.step)}',
        ),
      ),
      (
        '读取睡眠',
        () => _read<BleSleepPoint>(
          '睡眠',
          _sdk.getSleepPointsV2,
          (s) => s.timeMs,
          (s) => ('睡眠状态：${s.statusDescription}', '时间：${_time(s.timeMs)}'),
        ),
      ),
      (
        '读取心率',
        () => _read<BleHeartrate>(
          '心率',
          _sdk.getHeartratesV2,
          (h) => h.timeMs,
          (h) => ('心率：${h.bpm} bpm', '时间：${_time(h.timeMs)}'),
        ),
      ),
      (
        '读取血氧',
        () => _read<BleSpo2>(
          '血氧',
          _sdk.getSpo2sV2,
          (s) => s.timeMs,
          (s) => ('血氧：${s.spo2}%', '时间：${_time(s.timeMs)}'),
        ),
      ),
      (
        '读取压力',
        () => _read<BleStress>(
          '压力',
          _sdk.getStressesV2,
          (s) => s.timeMs,
          (s) => ('压力：${s.stress}', '时间：${_time(s.timeMs)}'),
        ),
      ),
      (
        '读取运动记录',
        () => _read<BleWorkout>(
          '运动记录',
          _sdk.getWorkoutsV2,
          (w) => w.startTimeMs,
          (w) => (
            '类型：${w.type}  步数：${w.step}  距离：${w.distance} 米',
            '卡路里：${w.calorie} kcal  时长：${w.duration}  心率：${w.bpm} bpm\n'
                '开始：${_time(w.startTimeMs)}\n结束：${_time(w.endTimeMs)}',
          ),
        ),
      ),
    ];
    final deletions = <(String, VoidCallback)>[
      ('删除睡眠', () => _delete('睡眠', _sdk.deleteSleeps)),
      ('删除心率', () => _delete('心率', _sdk.deleteHeartrates)),
      ('删除血氧', () => _delete('血氧', _sdk.deleteSpo2s)),
      ('删除压力', () => _delete('压力', _sdk.deleteStresses)),
      ('删除运动记录', () => _delete('运动记录', _sdk.deleteWorkouts)),
    ];
    final compactStyle = FilledButton.styleFrom(
      minimumSize: const Size(0, 36),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      textStyle: const TextStyle(fontSize: 13),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('杰理健康数据')),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 6,
                    children: [
                      for (final action in actions)
                        FilledButton.tonal(
                          style: compactStyle,
                          onPressed: _running ? null : action.$2,
                          child: Text(action.$1),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    children: [
                      for (final action in deletions)
                        OutlinedButton(
                          style: compactStyle.copyWith(
                            foregroundColor: WidgetStatePropertyAll(
                              Theme.of(context).colorScheme.error,
                            ),
                          ),
                          onPressed: _running ? null : action.$2,
                          child: Text(action.$1),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_running) const LinearProgressIndicator(),
                  const SizedBox(height: 8),
                  Text(_status),
                ],
              ),
            ),
          ),
          SliverList.builder(
            itemCount: _rows.length,
            itemBuilder: (context, index) => ListTile(
              title: Text('${index + 1}. ${_rows[index].$1}'),
              subtitle: Text(_rows[index].$2),
            ),
          ),
        ],
      ),
    );
  }
}
