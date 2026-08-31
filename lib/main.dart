import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sdkdemo/bound_device_store.dart';
import 'package:sdkdemo/pages/bind_flow_sheet.dart';
import 'package:sdkdemo/pages/scan_connect_page.dart';
import 'package:sdkdemo/pages/unbind_flow_sheet.dart';
import 'package:sdkdemo/sdk/sdk.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SdkDemoApp());
}

class SdkDemoApp extends StatelessWidget {
  const SdkDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BLE SDK Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B6CA8),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true),
      ),
      home: const HomePage(),
    );
  }
}

enum DevicePhase { idle, connected, bound, syncing, unbinding }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _sdk = HwBleSdk.instance;
  final List<String> _logs = [];

  DevicePhase _phase = DevicePhase.idle;
  String _status = '未初始化';
  String? _sdkVersion;
  BleDevice? _device;
  bool _bound = false;
  String _syncSummary = '';
  List<BleActivity> _wlActivities = const [];
  List<BleSleep> _wlSleeps = const [];
  List<BleHeartrate> _wlHeartrates = const [];
  List<BleSpo2> _wlSpo2s = const [];
  List<BleStress> _wlStresses = const [];
  List<BleHrv> _wlHrvs = const [];
  StreamSubscription<BleConnectionEvent>? _connSub;
  bool _busy = false;

  /// 用户主动点「断开连接」后为 true，此时不自动重连。
  bool _manualDisconnect = false;
  bool _reconnecting = false;
  Timer? _reconnectTimer;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _connSub?.cancel();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    const maxMtu = 247;
    try {
      await _sdk.init(maxMtu: maxMtu);
      final ver = await _sdk.getVersion();
      _connSub = _sdk.connectionEvents().listen(_onConnectionEvent);

      final initLog = Platform.isAndroid
          ? '初始化成功，版本 $ver，mtu=$maxMtu'
          : '初始化成功，版本 $ver';

      final saved = await BoundDeviceStore.load();
      if (!mounted) return;

      if (saved != null) {
        setState(() {
          _sdkVersion = ver;
          _device = BleDevice(name: saved.name, macAddress: saved.macAddress);
          _bound = true;
          _phase = DevicePhase.bound;
          _status = '已绑定 ${saved.name ?? saved.macAddress}（来自本地）';
        });
        _log(initLog);
        _log('读取本地绑定: ${saved.macAddress}');
        if (saved.deviceInfo != null) {
          final info = saved.deviceInfo!;
          _log(
            '本地设备信息: type=${info.type}, fw=${info.firmwareVersion}, '
            'proto=${info.protocolVersion}',
          );
        }
        // 恢复 SDK 侧绑定标记，便于断连重连逻辑
        try {
          await _sdk.setBind(true);
        } catch (_) {}
        await _enableAutoReconnect(_device!);
        await _tryReconnect(reason: '启动恢复');
      } else {
        setState(() {
          _sdkVersion = ver;
          _status = 'SDK 就绪';
        });
        _log(initLog);
      }
    } catch (e) {
      setState(() => _status = '初始化失败: $e');
      _log('初始化失败: $e');
    }
  }

  void _onConnectionEvent(BleConnectionEvent event) {
    switch (event) {
      case BleConnectedEvent(:final deviceName, :final macAddress):
        _reconnectTimer?.cancel();
        _reconnecting = false;
        setState(() {
          if (macAddress != null && macAddress.isNotEmpty) {
            _device = BleDevice(name: deviceName, macAddress: macAddress);
          }
          if (!_bound) {
            _phase = DevicePhase.connected;
          } else {
            _phase = DevicePhase.bound;
          }
          _status = '已连接 ${deviceName ?? macAddress ?? ''}';
        });
        _log('连接事件: 已连接');
      case BleDisconnectedEvent():
        if (_phase == DevicePhase.unbinding) return;
        setState(() {
          if (!_bound) {
            _phase = DevicePhase.idle;
            _status = '已断开';
          } else if (_manualDisconnect) {
            _status = '已绑定（已手动断开）';
          } else {
            _status = '已绑定（连接断开，准备重连）';
          }
        });
        _log(_manualDisconnect ? '连接事件: 已手动断开' : '连接事件: 意外断开');
        if (_bound && !_manualDisconnect) {
          _scheduleReconnect();
        }
    }
  }

  Future<void> _enableAutoReconnect(BleDevice device) async {
    _manualDisconnect = false;
    _log('已开启自动重连（${device.macAddress}）');
  }

  Future<void> _disableAutoReconnect() async {
    _reconnectTimer?.cancel();
    _reconnecting = false;
    _log('已停止自动重连');
  }

  void _scheduleReconnect({Duration delay = const Duration(seconds: 2)}) {
    if (!_bound || _manualDisconnect || _device == null) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      _tryReconnect(reason: '断线重连');
    });
  }

  Future<void> _tryReconnect({required String reason}) async {
    final device = _device;
    if (!_bound || _manualDisconnect || device == null) return;
    if (_reconnecting) return;
    if (_phase == DevicePhase.unbinding || _phase == DevicePhase.syncing) {
      return;
    }

    try {
      if (await _sdk.isConnected()) return;
    } catch (_) {}

    _reconnecting = true;
    if (mounted) {
      setState(() => _status = '重连中（$reason）…');
    }
    _log('开始重连: $reason → ${device.macAddress}');

    try {
      await _sdk.connect(
        macAddress: device.macAddress.isNotEmpty ? device.macAddress : null,
        bleName: device.name,
        timeoutSeconds: 30,
      );
      if (!mounted) return;
      setState(() {
        _phase = DevicePhase.bound;
        _status = '已重连 ${device.name ?? device.macAddress}';
      });
      _log('重连成功');
    } catch (e) {
      _log('重连失败: $e');
      if (mounted && _bound && !_manualDisconnect) {
        setState(() => _status = '重连失败，稍后重试');
        _scheduleReconnect(delay: const Duration(seconds: 5));
      }
    } finally {
      _reconnecting = false;
    }
  }

  void _log(String msg) {
    final now = DateTime.now();
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final ss = now.second.toString().padLeft(2, '0');
    if (!mounted) return;
    setState(() {
      _logs.insert(0, '$hh:$mm:$ss  $msg');
      if (_logs.length > 80) _logs.removeLast();
    });
  }

  Future<void> _openScanPage() async {
    if (_busy) return;
    final result = await Navigator.of(context).push<BleDevice>(
      MaterialPageRoute(builder: (_) => const ScanConnectPage()),
    );
    if (result == null || !mounted) return;
    setState(() {
      _device = result;
      _phase = _bound ? DevicePhase.bound : DevicePhase.connected;
      _status = '已连接 ${result.name ?? result.macAddress}';
      _manualDisconnect = false;
    });
    _log('连接成功: ${result.macAddress}');
    if (_bound) {
      await _enableAutoReconnect(result);
    }
  }

  Future<void> _bind() async {
    if (_busy) return;
    if (_device == null || !await _sdk.isConnected()) {
      setState(() => _status = '请先扫描并连接设备');
      return;
    }

    setState(() => _busy = true);
    _log('打开绑定流程');

    if (!mounted) return;
    final result = await showBindFlowSheet(context);
    if (!mounted) return;

    if (result != null) {
      final device = _device;
      if (device != null) {
        await BoundDeviceStore.save(
          macAddress: device.macAddress,
          name: device.name,
          deviceInfo: result.deviceInfo,
        );
        _log('已保存绑定信息到本地: ${device.macAddress}');
        if (result.deviceInfo != null) {
          final info = result.deviceInfo!;
          _log(
            '设备信息: type=${info.type}, fw=${info.firmwareVersion}, '
            'proto=${info.protocolVersion}, bat=${info.battery}',
          );
        }
      }
      if (!mounted) return;
      setState(() {
        _bound = true;
        _phase = DevicePhase.bound;
        _status = '绑定成功';
        _busy = false;
      });
      _log('绑定完成');
      if (_device != null) {
        await _enableAutoReconnect(_device!);
      }
    } else {
      setState(() {
        _phase = DevicePhase.connected;
        _status = '绑定未完成';
        _busy = false;
      });
      _log('绑定未完成');
    }
  }

  Future<void> _sync() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _phase = DevicePhase.syncing;
      _status = '同步数据中…';
      _syncSummary = '';
    });
    _log('开始同步健康数据');

    try {
      if (!await _sdk.isConnected()) {
        final target = _device;
        if (target == null) {
          throw Exception('没有可同步的设备，请先连接并绑定');
        }
        await _sdk.connect(
          macAddress: target.macAddress.isNotEmpty ? target.macAddress : null,
          bleName: target.name,
        );
      }

      final count = await _sdk.getHealthDataCount();
      final activities = count.activityCount > 0
          ? await _sdk.getActivities(count.activityCount)
          : <BleActivity>[];
      final heartrates = await _sdk.getHeartrates();
      final sleeps = await _sdk.getSleeps();

      final totalSteps = activities.fold<int>(0, (s, a) => s + a.step);
      final summary =
          '活动 ${activities.length} 条（步数合计 $totalSteps）\n'
          '心率 ${heartrates.length} 条\n'
          '睡眠 ${sleeps.length} 条';

      if (activities.isNotEmpty) {
        try {
          await _sdk.deleteSports();
        } catch (_) {}
      }
      if (heartrates.isNotEmpty) {
        try {
          await _sdk.deleteHeartrates();
        } catch (_) {}
      }
      if (sleeps.isNotEmpty) {
        try {
          await _sdk.deleteSleeps();
        } catch (_) {}
      }

      setState(() {
        _phase = _bound ? DevicePhase.bound : DevicePhase.connected;
        _status = '同步完成';
        _syncSummary = summary;
      });
      _log('同步完成: ${summary.replaceAll('\n', ' / ')}');
    } catch (e) {
      setState(() {
        _phase = _bound ? DevicePhase.bound : DevicePhase.connected;
        _status = '同步失败: $e';
      });
      _log('同步失败: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// 杰理健康数据使用六个独立 V2 接口串行同步，单类失败不覆盖其它类别结果。
  Future<void> _syncJLHealthData() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _phase = DevicePhase.syncing;
      _status = '杰理健康数据同步中…';
      _syncSummary = '';
    });
    _log('杰理健康数据同步入口');

    try {
      if (!await _sdk.isConnected()) {
        final target = _device;
        if (target == null) {
          throw Exception('没有可同步的设备，请先连接并绑定');
        }
        _log('杰理同步检测到未连接，开始重连: ${target.macAddress}');
        await _sdk.connect(
          macAddress: target.macAddress.isNotEmpty ? target.macAddress : null,
          bleName: target.name,
        );
        _log('杰理同步重连成功');
      }

      final errors = <String>[];

      Future<List<T>?> load<T>(
        String category,
        Future<List<T>> Function() action,
      ) async {
        _log('杰理$category 开始读取');
        try {
          final data = await action();
          _log('杰理$category 成功 count=${data.length}');
          return data;
        } catch (error) {
          final context = error.toString();
          errors.add('$category: $context');
          _log('杰理$category 失败: $context');
          return null;
        }
      }

      final activities = await load<BleActivity>(
        'STEP',
        _sdk.getActivitiesV2,
      );
      if (activities != null) _wlActivities = activities;

      final sleeps = await load<BleSleep>('SLEEP', _sdk.getSleepsV2);
      if (sleeps != null) _wlSleeps = sleeps;

      final heartrates = await load<BleHeartrate>(
        'HEART_RATE',
        _sdk.getHeartratesV2,
      );
      if (heartrates != null) _wlHeartrates = heartrates;

      final spo2s = await load<BleSpo2>('SPO2', _sdk.getSpo2sV2);
      if (spo2s != null) _wlSpo2s = spo2s;

      final stresses = await load<BleStress>(
        'STRESS',
        _sdk.getStressesV2,
      );
      if (stresses != null) _wlStresses = stresses;

      // final hrvs = await load<BleHrv>('HRV', _sdk.getHrvsV2);
      // if (hrvs != null) _wlHrvs = hrvs;

      final totalSteps = _wlActivities.fold<int>(
        0,
        (sum, item) => sum + item.step,
      );
      final summary = StringBuffer()
        ..writeln('活动 ${_wlActivities.length} 条（步数合计 $totalSteps）')
        ..writeln('睡眠 ${_wlSleeps.length} 条')
        ..writeln('心率 ${_wlHeartrates.length} 条')
        ..writeln('血氧 ${_wlSpo2s.length} 条')
        ..writeln('压力 ${_wlStresses.length} 条');
        //..write('HRV ${_wlHrvs.length} 条');
      if (errors.isNotEmpty) {
        summary
          ..writeln()
          ..write('失败：${errors.join('；')}');
      }

      if (!mounted) return;
      setState(() {
        _phase = _bound ? DevicePhase.bound : DevicePhase.connected;
        _status = errors.isEmpty ? '杰理同步完成' : '杰理同步部分完成';
        _syncSummary = summary.toString();
      });
      _log(
        '${errors.isEmpty ? '杰理同步完成' : '杰理同步部分完成'}: '
        '${summary.toString().replaceAll('\n', ' / ')}',
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _phase = _bound ? DevicePhase.bound : DevicePhase.connected;
        _status = '杰理同步失败: $error';
      });
      _log('杰理同步失败: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _unbind() async {
    if (_busy) return;
    if (!_bound) {
      setState(() => _status = '当前未绑定设备');
      return;
    }

    setState(() {
      _busy = true;
      _phase = DevicePhase.unbinding;
      _status = '解绑中…';
    });
    _log('打开解绑流程');
    await _disableAutoReconnect();

    if (!mounted) return;
    final ok = await showUnbindFlowSheet(context);
    if (!mounted) return;

    if (ok == true) {
      _log('已清除本地绑定信息');
      if (!mounted) return;
      setState(() {
        _bound = false;
        _device = null;
        _phase = DevicePhase.idle;
        _status = '已解绑';
        _syncSummary = '';
        _busy = false;
      });
      _log('解绑完成');
    } else {
      setState(() {
        _phase = DevicePhase.bound;
        _status = ok == false ? '解绑未完成' : '已取消解绑';
        _busy = false;
      });
      _log('解绑未完成');
      if (_device != null) {
        await _enableAutoReconnect(_device!);
      }
    }
  }

  Future<void> _disconnect() async {
    try {
      _manualDisconnect = true;
      await _disableAutoReconnect();
      await _sdk.disconnect();
      setState(() {
        _phase = _bound ? DevicePhase.bound : DevicePhase.idle;
        _status = _bound ? '已绑定（已手动断开）' : '已断开连接';
      });
      _log('已手动断开连接（不会自动重连）');
    } catch (e) {
      _log('断开失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canBind = !_busy && _device != null && !_bound;
    final canSync = !_busy && (_bound || _phase == DevicePhase.connected);
    final canUnbind = !_busy && _bound;

    return Scaffold(
      appBar: AppBar(
        title: const Text('手表 SDK Demo'),
        actions: [
          if (_sdkVersion != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text(
                  'v$_sdkVersion',
                  style: theme.textTheme.labelMedium,
                ),
              ),
            ),
        ],
      ),
      // Keep the whole page scrollable when controls exceed a short screen.
      body: ListView(
        children: [
          _StatusBanner(status: _status, phase: _phase, busy: _busy),
          if (_device != null)
            _CurrentDeviceCard(device: _device!, bound: _bound),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton.icon(
                  onPressed: _busy ? null : _openScanPage,
                  icon: const Icon(Icons.bluetooth_searching),
                  label: const Text('扫描并连接设备'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: canBind ? _bind : null,
                        icon: const Icon(Icons.link),
                        label: const Text('绑定手表'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: canSync ? _sync : null,
                        icon: const Icon(Icons.sync),
                        label: const Text('同步数据'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: canSync ? _syncJLHealthData : null,
                        icon: const Icon(Icons.sync),
                        label: const Text('同步数据（杰理）'),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: canUnbind ? _unbind : null,
                        icon: const Icon(Icons.link_off),
                        label: const Text('解绑手表'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextButton(
                        onPressed: _busy || _device == null
                            ? null
                            : _disconnect,
                        child: const Text('断开连接'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_syncSummary.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _syncSummary,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('日志', style: theme.textTheme.titleSmall),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _logs.length,
            itemBuilder: (context, index) => Text(
              _logs[index],
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.status,
    required this.phase,
    required this.busy,
  });

  final String status;
  final DevicePhase phase;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          children: [
            if (busy)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(_phaseIcon(phase), color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(status, style: theme.textTheme.titleSmall)),
          ],
        ),
      ),
    );
  }

  IconData _phaseIcon(DevicePhase phase) {
    return switch (phase) {
      DevicePhase.connected => Icons.bluetooth_connected,
      DevicePhase.bound => Icons.verified,
      DevicePhase.syncing => Icons.sync,
      DevicePhase.unbinding => Icons.link_off,
      DevicePhase.idle => Icons.bluetooth,
    };
  }
}

class _CurrentDeviceCard extends StatelessWidget {
  const _CurrentDeviceCard({required this.device, required this.bound});

  final BleDevice device;
  final bool bound;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.watch,
              color: bound
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.name?.isNotEmpty == true ? device.name! : '未知设备',
                    style: theme.textTheme.titleSmall,
                  ),
                  Text(device.macAddress, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            Text(
              bound ? '已绑定' : '已连接',
              style: theme.textTheme.labelMedium?.copyWith(
                color: bound
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
