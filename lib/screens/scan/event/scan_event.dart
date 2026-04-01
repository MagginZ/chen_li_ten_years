import 'dart:async';

import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../../ble/ble_permissions.dart';
import '../../../debug/ble_scan_ui.dart';
import '../../../theme/app_colors.dart';
import '../controller/scan_controller.dart';
import '../scan_web_mock.dart';

/// 将广播名为空时的设备展示为 `AA:BB:CC:DD:EE:FF` 形式 MAC
String formatBleMacForDisplay(String remoteIdStr) {
  final hex = remoteIdStr.replaceAll(RegExp(r'[^0-9A-Fa-f]'), '');
  if (hex.length != 12) return remoteIdStr;
  final buf = StringBuffer();
  for (var i = 0; i < 12; i += 2) {
    if (i > 0) buf.write(':');
    buf.write(hex.substring(i, i + 2).toUpperCase());
  }
  return buf.toString();
}

class ScanEvent {
  ScanEvent(this._controller);

  final ScanController _controller;
  StreamSubscription<List<ScanResult>>? _scanSubscription;

  /// 与 [FlutterBluePlus.startScan] 的 [timeout] 一致。注意：FBP 的 `startScan` 在发起扫描后会**立刻**完成
  /// Future，真正结束由内部 Timer 触发；若随后立即 `stopScan` 会马上掐断扫描。
  static const Duration _scanWindow = Duration(seconds: 15);

  void rescan() {
    _controller.clearDevices();
    _controller.setScanning(true);
    bleScanLog('[ScanEvent] 发起扫描 → 检查蓝牙与权限…', toast: true);
    _startScan();
  }

  Future<void> _startScan() async {
    final sw = Stopwatch()..start();
    await _scanSubscription?.cancel();

    if (kIsWeb) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      fillWebMockScanDevices(_controller);
      _controller.setScanning(false);
      bleScanLog(
        '[ScanEvent] Web 预览：已填充 10 条模拟设备（无真实 BLE，连接会失败）',
        toast: true,
      );
      return;
    }

    if (!await FlutterBluePlus.isSupported) {
      bleScanLog('[ScanEvent] 本机不支持 BLE（${sw.elapsedMilliseconds}ms）', toast: true);
      _controller.setScanning(false);
      return;
    }

    bleScanLog('[ScanEvent] 正在确认蓝牙权限…', toast: true);
    final okPerm = await ensureBlePermissionsForScan();
    if (!okPerm) {
      bleScanLog(
        '[ScanEvent] 权限未通过（${sw.elapsedMilliseconds}ms）：请在设置中允许蓝牙扫描/连接（及定位，旧系统需要）',
        toast: true,
      );
      _controller.setScanning(false);
      return;
    }
    bleScanLog('[ScanEvent] 权限 OK，adapter=${FlutterBluePlus.adapterStateNow}', toast: true);

    // 安卓：adapter 仍为 unknown 时尝试唤起系统打开蓝牙（避免部分机型不广播）
    if (defaultTargetPlatform == TargetPlatform.android) {
      final snap = FlutterBluePlus.adapterStateNow;
      if (snap == BluetoothAdapterState.unknown) {
        bleScanLog('[ScanEvent] 蓝牙状态 unknown，尝试 turnOn()…', toast: true);
        try {
          await FlutterBluePlus.turnOn(timeout: 8);
        } catch (e) {
          bleScanLog('[ScanEvent] turnOn 失败: $e', toast: true);
        }
        await Future<void>.delayed(const Duration(milliseconds: 400));
      }
    }

    final now = FlutterBluePlus.adapterStateNow;
    bleScanLog('[ScanEvent] 开始扫描前 adapter=$now', toast: true);

    if (now == BluetoothAdapterState.off || now == BluetoothAdapterState.turningOff) {
      bleScanLog('[ScanEvent] 蓝牙适配器关闭（${sw.elapsedMilliseconds}ms），无法扫描', toast: true);
      _controller.setScanning(false);
      return;
    }

    try {
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (final r in results) {
          final rawName = r.device.platformName.trim();
          final displayName = rawName.isNotEmpty
              ? rawName
              : formatBleMacForDisplay(r.device.remoteId.str);
          final id = r.device.remoteId.str;
          final rssi = r.rssi;
          final signal = rssi > -60 ? '极佳' : (rssi > -75 ? '良好' : '一般');
          final signalColor = rssi > -60
              ? AppColors.secondary
              : (rssi > -75 ? AppColors.tertiary : AppColors.error);

          _controller.addDevice(ScanDevice(
            device: r.device,
            name: displayName,
            id: id,
            signal: signal,
            signalColor: signalColor,
            isPrimary: rssi > -60,
            isLednet: displayName.toUpperCase().contains('LEDNET') ||
                rawName.toUpperCase().contains('LEDNET'),
          ));
        }
      });

      // 不传入 withServices / 其它过滤器，扫描全部广播
      bleScanLog('[ScanEvent] 正在调用 startScan（窗口 ${_scanWindow.inSeconds}s）…', toast: true);
      await FlutterBluePlus.startScan(
        timeout: _scanWindow,
        androidScanMode: AndroidScanMode.lowLatency,
        continuousUpdates: false,
        androidUsesFineLocation: false,
        androidCheckLocationServices: false,
      );
      // 必须等待扫描结束：startScan 的 Future 会马上返回，若直接进入 finally 会立刻 stopScan，扫描只有几百毫秒。
      await FlutterBluePlus.isScanning.where((v) => !v).first.timeout(
            _scanWindow + const Duration(seconds: 2),
          );
    } catch (e, st) {
      bleScanLog('[ScanEvent] startScan 异常: $e', toast: true);
      bleScanLog('[ScanEvent] stack: $st', toast: false);
    } finally {
      await FlutterBluePlus.stopScan();
      await _scanSubscription?.cancel();
      _scanSubscription = null;
      _controller.setScanning(false);
      final n = _controller.devices.length;
      bleScanLog(
        '[ScanEvent] 扫描阶段结束 耗时 ${sw.elapsedMilliseconds}ms 列表 $n 台',
        toast: true,
      );
    }
  }

  Future<void> connectDevice(int index) async {
    await _controller.connectDevice(index);
  }

  void dispose() {
    _scanSubscription?.cancel();
  }
}
