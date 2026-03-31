import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../../ble/ble_permissions.dart';
import '../../../theme/app_colors.dart';
import '../controller/scan_controller.dart';

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

  void rescan() {
    _controller.clearDevices();
    _controller.setScanning(true);
    _startScan();
  }

  Future<void> _startScan() async {
    await _scanSubscription?.cancel();

    if (!await FlutterBluePlus.isSupported) {
      debugPrint('[ScanEvent] Bluetooth not supported');
      _controller.setScanning(false);
      return;
    }

    final okPerm = await ensureBlePermissionsForScan();
    if (!okPerm) {
      debugPrint('[ScanEvent] BLE permissions denied');
      _controller.setScanning(false);
      return;
    }

    // 安卓：adapter 仍为 unknown 时尝试唤起系统打开蓝牙（避免部分机型不广播）
    if (Platform.isAndroid) {
      final snap = FlutterBluePlus.adapterStateNow;
      if (snap == BluetoothAdapterState.unknown) {
        try {
          await FlutterBluePlus.turnOn(timeout: 8);
        } catch (e) {
          debugPrint('[ScanEvent] turnOn: $e');
        }
        await Future<void>.delayed(const Duration(milliseconds: 400));
      }
    }

    final now = FlutterBluePlus.adapterStateNow;
    debugPrint('[ScanEvent] start scan, adapterStateNow=$now');

    if (now == BluetoothAdapterState.off || now == BluetoothAdapterState.turningOff) {
      debugPrint('[ScanEvent] Bluetooth adapter off');
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
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
        androidScanMode: AndroidScanMode.lowLatency,
        continuousUpdates: false,
        androidUsesFineLocation: false,
        androidCheckLocationServices: false,
      );
    } catch (e) {
      debugPrint('[ScanEvent] Bluetooth scan error: $e');
    } finally {
      await FlutterBluePlus.stopScan();
      await _scanSubscription?.cancel();
      _scanSubscription = null;
      _controller.setScanning(false);
    }
  }

  Future<void> connectDevice(int index) async {
    await _controller.connectDevice(index);
  }

  void dispose() {
    _scanSubscription?.cancel();
  }
}
