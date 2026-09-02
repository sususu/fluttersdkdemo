import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../sdk/hw_ble_sdk.dart';
import '../sdk/models/ble_goal.dart';
import '../sdk/models/ble_goal_type.dart';

class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  State<GoalsPage> createState() => _GoalsPagetate();
}
class _GoalsPagetate extends State<GoalsPage> {
  final HwBleSdk _sdk = HwBleSdk.instance;
  bool _running = false;
  String _status = '点击下方按钮';
  BleGoal? _goal;

  Future<void> _readGoals() async {
    if (_running) return;
    setState(() {
      _running = true;
      _status = '读取目标中…';
      // Discard stale values while a new device read is in progress.
      _goal = null;
    });
    debugPrint('[GOALS][ENTER] read goals');

    try {
      if (!await _sdk.isConnected()) {
        debugPrint('[GOALS][RESULT] read goals failed: device disconnected');
        if (!mounted) return;
        setState(() => _status = '设备未连接');
        return;
      }

      final goal = await _sdk.getGoals();
      debugPrint(
        '[GOALS][RESULT] step=${goal.step} calorie=${goal.calorie} '
        'distance=${goal.distance} sleep=${goal.sleep} duration=${goal.duration} '
        'otDistance=${goal.otDistance} otDistanceMile=${goal.otDistanceMile}',
      );
      if (!mounted) return;
      setState(() {
        _goal = goal;
        _status = '读取目标完成';
      });
    } catch (error) {
      debugPrint('[GOALS][EXCEPTION] read goals failed: $error');
      if (!mounted) return;
      setState(() => _status = '读取目标失败: $error');
    } finally {
      if (!mounted) return;
      setState(() => _running = false);
      debugPrint('[GOALS][FINISH] read goals running=false');
    }
  }

  Future<void> _writeGoals() async {
    if (_running) return;
    setState(() {
      _running = true;
      _status = '写入目标中…';
      // Clear readback values because they no longer represent the pending device state.
      _goal = null;
    });
    debugPrint('[GOALS][ENTER] write goals');

    var currentGoal = '';
    var completed = 0;

    Future<void> writeGoal(BleGoalType type, int value, String label) async {
      if (!mounted) return;
      currentGoal = label;
      setState(() => _status = '写入目标中（${completed + 1}/5）：$label');
      debugPrint(
        '[GOALS][BRANCH] write index=${completed + 1}/5 '
        'type=$label value=$value',
      );
      await _sdk.setGoal(type, value);
      completed++;
      debugPrint(
        '[GOALS][RESULT] write success index=$completed/5 '
        'type=$label value=$value',
      );
    }

    try {
      if (!await _sdk.isConnected()) {
        debugPrint('[GOALS][RESULT] write goals failed: device disconnected');
        if (!mounted) return;
        setState(() => _status = '设备未连接');
        return;
      }

      await writeGoal(BleGoalType.step, 80, 'Step');
      if (!mounted) return;
      await writeGoal(BleGoalType.calorie, 400, 'Calorie');
      if (!mounted) return;
      await writeGoal(BleGoalType.distance, 5, 'Distance');
      if (!mounted) return;
      await writeGoal(BleGoalType.sleep, 8, 'Sleep');
      if (!mounted) return;
      await writeGoal(BleGoalType.duration, 30, 'Duration');
      if (!mounted) return;

      setState(() => _status = '写入目标完成');
      debugPrint('[GOALS][RESULT] write goals success completed=$completed/5');
    } catch (error) {
      debugPrint(
        '[GOALS][EXCEPTION] write goals failed '
        'type=$currentGoal completed=$completed/5 error=$error',
      );
      if (!mounted) return;
      setState(() => _status = '写入失败：$currentGoal，$error');
    } finally {
      if (!mounted) return;
      setState(() => _running = false);
      debugPrint('[GOALS][FINISH] write goals completed=$completed/5');
    }
  }
  Widget _buildGoalResult(ThemeData theme) {
    final goal = _goal;
    if (goal == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('结果', style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          Text('步数: ${goal.step * 100}（协议百步=${goal.step}）'),
          Text('卡路里: ${goal.calorie} 千卡'),
          Text('距离: ${goal.distance}（公里/英里）'),
          Text('睡眠: ${goal.sleep} 小时'),
          Text('时长: ${goal.duration} 分钟'),
          // Text('OT 距离: ${(goal.otDistance / 10).toStringAsFixed(1)} 公里'),
          // Text('OT 距离: ${(goal.otDistanceMile / 10).toStringAsFixed(1)} 英里'),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {


    final theme = Theme.of(context);
    return Scaffold(
        appBar: AppBar(title: const Text('目标设置')),
        body: Column(
            children: [
              Material(
                color: theme.colorScheme.surfaceContainerLow,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          if (_running)
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            Icon(
                              Icons.check_circle_outlined,
                              color: theme.colorScheme.primary,
                            ),
                          const SizedBox(width: 1),
                          Expanded(
                            child: Text(_status, style: theme.textTheme.titleSmall),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          FilledButton.tonal(
                            onPressed: _running ? null : _readGoals,
                            child: const Text('读取目标'),
                          ),
                          const SizedBox(height: 8),
                          FilledButton.tonal(
                            onPressed: _running ? null : _writeGoals,
                            child: const Text('写入目标'),
                          ),
                        ],
                      ),
                    ],
                  )
                ),
              ),
              if (_goal != null) _buildGoalResult(theme),
            ]
        )
    );
  }

}
