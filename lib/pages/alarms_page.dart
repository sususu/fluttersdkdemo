import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../sdk/hw_ble_sdk.dart';
import '../sdk/models/ble_alarm.dart';


class AlarmsPage extends StatefulWidget {
  const AlarmsPage({super.key});

  @override
  State<AlarmsPage> createState() => _AlarmsPagetate();
}

class _AlarmsPagetate extends State<AlarmsPage> {
  final HwBleSdk _sdk = HwBleSdk.instance;
  bool _running = false;
  String _status = '点击下方按钮';
  List<BleAlarm>? _alarms;

  Widget _buildAlarmResult(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 80,
              child: Text('结果', style:  theme.textTheme.titleSmall)
           ),
          const SizedBox(height: 4),
          if (_alarms != null && _alarms!.isEmpty)
            const Text('暂无闹钟')
          else if (_alarms != null)
            ..._alarms!.map((alarm) {
              final time = alarm.hour == null || alarm.minute == null
                  ? '--:--'
                  : '${alarm.hour!.toString().padLeft(2, '0')}:'
                      '${alarm.minute!.toString().padLeft(2, '0')}';
              return Text(
                '#${alarm.id} $time on=${alarm.isOn} ${alarm.content} week=${alarm.weekDescription}',
              );
            }),
        ],
      ),
    );
  }

  Future<void> _readAlarms() async {
    debugPrint('[ALARMS][ENTER] action=readAlarms');
    setState(() {
      _running = true;
      _status = '正在读取闹钟…';
      _alarms = null;
    });

    try {
      if (!await _sdk.isConnected()) {
        throw StateError('设备未连接');
      }
      final alarms = await _sdk.getAlarms();
      debugPrint(
        '[ALARMS][RESULT] action=readAlarms success=true count=${alarms.length}',
      );
      if (!mounted) return;
      setState(() {
        _alarms = alarms;
        _status = '读取闹钟完成，共 ${alarms.length} 个';
      });
    } catch (error, stackTrace) {
      debugPrint('[ALARMS][EXCEPTION] action=readAlarms error=$error');
      if (!mounted) return;
      setState(() {
        _status = '读取闹钟失败：$error';
      });
    } finally {
      if (mounted) {
        setState(() => _running = false);
      }
    }
  }

  Future<void> _addDemoAlarm() async {
    debugPrint('[ALARMS][ENTER] action=addDemoAlarm hour=7 minute=30');
    setState(() {
      _running = true;
      _status = '正在添加示例闹钟…';
      _alarms = null;
    });

    try {
      if (!await _sdk.isConnected()) {
        throw StateError('设备未连接');
      }
      await _sdk.addDemoAlarm();
      debugPrint('[ALARMS][RESULT] action=addDemoAlarm success=true');
      if (!mounted) return;
      setState(() {
        _status = '添加示例闹钟完成';
      });
    } catch (error) {
      debugPrint('[ALARMS][EXCEPTION] action=addDemoAlarm error=$error');
      if (!mounted) return;
      setState(() {
        _status = '添加示例闹钟失败：$error';
      });
    } finally {
      if (mounted) {
        setState(() => _running = false);
      }
    }
  }
  Future<void> _addJLAlarm() async {
    debugPrint('[ALARMS][ENTER] action=addJlDemoAlarm hour=7 minute=30');
    setState(() {
      _running = true;
      _status = '正在添加杰理示例闹钟…';
      _alarms = null;
    });

    try {
      if (!await _sdk.isConnected()) {
        throw StateError('设备未连接');
      }
      final alarmId = await _sdk.addJlDemoAlarm();
      debugPrint(
        '[ALARMS][RESULT] action=addJlDemoAlarm success=true id=$alarmId',
      );
      if (!mounted) return;
      setState(() {
        _status = '添加杰理示例闹钟完成 #$alarmId';
      });
    } on PlatformException catch (error) {
      debugPrint(
        '[ALARMS][RESULT] action=addJlDemoAlarm success=false '
        'code=${error.code} message=${error.message} details=${error.details}',
      );
      if (!mounted) return;
      setState(() {
        _status = error.code == 'JL_ALARM_ID_UNAVAILABLE'
            ? '杰理闹钟已达到最大数量（最多 5 个）'
            : '添加杰理示例闹钟失败：[${error.code}] ${error.message ?? ''}';
      });
    } catch (error) {
      debugPrint('[ALARMS][EXCEPTION] action=addJlDemoAlarm error=$error');
      if (!mounted) return;
      setState(() {
        _status = '添加杰理示例闹钟失败：$error';
      });
    } finally {
      if (mounted) {
        setState(() => _running = false);
      }
    }
  }

  Future<void> _deleteAllAlarms() async {
    debugPrint('[ALARMS][ENTER] action=deleteAllAlarms');
    setState(() {
      _running = true;
      _status = '正在删除全部闹钟…';
    });

    try {
      if (!await _sdk.isConnected()) {
        throw StateError('设备未连接');
      }
      await _sdk.deleteAllAlarms();
      debugPrint('[ALARMS][RESULT] action=deleteAllAlarms success=true');
      if (!mounted) return;
      setState(() {
        _alarms = const [];
        _status = '删除全部闹钟完成';
      });
    } on PlatformException catch (error) {
      debugPrint(
        '[ALARMS][RESULT] action=deleteAllAlarms success=false '
        'code=${error.code} message=${error.message} details=${error.details}',
      );
      if (!mounted) return;
      setState(() {
        _status = '删除全部闹钟失败：[${error.code}] ${error.message ?? ''}';
      });
    } catch (error) {
      debugPrint('[ALARMS][EXCEPTION] action=deleteAllAlarms error=$error');
      if (!mounted) return;
      setState(() {
        _status = '删除全部闹钟失败：$error';
      });
    } finally {
      if (mounted) {
        setState(() => _running = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('闹钟与提醒')),
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
                        onPressed: _running ? null : _readAlarms,
                        child: const Text('读取闹钟'),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.tonal(
                        onPressed: _running ? null : _addDemoAlarm,
                        child: const Text('添加示例闹钟（工作日 07:30）'),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.tonal(
                        onPressed: _running ? null : _addJLAlarm,
                        child: const Text('添加示例闹钟（工作日 07:30）（杰理）'),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.tonal(
                        onPressed: _running ? null : _deleteAllAlarms,
                        child: const Text('删除全部闹钟'),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.tonal(
                        onPressed: () {},
                        child: const Text('读取久坐提醒'),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.tonal(
                        onPressed: () {},
                        child: const Text('设置久坐提醒'),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.tonal(
                        onPressed: () {},
                        child: const Text('读取喝水提醒'),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.tonal(
                        onPressed: () {},
                        child: const Text('设置洗手提醒'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: _buildAlarmResult(theme),
          ),
        ],
      ),
    );
  }
}
