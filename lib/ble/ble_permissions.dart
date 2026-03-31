import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// 扫描前确保 BLE 相关权限已授予（不订阅 [FlutterBluePlus.adapterState]，避免部分机型流不推送导致永久 await）。
Future<bool> ensureBlePermissionsForScan() async {
  if (kIsWeb) return false;

  if (Platform.isIOS || Platform.isMacOS) {
    final s = await Permission.bluetooth.request();
    return s.isGranted;
  }

  if (!Platform.isAndroid) return true;

  var scan = await Permission.bluetoothScan.status;
  if (!scan.isGranted) {
    scan = await Permission.bluetoothScan.request();
  }
  var connect = await Permission.bluetoothConnect.status;
  if (!connect.isGranted) {
    connect = await Permission.bluetoothConnect.request();
  }
  if (!scan.isGranted || !connect.isGranted) {
    return false;
  }

  // Android 11 及以下：扫描常需「定位权限」；12+ 使用 BLUETOOTH_SCAN+neverForLocation 时可不要定位。
  // 这里尽力申请，未授予仍返回 true 以允许继续扫描（避免误拦新系统）。
  await Permission.locationWhenInUse.request();
  return true;
}
