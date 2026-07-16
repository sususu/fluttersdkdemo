import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sdkdemo/sdk/sdk.dart';

enum BindStepStatus { pending, running, done, failed, skipped }

class BindStepItem {
  BindStepItem({
    required this.api,
    required this.description,
    this.platformNote,
  });

  final String api;
  final String description;
  final String? platformNote;
  BindStepStatus status = BindStepStatus.pending;
  String? detail;
}

/// 弹出绑定流程底部面板；全部成功后点「确认」关闭，返回 [BindFlowResult]。
Future<BindFlowResult?> showBindFlowSheet(BuildContext context) {
  return showModalBottomSheet<BindFlowResult>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    builder: (ctx) => const BindFlowSheet(),
  );
}

class BindFlowResult {
  const BindFlowResult({this.deviceInfo});

  final BleDeviceInfo? deviceInfo;
}

class BindFlowSheet extends StatefulWidget {
  const BindFlowSheet({super.key});

  @override
  State<BindFlowSheet> createState() => _BindFlowSheetState();
}

class _BindFlowSheetState extends State<BindFlowSheet> {
  final _sdk = HwBleSdk.instance;
  late final List<BindStepItem> _steps;
  bool _finished = false;
  bool _failed = false;
  String? _error;
  BleDeviceInfo? _deviceInfo;

