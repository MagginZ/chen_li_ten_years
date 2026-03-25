import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// 音乐同步脚本：秒数 -> RGB 指令 [R, G, B]
final Map<int, List<int>> syncScript = {
  5: [0xFF, 0x00, 0x00],
  12: [0x00, 0xFF, 0x00],
  30: [0x00, 0x00, 0xFF],
};

class BleController extends ChangeNotifier {
  BleController._();
  static final BleController instance = BleController._();

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _writeChar;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  bool _autoSyncEnabled = true;
  bool _isConnecting = false;

  /// 连接成功后跳转到指定 Tab 的回调 (0=Scan, 1=Connect, 2=Music, 3=Light)
  void Function(int tabIndex)? onNavigateToTab;

  BluetoothDevice? get connectedDevice => _connectedDevice;
  bool get isConnected => _connectedDevice != null && _writeChar != null;
  bool get isConnecting => _isConnecting;
  bool get autoSyncEnabled => _autoSyncEnabled;

  void setAutoSync(bool value) {
    _autoSyncEnabled = value;
    notifyListeners();
  }

  Future<void> connect(BluetoothDevice device) async {
    if (_isConnecting) return;
    _isConnecting = true;
    notifyListeners();

    try {
      if (_connectedDevice?.remoteId != device.remoteId) {
        await _disconnectCurrentDevice(navigate: false);
      }

      await _connectionSubscription?.cancel();
      _connectionSubscription = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected &&
            _connectedDevice?.remoteId == device.remoteId) {
          _clearConnectionState();
          onNavigateToTab?.call(0);
        }
      });

      final currentState = await device.connectionState.first;
      if (currentState != BluetoothConnectionState.connected) {
        await device.connect();
      }

      final services = await device.discoverServices();
      final writeChar = _findWritableCharacteristic(services);
      if (writeChar == null) {
        throw Exception('No writable characteristic found for ${device.remoteId.str}');
      }

      _connectedDevice = device;
      _writeChar = writeChar;
      _isConnecting = false;
      notifyListeners();

      debugPrint('[BleController] Connected to ${device.platformName} (${device.remoteId.str})');
      onNavigateToTab?.call(1);
    } catch (e) {
      debugPrint('[BleController] Connection error: $e');
      await _disconnectCurrentDevice(navigate: false);
      _isConnecting = false;
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    await _disconnectCurrentDevice(navigate: true);
    debugPrint('[BleController] Disconnected');
  }

  Future<void> writeRgb(List<int> rgb) async {
    if (rgb.length < 3) return;
    final cmd = [0xAA, 0x55, 0x03, rgb[0], rgb[1], rgb[2]];
    await _writeBytes(cmd);
    debugPrint('[BleController] writeRgb: ${rgb.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ')}');
  }

  Future<void> writeHex(List<int> data) async {
    await _writeBytes(data);
    debugPrint('[BleController] writeHex: ${data.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ')}');
  }

  Future<void> triggerSyncAt(int second) async {
    final cmd = syncScript[second];
    if (cmd == null) return;
    debugPrint('[Sync] Sending RGB Command: $cmd');
    await writeHex(cmd);
  }

  BluetoothCharacteristic? _findWritableCharacteristic(List<BluetoothService> services) {
    for (final service in services) {
      for (final characteristic in service.characteristics) {
        if (characteristic.properties.write ||
            characteristic.properties.writeWithoutResponse) {
          return characteristic;
        }
      }
    }
    return null;
  }

  Future<void> _disconnectCurrentDevice({required bool navigate}) async {
    final device = _connectedDevice;
    await _connectionSubscription?.cancel();
    _connectionSubscription = null;

    try {
      if (device != null) {
        final state = await device.connectionState.first;
        if (state != BluetoothConnectionState.disconnected) {
          await device.disconnect();
        }
      }
    } catch (e) {
      debugPrint('[BleController] Disconnect error: $e');
    } finally {
      _clearConnectionState();
      if (navigate) {
        onNavigateToTab?.call(0);
      }
    }
  }

  void _clearConnectionState() {
    _connectedDevice = null;
    _writeChar = null;
    _isConnecting = false;
    notifyListeners();
  }

  Future<void> _writeBytes(List<int> data) async {
    final characteristic = _writeChar;
    if (_connectedDevice == null || characteristic == null) {
      debugPrint('[BleController] Skip write without connected writable characteristic');
      return;
    }

    try {
      await characteristic.write(
        data,
        withoutResponse: characteristic.properties.writeWithoutResponse,
      );
    } catch (e) {
      debugPrint('[BleController] Write error: $e');
    }
  }
}
