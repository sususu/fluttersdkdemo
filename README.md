# BLE SDK Demo

独立 Flutter Demo，直接集成华沃蓝牙原生 SDK（**不依赖** `blesdk` 插件工程）。

## 原生依赖（本地优先）

| 平台 | 产物 | 位置 |
|------|------|------|
| Android | `BluetoothSDK-2.5.4.126.aar` | `android/localRepo`（本地 Maven） |
| iOS | `HwBluetoothSDK.framework` | `ios/Frameworks/`（CocoaPods vendored） |

Dart 桥接：`lib/sdk/` → MethodChannel `sdkdemo/hw_ble`

## 运行

```bash
flutter pub get
flutter run
```

iOS（Mac）：

```bash
cd ios && pod install && cd ..
flutter run
```

## 功能

扫描 / 连接 / 绑定 / 同步健康数据 / 解绑；已绑定设备支持断线自动重连（非手动断开时）。