  @override
  void initState() {
    super.initState();
    _steps = _buildSteps();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  List<BindStepItem> _buildSteps() {
    if (Platform.isIOS) {
      // SDK_iOS.md §6 配对与绑定
      return [
        BindStepItem(
          api: 'getPairStateWithCallback',
          description: '查询是否已配对',
          platformNote: 'iOS §6.1',
        ),
        BindStepItem(
          api: 'requestDeviceToPairWithCallback',
          description: '请求设备发起/配合配对',
          platformNote: 'iOS §6.1 · 按产品 SOP，可失败后继续',
        ),
        BindStepItem(
          api: 'getBtConnectionStateWithCallback',
          description: '查询 BT（经典蓝牙媒体通道）连接状态',
          platformNote: 'iOS §6.1',
        ),
        BindStepItem(
          api: 'setBtSwitch:autoConnect:',
          description: '打开手表 BT 开关并尝试自动连接',
          platformNote: 'iOS §6.1 · 可失败后继续',
        ),
        BindStepItem(
          api: 'startBindDeviceWithCallback',
          description: '标准设备绑定（请在手表上确认）',
          platformNote: 'iOS §6.2',
        ),
        BindStepItem(
          api: 'setDeviceTime:is24H:',
          description: '同步时间到手表',
          platformNote: '绑定后环境同步',
        ),
        BindStepItem(
          api: 'setUserInfo:',
          description: '同步用户信息',
          platformNote: '绑定后环境同步',
        ),
        BindStepItem(
          api: 'setUnit:',
          description: '同步单位（公制）',
          platformNote: '绑定后环境同步',
        ),
        BindStepItem(
          api: 'setLanguage:',
          description: '同步语言',
          platformNote: '绑定后环境同步',
        ),
        BindStepItem(
          api: 'getDeviceInfoWithCallback',
          description: '获取设备信息',
          platformNote: '绑定后拉取，结束后写入 App 本地',
        ),
        BindStepItem(
          api: 'endBindDeviceWithCallback',
          description: '结束绑定流程',
          platformNote: 'iOS §6.2',
        ),
        BindStepItem(
          api: 'getBindStateWithCallback',
          description: '确认设备绑定状态',
          platformNote: 'iOS §6.2',
        ),
      ];
    }

    // SDK_android.md §6 配对与绑定
    // 经典蓝牙配对放在 endBind 之后、setBind 之前
    return [
      BindStepItem(
        api: 'BluetoothSDK.startBind()',
        description: '标准设备绑定（请在手表上确认）',
        platformNote: 'Android §6.2',
      ),
      BindStepItem(
        api: 'BluetoothSDK.setDeviceTime()',
        description: '同步时间到手表',
        platformNote: '绑定后环境同步',
      ),
      BindStepItem(
        api: 'BluetoothSDK.setUserInfo()',
        description: '同步用户信息',
        platformNote: '绑定后环境同步',
      ),
      BindStepItem(
        api: 'BluetoothSDK.setUnit()',
        description: '同步单位（公制）',
        platformNote: '绑定后环境同步',
      ),
      BindStepItem(
        api: 'BluetoothSDK.setLanguage()',
        description: '同步语言',
        platformNote: '绑定后环境同步',
      ),
      BindStepItem(
        api: 'BluetoothSDK.getDeviceInfo()',
        description: '获取设备信息',
        platformNote: '绑定后拉取，结束后写入 App 本地',
      ),
      BindStepItem(
        api: 'BluetoothSDK.endBind()',
        description: '结束绑定流程',
        platformNote: 'Android §6.2',
      ),
      BindStepItem(
        api: 'BluetoothSDK.isBonded()',
        description: '查询经典蓝牙是否已配对',
        platformNote: 'Android §6.1',
      ),
      BindStepItem(
        api: 'BluetoothSDK.createBond()',
        description: '经典蓝牙配对',
        platformNote: 'Android §6.1 · 已配对则跳过',
      ),
      BindStepItem(
        api: 'BluetoothSDK.setBind(true)',
        description: '给 SDK 设置已绑定标记',
        platformNote: 'Android §6.2 · 供 SDK 断连重连逻辑使用（非 App 本地存储）',
      ),
    ];
  }

  Future<void> _markRunning(int i) async {
    setState(() {
      _steps[i].status = BindStepStatus.running;
      _steps[i].detail = null;
    });
  }

  Future<void> _markDone(int i, {String? detail}) async {
    setState(() {
      _steps[i].status = BindStepStatus.done;
      _steps[i].detail = detail;
    });
  }

  Future<void> _markSkipped(int i, {String? detail}) async {
    setState(() {
      _steps[i].status = BindStepStatus.skipped;
      _steps[i].detail = detail;
    });
  }

  Future<void> _markFailed(int i, Object e) async {
    setState(() {
      _steps[i].status = BindStepStatus.failed;
      _steps[i].detail = '$e';
      _failed = true;
      _error = '$e';
    });
  }

  Future<bool> _runSoft(int i, Future<void> Function() action) async {
    await _markRunning(i);
    try {
      await action();
      await _markDone(i);
      return true;
    } catch (e) {
      setState(() {
        _steps[i].status = BindStepStatus.skipped;
        _steps[i].detail = '失败已跳过: $e';
      });
      return false;
    }
  }

  Future<bool> _runHard(int i, Future<void> Function() action) async {
    await _markRunning(i);
    try {
      await action();
      await _markDone(i);
      return true;
    } catch (e) {
      await _markFailed(i, e);
      return false;
    }
  }

  Future<void> _run() async {
    try {
      if (!await _sdk.isConnected()) {
        setState(() {
          _failed = true;
          _error = '设备未连接，请先扫描并连接';
        });
        return;
      }

      if (Platform.isIOS) {
        await _runIos();
      } else {
        await _runAndroid();
      }

      if (!_failed) {
        setState(() => _finished = true);
      }
    } catch (e) {
      setState(() {
        _failed = true;
        _error = '$e';
      });
    }
  }

  Future<void> _runAndroid() async {
    if (!await _runHard(0, () => _sdk.startBind(BleBindType.normal))) return;

    if (!await _runHard(
      1,
      () => _sdk.setDeviceTime(
        time: DateTime.now(),
        use24HourFormat: true,
      ),
    )) {
      return;
    }
    if (!await _runHard(
      2,
      () => _sdk.setUserInfo(
        const BleUserInfo(
          gender: BleGender.male,
          age: 28,
          height: 175,
          weight: 700,
        ),
      ),
    )) {
      return;
    }
    if (!await _runHard(3, () => _sdk.setUnit(BleUnit.metric))) return;
    if (!await _runHard(4, () => _sdk.setLanguage(0))) return;

    if (!await _fetchDeviceInfo(5)) return;

    if (!await _runHard(6, () => _sdk.endBind())) return;

    // endBind 之后再做经典蓝牙配对，再设置 SDK 绑定标记
    await _markRunning(7);
    final bonded = await _sdk.isBonded();
    await _markDone(7, detail: bonded ? '已配对' : '未配对');

    if (bonded) {
      await _markSkipped(8, detail: '已配对，跳过 createBond');
    } else {
      await _runSoft(8, () => _sdk.createBond());
    }

    if (!await _runHard(9, () => _sdk.setBind(true))) return;
  }

  Future<void> _runIos() async {
    await _markRunning(0);
    try {
      final paired = await _sdk.getPairState();
      await _markDone(0, detail: paired ? '已配对' : '未配对');
      if (paired) {
        await _markSkipped(1, detail: '已配对，跳过 requestDeviceToPair');
      } else {
        await _runSoft(1, () => _sdk.requestDeviceToPair());
      }
    } catch (e) {
      await _markSkipped(0, detail: '查询失败: $e');
      await _runSoft(1, () => _sdk.requestDeviceToPair());
    }

    await _markRunning(2);
    try {
      final bt = await _sdk.getBtConnectionState();
      await _markDone(2, detail: bt ? 'BT 已连接' : 'BT 未连接');
    } catch (e) {
      await _markSkipped(2, detail: '查询失败: $e');
    }

    await _runSoft(
      3,
      () => _sdk.setBtSwitchWithAutoConnect(on: true, autoConnect: true),
    );

    if (!await _runHard(4, () => _sdk.startBind(BleBindType.normal))) return;

    if (!await _runHard(
      5,
      () => _sdk.setDeviceTime(
        time: DateTime.now(),
        use24HourFormat: true,
      ),
    )) {
      return;
    }
    if (!await _runHard(
      6,
      () => _sdk.setUserInfo(
        const BleUserInfo(
          gender: BleGender.male,
          age: 28,
          height: 175,
          weight: 700,
        ),
      ),
    )) {
      return;
    }
    if (!await _runHard(7, () => _sdk.setUnit(BleUnit.metric))) return;
    if (!await _runHard(8, () => _sdk.setLanguage(0))) return;

    if (!await _fetchDeviceInfo(9)) return;

    if (!await _runHard(10, () => _sdk.endBind())) return;

    await _markRunning(11);
    try {
      final state = await _sdk.getBindState();
      await _markDone(11, detail: 'bindState=${state.name}');
    } catch (e) {
      await _markFailed(11, e);
    }
  }

  Future<bool> _fetchDeviceInfo(int stepIndex) async {
    await _markRunning(stepIndex);
    try {
      final info = await _sdk.getDeviceInfo();
      _deviceInfo = info;
      final summary = [
        if (info.type != null) 'type=${info.type}',
        if (info.firmwareVersion != null) 'fw=${info.firmwareVersion}',
        if (info.mac != null) 'mac=${info.mac}',
        if (info.battery != null) 'bat=${info.battery}',
        if (info.protocolVersion != null) 'proto=${info.protocolVersion}',
      ].join(', ');
      await _markDone(
        stepIndex,
        detail: summary.isEmpty ? '已获取' : summary,
      );
      return true;
    } catch (e) {
      await _markFailed(stepIndex, e);
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final platformLabel = Platform.isIOS ? 'iOS' : 'Android';

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.78,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Text('绑定手表', style: theme.textTheme.titleLarge),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  '按 SDK「§6 配对与绑定」逐步调用（当前：$platformLabel）',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Text(
                    _error!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _steps.length,
                  itemBuilder: (context, index) {
                    return _StepTile(index: index + 1, step: _steps[index]);
                  },
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  children: [
                    if (_failed)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('关闭'),
                        ),
                      ),
                    if (_failed) const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _finished
                            ? () => Navigator.pop(
                                  context,
                                  BindFlowResult(deviceInfo: _deviceInfo),
                                )
                            : null,
                        child: Text(_finished ? '确认' : '绑定进行中…'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({required this.index, required this.step});

  final int index;
  final BindStepItem step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, color) = switch (step.status) {
      BindStepStatus.pending => (
          Icons.radio_button_unchecked,
          theme.colorScheme.outline,
        ),
      BindStepStatus.running => (
          Icons.hourglass_top,
          theme.colorScheme.primary,
        ),
      BindStepStatus.done => (Icons.check_circle, Colors.green.shade700),
      BindStepStatus.skipped => (
          Icons.check_circle_outline,
          theme.colorScheme.tertiary,
        ),
      BindStepStatus.failed => (Icons.error, theme.colorScheme.error),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: step.status == BindStepStatus.running
                ? const CircularProgressIndicator(strokeWidth: 2)
                : Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$index. ${step.description}',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  step.api,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: theme.colorScheme.primary,
                  ),
                ),
                if (step.platformNote != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    step.platformNote!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (step.detail != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    step.detail!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: step.status == BindStepStatus.failed
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
