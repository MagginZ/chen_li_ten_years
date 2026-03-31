import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'zengge_protocol.dart';

/// 音乐同步脚本：秒数 -> RGB [R, G, B]（逻辑 RGB，经 [updateLightColor] 发 GRB 包）
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
      try {
        await device.requestMtu(512);
      } catch (_) {}

      final writeChar = _findWritableCharacteristic(services);
      if (writeChar == null) {
        throw Exception('未找到可写特征（需 FFE0/FFE1 或兼容特征）');
      }

      _connectedDevice = device;
      _writeChar = writeChar;
      _isConnecting = false;
      notifyListeners();

      debugPrint('[BleController] Connected, write char: ${writeChar.uuid}');
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

  /// 征极 LEDnet 调色（GRB 字节序，见 [buildLednetColorPacket]）
  Future<void> updateLightColor(int r, int g, int b) async {
    final bytes = buildLednetColorPacket(r, g, b);
    await _writeProtocolBytes(bytes);
  }

  /// 闪烁预设模式
  Future<void> sendBlinkMode() async {
    await _writeProtocolBytes(buildLednetBlinkPacket());
  }

  Future<void> writeRgb(List<int> rgb) async {
    if (rgb.length < 3) return;
    await updateLightColor(rgb[0], rgb[1], rgb[2]);
  }

  Future<void> writeHex(List<int> data) async {
    await _writeProtocolBytes(data);
  }

  Future<void> triggerSyncAt(int second) async {
    final cmd = syncScript[second];
    if (cmd == null || cmd.length < 3) return;
    await updateLightColor(cmd[0], cmd[1], cmd[2]);
  }

  /// 优先：Service FFE0 + Characteristic FFE1；其次 FFE9；再任意可写。
  BluetoothCharacteristic? _findWritableCharacteristic(List<BluetoothService> services) {
    BluetoothCharacteristic? ffe1UnderFfe0;
    BluetoothCharacteristic? ffe9;
    BluetoothCharacteristic? fallback;

    bool canWrite(BluetoothCharacteristic c) =>
        c.properties.write || c.properties.writeWithoutResponse;

    for (final service in services) {
      final su = service.uuid.toString().toLowerCase();
      final isFfe0 = su.contains('ffe0');
      for (final c in service.characteristics) {
        if (!canWrite(c)) continue;
        final u = c.uuid.toString().toLowerCase();
        if (isFfe0 && u.contains('ffe1')) {
          ffe1UnderFfe0 = c;
        }
        if (u.contains('ffe9')) {
          ffe9 = c;
        }
        fallback ??= c;
      }
    }
    return ffe1UnderFfe0 ?? ffe9 ?? fallback;
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

  /// 征极协议：优先 [BluetoothCharacteristic.write] 且 `withoutResponse: true`（若特征支持）
  Future<void> _writeProtocolBytes(List<int> data) async {
    final characteristic = _writeChar;
    if (_connectedDevice == null || characteristic == null) {
      debugPrint('[BleController] Skip write without connected writable characteristic');
      return;
    }

    try {
      final useWithoutResponse = characteristic.properties.writeWithoutResponse;
      await characteristic.write(
        data,
        withoutResponse: useWithoutResponse,
      );
    } catch (e) {
      debugPrint('[BleController] Write error: $e');
    }
  }
}
