import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Mock BLE UUIDs (协议未知，使用 Mock)
const String mockServiceUuid = '0000FFE0-0000-1000-8000-00805F9B34FB';
const String mockCharUuid = '0000FFE1-0000-1000-8000-00805F9B34FB';

/// 全局蓝牙控制器：连接状态、Auto-Sync、指令发送
class BleController extends ChangeNotifier {
  BleController._();
  static final BleController instance = BleController._();

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _writeChar;
  bool _autoSyncEnabled = true;
  bool _isConnecting = false;

  /// 连接成功后跳转到指定 Tab 的回调 (0=Scan, 1=Connect, 2=Music, 3=Light)
  void Function(int tabIndex)? onNavigateToTab;

  BluetoothDevice? get connectedDevice => _connectedDevice;
  bool get isConnected => _connectedDevice != null;
  bool get isConnecting => _isConnecting;
  bool get autoSyncEnabled => _autoSyncEnabled;

  void setAutoSync(bool value) {
    _autoSyncEnabled = value;
    notifyListeners();
  }

  /// 模拟连接成功（Mock 设备）
  Future<void> mockConnect() async {
    _isConnecting = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 800));

    _isConnecting = false;
    _connectedDevice = null; // Mock: 无真实设备，仅标记为已连接
    notifyListeners();

    debugPrint('[BleController] Mock connect success -> navigate to Connect tab');
    onNavigateToTab?.call(1);
  }

  /// 断开连接
  Future<void> disconnect() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      _connectedDevice = null;
      _writeChar = null;
    }
    notifyListeners();
    debugPrint('[BleController] Disconnected');
    onNavigateToTab?.call(0);
  }

  /// 写入 RGB 指令 (Mock: 仅打印日志)
  Future<void> writeRgb(List<int> rgb) async {
    if (rgb.length < 3) return;
    final cmd = [0xAA, 0x55, 0x03, rgb[0], rgb[1], rgb[2]]; // Mock 协议头
    await _writeBytes(cmd);
    debugPrint('[BleController] writeRgb: ${rgb.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ')}');
  }

  /// 写入十六进制指令 (Mock: 仅打印日志)
  Future<void> writeHex(List<int> data) async {
    await _writeBytes(data);
    debugPrint('[BleController] writeHex: ${data.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ')}');
  }

  Future<void> _writeBytes(List<int> data) async {
    if (_connectedDevice != null && _writeChar != null) {
      await _writeChar!.write(data);
    } else {
      debugPrint('[BleController] Mock write (no device): $data');
    }
  }
}
