import 'dart:async';

import 'package:blesdk/blesdk.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

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

enum DevicePhase {
  idle,
  scanning,
  connecting,
  connected,
  binding,
  bound,
  syncing,
  unbinding,
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _sdk = Blesdk.instance;
  final List<BleDevice> _devices = [];
  final List<String> _logs = [];

  DevicePhase _phase = DevicePhase.idle;
  String _status = '未初始化';
  String? _sdkVersion;
  BleDevice? _selected;
  BleDevice? _bound;
  String _syncSummary = '';
  StreamSubscription<BleConnectionEvent>? _connSub;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _connSub?.cancel();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    try {
      await _sdk.init(maxMtu: 247);
      final ver = await _sdk.getVersion();
      _connSub = _sdk.connectionEvents().listen(_onConnectionEvent);

      setState(() {
        _sdkVersion = ver;
        _status = 'SDK 就绪';
      });
      _log('初始化成功，版本 $ver');
    } catch (e) {
      setState(() => _status = '初始化失败: $e');
      _log('初始化失败: $e');
    }
  }

  void _onConnectionEvent(BleConnectionEvent event) {
    switch (event) {
      case BleConnectedEvent(:final deviceName, :final macAddress):
        setState(() {
          if (macAddress != null && macAddress.isNotEmpty) {
            _selected = BleDevice(
              name: deviceName,
              macAddress: macAddress,
            );
          }
          if (_phase != DevicePhase.binding && _phase != DevicePhase.bound) {
            _phase = DevicePhase.connected;
          }
          _status = '已连接 ${deviceName ?? macAddress ?? ''}';
        });
      case BleDisconnectedEvent():
        if (_phase == DevicePhase.unbinding) return;
        setState(() {
          if (_phase != DevicePhase.bound && _phase != DevicePhase.idle) {
            _phase = DevicePhase.idle;
          }
          _status = '已断开';
        });
    }
  }

  void _log(String msg) {
    final now = DateTime.now();
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final ss = now.second.toString().padLeft(2, '0');
    final line = '$hh:$mm:$ss  $msg';
    if (!mounted) return;
    setState(() {
      _logs.insert(0, line);
      if (_logs.length > 80) _logs.removeLast();
    });
  }

  Future<bool> _ensurePermissions() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();
    final ok = statuses.values.every(
      (s) => s.isGranted || s.isLimited || s.isRestricted,
    );
    if (!ok) {
      _log('蓝牙/定位权限未授予');
      setState(() => _status = '请授予蓝牙与定位权限');
    }
    return ok;
  }

  Future<void> _scan() async {
    if (_busy) return;
    if (!await _ensurePermissions()) return;

    setState(() {
      _busy = true;
      _devices.clear();
      _phase = DevicePhase.scanning;
      _status = '扫描中…';
      _syncSummary = '';
    });
    _log('开始扫描');

    try {
      await for (final event in _sdk.scanDevices(timeoutMs: 10000)) {
        if (!mounted) return;
        switch (event) {
          case BleScanStarted(:final success):
            setState(() {
              _status = success ? '扫描中…' : '扫描启动失败';
            });
          case BleScanResult(:final device):
            setState(() {
              final i = _devices.indexWhere(
                (d) => d.macAddress == device.macAddress,
              );
              if (i >= 0) {
                _devices[i] = device;
              } else {
                _devices.add(device);
              }
              _devices.sort((a, b) => (b.rssi ?? -999).compareTo(a.rssi ?? -999));
            });
          case BleScanFinished(:final devices):
            setState(() {
              _devices
                ..clear()
                ..addAll(devices);
              _devices.sort(
                (a, b) => (b.rssi ?? -999).compareTo(a.rssi ?? -999),
              );
              _phase = DevicePhase.idle;
              _status = '扫描结束，共 ${devices.length} 台';
            });
            _log('扫描结束: ${devices.length} 台设备');
        }
      }
    } catch (e) {
      setState(() {
        _phase = DevicePhase.idle;
        _status = '扫描失败: $e';
      });
      _log('扫描失败: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _stopScan() async {
    try {
      await _sdk.stopScan();
      setState(() {
        _phase = DevicePhase.idle;
        _status = '已停止扫描';
        _busy = false;
      });
    } catch (e) {
      _log('停止扫描失败: $e');
    }
  }

  Future<void> _connect(BleDevice device) async {
    if (_busy) return;
    if (!await _ensurePermissions()) return;

    setState(() {
      _busy = true;
      _selected = device;
      _phase = DevicePhase.connecting;
      _status = '连接 ${device.name ?? device.macAddress}…';
    });
    _log('连接 ${device.macAddress}');

    try {
      await _sdk.stopScan();
      final connected = await _sdk.connect(
        macAddress: device.macAddress.isNotEmpty ? device.macAddress : null,
        bleName: device.name,
        timeoutSeconds: 30,
      );
      setState(() {
        _selected = connected;
        _phase = DevicePhase.connected;
        _status = '已连接 ${connected.name ?? connected.macAddress}';
      });
      _log('连接成功');
    } catch (e) {
      setState(() {
        _phase = DevicePhase.idle;
        _status = '连接失败: $e';
      });
      _log('连接失败: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _bind() async {
    if (_busy) return;
    final device = _selected;
    if (device == null) {
      setState(() => _status = '请先连接设备');
      return;
    }

    setState(() {
      _busy = true;
      _phase = DevicePhase.binding;
      _status = '绑定中，请在手表上确认…';
    });
    _log('开始绑定');

    try {
      final connected = await _sdk.isConnected();
      if (!connected) {
        await _connect(device);
      }

      await _sdk.startBind(BleBindType.normal);
      _log('startBind 成功，同步环境信息');

      await _sdk.setDeviceTime(
        time: DateTime.now(),
        use24HourFormat: true,
      );
      await _sdk.setUserInfo(
        const BleUserInfo(
          gender: BleGender.male,
          age: 28,
          height: 175,
          weight: 700,
        ),
      );
      await _sdk.setUnit(BleUnit.metric);
      await _sdk.setLanguage(0); // 简体中文（以 SDK 枚举为准）
      await _sdk.endBind();
      await _sdk.setBind(true);

      setState(() {
        _bound = device;
        _phase = DevicePhase.bound;
        _status = '绑定成功';
      });
      _log('绑定完成');
    } catch (e) {
      setState(() {
        _phase = DevicePhase.connected;
        _status = '绑定失败: $e';
      });
      _log('绑定失败: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
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
        final target = _bound ?? _selected;
        if (target == null) {
          throw Exception('没有可同步的设备，请先绑定或连接');
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

      // 同步入库后删除设备端缓存，避免重复拉取
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
        _phase = DevicePhase.bound;
        _status = '同步完成';
        _syncSummary = summary;
      });
      _log('同步完成: $summary'.replaceAll('\n', ' / '));
    } catch (e) {
      setState(() {
        _phase = _bound != null ? DevicePhase.bound : DevicePhase.connected;
        _status = '同步失败: $e';
      });
      _log('同步失败: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _unbind() async {
    if (_busy) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('解绑手表'),
        content: const Text('将清除手表数据并断开连接，确定继续？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('解绑'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() {
      _busy = true;
      _phase = DevicePhase.unbinding;
      _status = '解绑中…';
    });
    _log('开始解绑');

    try {
      await _sdk.unbind();

      setState(() {
        _bound = null;
        _selected = null;
        _phase = DevicePhase.idle;
        _status = '已解绑';
        _syncSummary = '';
      });
      _log('解绑完成');
    } catch (e) {
      setState(() {
        _phase = DevicePhase.bound;
        _status = '解绑失败: $e';
      });
      _log('解绑失败: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _disconnect() async {
    try {
      await _sdk.disconnect();
      setState(() {
        _phase = _bound != null ? DevicePhase.bound : DevicePhase.idle;
        _status = '已断开连接';
      });
    } catch (e) {
      _log('断开失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
      body: Column(
        children: [
          _StatusBanner(status: _status, phase: _phase, busy: _busy),
          if (_bound != null || _selected != null)
            _CurrentDeviceCard(
              device: _selected ?? _bound!,
              bound: _bound != null,
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: _busy
                      ? null
                      : (_phase == DevicePhase.scanning ? _stopScan : _scan),
                  icon: Icon(
                    _phase == DevicePhase.scanning
                        ? Icons.stop
                        : Icons.bluetooth_searching,
                  ),
                  label: Text(_phase == DevicePhase.scanning ? '停止扫描' : '扫描设备'),
                ),
                FilledButton.tonalIcon(
                  onPressed: _busy ||
                          _selected == null ||
                          _phase == DevicePhase.scanning
                      ? null
                      : _bind,
                  icon: const Icon(Icons.link),
                  label: const Text('绑定手表'),
                ),
                FilledButton.tonalIcon(
                  onPressed: _busy ||
                          (_bound == null &&
                              _phase != DevicePhase.connected &&
                              _phase != DevicePhase.bound)
                      ? null
                      : _sync,
                  icon: const Icon(Icons.sync),
                  label: const Text('同步数据'),
                ),
                OutlinedButton.icon(
                  onPressed: _busy || _bound == null ? null : _unbind,
                  icon: const Icon(Icons.link_off),
                  label: const Text('解绑手表'),
                ),
                if (_phase == DevicePhase.connected ||
                    _phase == DevicePhase.bound)
                  TextButton(
                    onPressed: _busy ? null : _disconnect,
                    child: const Text('断开连接'),
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
          Expanded(
            flex: 3,
            child: _devices.isEmpty
                ? Center(
                    child: Text(
                      _phase == DevicePhase.scanning ? '正在搜索附近设备…' : '点击「扫描设备」开始',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: _devices.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final d = _devices[index];
                      final selected =
                          _selected?.macAddress == d.macAddress;
                      return ListTile(
                        selected: selected,
                        leading: CircleAvatar(
                          backgroundColor: selected
                              ? theme.colorScheme.primaryContainer
                              : theme.colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.watch,
                            color: selected
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        title: Text(
                          (d.name == null || d.name!.isEmpty)
                              ? '未知设备'
                              : d.name!,
                        ),
                        subtitle: Text(
                          '${d.macAddress}  ·  RSSI ${d.rssi ?? '-'}',
                        ),
                        trailing: FilledButton(
                          onPressed: _busy ? null : () => _connect(d),
                          child: const Text('连接'),
                        ),
                        onTap: _busy ? null : () => _connect(d),
                      );
                    },
                  ),
          ),
          const Divider(height: 1),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text('日志', style: theme.textTheme.titleSmall),
                ),
                Expanded(
                  child: ListView.builder(
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
                ),
              ],
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
            Expanded(
              child: Text(status, style: theme.textTheme.titleSmall),
            ),
          ],
        ),
      ),
    );
  }

  IconData _phaseIcon(DevicePhase phase) {
    return switch (phase) {
      DevicePhase.scanning => Icons.bluetooth_searching,
      DevicePhase.connecting => Icons.bluetooth_connected,
      DevicePhase.connected => Icons.bluetooth_connected,
      DevicePhase.binding => Icons.link,
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
                    device.name?.isNotEmpty == true
                        ? device.name!
                        : '未知设备',
                    style: theme.textTheme.titleSmall,
                  ),
                  Text(
                    device.macAddress,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Text(
              bound ? '已绑定' : '已选中',
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
