import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sdkdemo/sdk/sdk.dart';

/// 扫描并连接设备；连接成功后 pop 回传 [BleDevice]。
class ScanConnectPage extends StatefulWidget {
  const ScanConnectPage({super.key});

  @override
  State<ScanConnectPage> createState() => _ScanConnectPageState();
}

class _ScanConnectPageState extends State<ScanConnectPage> {
  final _sdk = HwBleSdk.instance;
  final List<BleDevice> _devices = [];
  bool _scanning = false;
  bool _connecting = false;
  String _status = '点击下方开始扫描';

  Future<bool> _ensurePermissions() async {
    final permissions = Platform.isIOS
        ? <Permission>[Permission.bluetooth]
        : <Permission>[
            Permission.bluetoothScan,
            Permission.bluetoothConnect,
            Permission.locationWhenInUse,
          ];
    final statuses = await permissions.request();
    final ok = statuses.values.every(
      (s) => s.isGranted || s.isLimited || s.isRestricted,
    );
    if (!ok && mounted) {
      setState(() => _status = Platform.isIOS ? '请授予蓝牙权限' : '请授予蓝牙与定位权限');
    }
    return ok;
  }

  Future<void> _scan() async {
    if (_scanning || _connecting) return;
    if (!await _ensurePermissions()) return;

    setState(() {
      _scanning = true;
      _devices.clear();
      _status = '扫描中…';
    });

    try {
      await for (final event in _sdk.scanDevices(timeoutMs: 10000)) {
        if (!mounted) return;
        switch (event) {
          case BleScanStarted(:final success):
            setState(() => _status = success ? '扫描中…' : '扫描启动失败');
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
              _devices.sort(
                (a, b) => (b.rssi ?? -999).compareTo(a.rssi ?? -999),
              );
            });
          case BleScanFinished(:final devices):
            setState(() {
              _devices
                ..clear()
                ..addAll(devices);
              _devices.sort(
                (a, b) => (b.rssi ?? -999).compareTo(a.rssi ?? -999),
              );
              _scanning = false;
              _status = '扫描结束，共 ${devices.length} 台';
            });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _scanning = false;
          _status = '扫描失败: $e';
        });
      }
    } finally {
      if (mounted && _scanning) setState(() => _scanning = false);
    }
  }

  Future<void> _stopScan() async {
    try {
      await _sdk.stopScan();
    } catch (_) {}
    if (mounted) {
      setState(() {
        _scanning = false;
        _status = '已停止扫描';
      });
    }
  }

  Future<void> _connect(BleDevice device) async {
    if (_connecting) return;
    if (!await _ensurePermissions()) return;

    setState(() {
      _connecting = true;
      _status = '连接 ${device.name ?? device.macAddress}…';
    });

    try {
      await _sdk.stopScan();
      final connected = await _sdk.connect(
        macAddress: device.macAddress.isNotEmpty ? device.macAddress : null,
        bleName: device.name,
        timeoutSeconds: 30,
      );
      if (!mounted) return;
      Navigator.pop(context, connected);
    } catch (e) {
      if (mounted) {
        setState(() {
          _connecting = false;
          _status = '连接失败: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('扫描并连接')),
      body: Column(
        children: [
          Material(
            color: theme.colorScheme.surfaceContainerLow,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  if (_scanning || _connecting)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(
                      Icons.bluetooth_searching,
                      color: theme.colorScheme.primary,
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(_status, style: theme.textTheme.titleSmall),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _connecting ? null : (_scanning ? _stopScan : _scan),
                icon: Icon(_scanning ? Icons.stop : Icons.bluetooth_searching),
                label: Text(_scanning ? '停止扫描' : '开始扫描'),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _devices.isEmpty
                ? Center(
                    child: Text(
                      _scanning ? '正在搜索附近设备…' : '暂无设备',
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
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.watch,
                            color: theme.colorScheme.onSurfaceVariant,
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
                          onPressed: _connecting ? null : () => _connect(d),
                          child: const Text('连接'),
                        ),
                        onTap: _connecting ? null : () => _connect(d),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
