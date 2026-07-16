import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sdkdemo/bound_device_store.dart';
import 'package:sdkdemo/pages/bind_flow_sheet.dart';
import 'package:sdkdemo/sdk/sdk.dart';

/// 弹出解绑流程底部面板；全部成功后点「确认」关闭，返回 true。
Future<bool?> showUnbindFlowSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    builder: (ctx) => const UnbindFlowSheet(),
  );
}

class UnbindFlowSheet extends StatefulWidget {
  const UnbindFlowSheet({super.key});

  @override
  State<UnbindFlowSheet> createState() => _UnbindFlowSheetState();
}

class _UnbindFlowSheetState extends State<UnbindFlowSheet> {
  final _sdk = HwBleSdk.instance;
  late final List<BindStepItem> _steps;
  bool _finished = false;
  bool _failed = false;
  String? _error;
  bool _awaitingIgnoreConfirm = false;

  @override
  void initState() {
    super.initState();
    _steps = _buildSteps();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  List<BindStepItem> _buildSteps() {
    if (Platform.isIOS) {
      // SDK_iOS.md：unbindDevice → removeConnectionCache → disconnect
      // + 提示用户在系统蓝牙设置中忽略设备
      // + 最后清除 App 本地绑定数据
      return [
        BindStepItem(
          api: 'unbindDeviceWithCallback',
          description: '解绑设备',
          platformNote: 'iOS §6.2',
        ),
        BindStepItem(
          api: 'removeConnectionCache',
          description: '清除 SDK 连接缓存',
          platformNote: 'iOS §6.2',
        ),
        BindStepItem(
          api: 'disconnectWithCallback',
          description: '断开 BLE 连接',
          platformNote: 'iOS 解绑收尾',
        ),
        BindStepItem(
          api: '（系统设置）忽略此设备',
          description: '请到「设置 → 蓝牙」中忽略该设备',
          platformNote: 'iOS 无 removeBond，需用户手动忽略',
        ),
        BindStepItem(
          api: 'BoundDeviceStore.clear()',
          description: '清除 App 保存的绑定数据',
          platformNote: 'App 本地持久化',
        ),
      ];
    }

    // Android：先 removeBond，再 disconnect → setBind(false) → 清除 App 本地
    return [
      BindStepItem(
        api: 'BluetoothSDK.removeBond()',
        description: '取消经典蓝牙配对',
        platformNote: 'Android §6.1 · 不依赖 BLE 连接',
      ),
      BindStepItem(
        api: 'BluetoothSDK.disconnect()',
        description: '断开 BLE 连接',
        platformNote: 'Android 解绑 §22',
      ),
      BindStepItem(
        api: 'BluetoothSDK.setBind(false)',
        description: '给 SDK 清除已绑定标记',
        platformNote: 'Android §6.2 / §22 · BluetoothSDK.setBind(false)',
      ),
      BindStepItem(
        api: 'BoundDeviceStore.clear()',
        description: '清除 App 保存的绑定数据',
        platformNote: 'App 本地持久化',
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
      if (Platform.isIOS) {
        await _runIos();
      } else {
        await _runAndroid();
      }
      if (!_failed && !_awaitingIgnoreConfirm) {
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
    // removeBond：不依赖 BLE；失败可跳过（可能未配对）
    await _runSoft(0, () => _sdk.removeBond());

    await _runSoft(1, () => _sdk.disconnect());

    if (!await _runHard(2, () => _sdk.setBind(false))) return;

    if (!await _runHard(3, () => BoundDeviceStore.clear())) return;
  }

  Future<void> _runIos() async {
    if (!await _runHard(0, () => _sdk.unbindDevice())) return;

    if (!await _runHard(1, () => _sdk.removeConnectionCache())) return;

    await _runSoft(2, () => _sdk.disconnect());

    // 等待用户去系统设置忽略设备
    await _markRunning(3);
    setState(() {
      _awaitingIgnoreConfirm = true;
      _steps[3].detail = '请打开系统蓝牙设置，找到该设备并「忽略此设备」';
    });
  }

  Future<void> _confirmIgnored() async {
    await _markDone(3, detail: '用户已确认忽略设备');
    setState(() => _awaitingIgnoreConfirm = false);

    if (!await _runHard(4, () => BoundDeviceStore.clear())) return;

    setState(() => _finished = true);
  }

  Future<void> _openBluetoothSettings() async {
    await openAppSettings();
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
                child: Text('解绑手表', style: theme.textTheme.titleLarge),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  '按 SDK 解绑流程逐步调用（当前：$platformLabel）',
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
                    return _UnbindStepTile(
                      index: index + 1,
                      step: _steps[index],
                    );
                  },
                ),
              ),
              if (_awaitingIgnoreConfirm) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '请前往「设置 → 蓝牙」，找到已连接/已配对的手表，点击 ⓘ 后选择「忽略此设备」。',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: _openBluetoothSettings,
                        icon: const Icon(Icons.settings),
                        label: const Text('打开系统设置'),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.tonal(
                        onPressed: _confirmIgnored,
                        child: const Text('我已忽略该设备'),
                      ),
                    ],
                  ),
                ),
              ],
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  children: [
                    if (_failed)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('关闭'),
                        ),
                      ),
                    if (_failed) const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _finished
                            ? () => Navigator.pop(context, true)
                            : null,
                        child: Text(_finished ? '确认' : '解绑进行中…'),
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

class _UnbindStepTile extends StatelessWidget {
  const _UnbindStepTile({required this.index, required this.step});

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
