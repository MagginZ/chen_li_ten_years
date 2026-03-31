import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../debug/ble_scan_ui.dart';
import 'zengge_protocol.dart';

String _hexBytes(List<int> data) =>
    data.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ');

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
  /// LEDnet `0x7E…` 走 FFE0 下的 FFE1（与常见逆向一致）。
  BluetoothCharacteristic? _chrFfe1;
  /// Zengge 静态色 `0x56…` 走 FFE9（官方/Magic Hue 文档：颜色命令写 FFE9，勿写到 FFE1）。
  BluetoothCharacteristic? _chrFfe9;
  /// 其它可写特征（仅当上面都缺失时兜底）。
  BluetoothCharacteristic? _chrFallback;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  final List<StreamSubscription<List<int>>> _notifySubscriptions = [];
  bool _autoSyncEnabled = true;
  bool _isConnecting = false;

  /// 荧光棒电源：开时发默认绿色（Kinetic #94D962），关时熄灭
  static const int _lampOnR = 0x94;
  static const int _lampOnG = 0xD9;
  static const int _lampOnB = 0x62;

  /// 未连接时为 false；连接成功后默认 true（开灯）
  bool _lampPowerOn = false;
  bool get lampPowerOn => _lampPowerOn;

  /// 连接成功后跳转到指定 Tab 的回调 (0=Scan, 1=Connect, 2=Music, 3=Light)
  void Function(int tabIndex)? onNavigateToTab;

  BluetoothDevice? get connectedDevice => _connectedDevice;

  BluetoothCharacteristic? get _primaryWriteChar =>
      _chrFfe1 ?? _chrFfe9 ?? _chrFallback;

  bool get isConnected => _connectedDevice != null && _primaryWriteChar != null;
  bool get isConnecting => _isConnecting;
  bool get autoSyncEnabled => _autoSyncEnabled;

  void setAutoSync(bool value) {
    _autoSyncEnabled = value;
    notifyListeners();
  }

  /// 征极类设备：部分固件只认 **FFE1 的 0x7E** 包，部分只认 **FFE9 的 0x56** 包，开关需双发。
  Future<void> setLampPowerOn(bool on) async {
    bleScanLog(
      '[BleLamp] setLampPowerOn($on) isConnected=$isConnected '
      'dev=${_connectedDevice?.remoteId.str ?? "-"} '
      'ffe1=${_chrFfe1?.uuid ?? "-"} ffe9=${_chrFfe9?.uuid ?? "-"}',
      toast: true,
    );
    _lampPowerOn = on;
    notifyListeners();
    if (!isConnected) {
      bleScanLog('[BleLamp] 跳过写入：未连接', toast: true);
      return;
    }
    _logWriteTarget('setLampPowerOn');
    await _applyLampPowerToDevice(on);
    bleScanLog('[BleLamp] setLampPowerOn($on) 双发结束', toast: true);
  }

  void _logWriteTarget(String reason) {
    void one(String label, BluetoothCharacteristic? c) {
      if (c == null) {
        bleScanLog('[BleLamp] $reason | $label=(无)', toast: true);
        return;
      }
      final p = c.properties;
      bleScanLog(
        '[BleLamp] $reason | $label svc=${c.serviceUuid} chr=${c.uuid} '
        'wwr=${p.writeWithoutResponse}',
        toast: true,
      );
    }

    one('FFE1(7E)', _chrFfe1);
    one('FFE9(56)', _chrFfe9);
    one('fallback', _chrFallback);
  }

  Future<void> _applyLampPowerToDevice(bool on) async {
    final r = on ? _lampOnR : 0;
    final g = on ? _lampOnG : 0;
    final b = on ? _lampOnB : 0;
    bleScanLog('[BleLamp] 双发 RGB=($r,$g,$b) on=$on', toast: true);
    await _writeProtocolBytes(
      buildLednetColorPacket(r, g, b),
      tag: 'lamp/LEDNET(7E)→FFE1',
      toastLog: true,
      preferWithResponse: true,
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
    // Zengge：`56 R G B 00 F0 AA` → 优先写 FFE9；部分固件只处理「带响应写」或只认 FFE1 上的 0x56
    final zRgb = buildZenggeStaticColorPacket(r, g, b, order: ZenggeRgbWireOrder.rgb);
    await _writeProtocolBytes(
      zRgb,
      tag: 'lamp/ZENGGE(56)→FFE9',
      toastLog: true,
      preferWithResponse: true,
    );
    if (_chrFfe1 != null && _chrFfe9 != null) {
      await Future<void>.delayed(const Duration(milliseconds: 30));
      await _writeProtocolBytes(
        zRgb,
        tag: 'lamp/ZENGGE(56)→FFE1镜像',
        toastLog: true,
        preferWithResponse: true,
        overrideChar: _chrFfe1,
      );
    }
    // 若灯珠走 GRB 线序，再补发一包 GRB（仅灯控，避免音乐同步刷屏）
    final zGrb = buildZenggeStaticColorPacket(r, g, b, order: ZenggeRgbWireOrder.grb);
    if (_hexBytes(zRgb) != _hexBytes(zGrb)) {
      await Future<void>.delayed(const Duration(milliseconds: 40));
      await _writeProtocolBytes(
        zGrb,
        tag: 'lamp/ZENGGE(56)GRB→FFE9',
        toastLog: true,
        preferWithResponse: true,
      );
    }
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

      _assignWriteCharacteristics(services);
      if (_primaryWriteChar == null) {
        throw Exception('未找到可写特征（需 FFE0/FFE1 或 FFE9 或兼容特征）');
      }

      await _subscribeZenggeNotifications(services);

      _connectedDevice = device;
      _isConnecting = false;
      _lampPowerOn = true;
      notifyListeners();

      bleScanLog(
        '[BleController] 已连接 FFE1=${_chrFfe1?.uuid} FFE9=${_chrFfe9?.uuid}',
        toast: true,
      );
      _logWriteTarget('connect后开灯');
      // 连接后默认开灯（双协议）
      await _applyLampPowerToDevice(true);
      onNavigateToTab?.call(1);
    } catch (e) {
      bleScanLog('[BleController] 连接失败: $e', toast: true);
      await _disconnectCurrentDevice(navigate: false);
      _isConnecting = false;
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    await _disconnectCurrentDevice(navigate: true);
    bleScanLog('[BleController] 已断开', toast: true);
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

  /// 同时收集 FFE1（0x7E）与 FFE9（0x56），避免只连到其一导致「双发」实际全写到同一特征而灯无反应。
  void _assignWriteCharacteristics(List<BluetoothService> services) {
    _chrFfe1 = null;
    _chrFfe9 = null;
    _chrFallback = null;

    bool canWrite(BluetoothCharacteristic c) =>
        c.properties.write || c.properties.writeWithoutResponse;

    for (final service in services) {
      final su = service.uuid.toString().toLowerCase();
      final isFfe0 = su.contains('ffe0');
      for (final c in service.characteristics) {
        if (!canWrite(c)) continue;
        final u = c.uuid.toString().toLowerCase();
        if (isFfe0 && u.contains('ffe1')) {
          _chrFfe1 = c;
        }
        if (u.contains('ffe9')) {
          _chrFfe9 = c;
        }
        _chrFallback ??= c;
      }
    }
    // 少数固件 FFE1 不在 FFE0 服务下，再扫一遍仅按 UUID 匹配
    if (_chrFfe1 == null) {
      for (final service in services) {
        for (final c in service.characteristics) {
          if (!canWrite(c)) continue;
          final u = c.uuid.toString().toLowerCase();
          if (u.contains('ffe1')) {
            _chrFfe1 = c;
            break;
          }
        }
        if (_chrFfe1 != null) break;
      }
    }
  }

  /// 部分固件对 Write Command（无响应）不生效，灯控需优先 Write Request（`preferWithResponse`）。
  bool _chooseWriteWithoutResponse(
    BluetoothCharacteristic c, {
    required bool preferWithResponse,
  }) {
    final p = c.properties;
    if (preferWithResponse && p.write) {
      return false;
    }
    if (p.writeWithoutResponse) {
      return true;
    }
    if (p.write) {
      return false;
    }
    return false;
  }

  /// 征极类：先开 FFE0 下 FFE1/FFE2 的 notify，再写颜色（与部分官方 App 顺序一致）。
  Future<void> _subscribeZenggeNotifications(List<BluetoothService> services) async {
    for (final sub in _notifySubscriptions) {
      await sub.cancel();
    }
    _notifySubscriptions.clear();

    for (final service in services) {
      final su = service.uuid.toString().toLowerCase();
      if (!su.contains('ffe0')) continue;
      for (final c in service.characteristics) {
        if (!c.properties.notify && !c.properties.indicate) continue;
        final u = c.uuid.toString().toLowerCase();
        if (!u.contains('ffe1') && !u.contains('ffe2')) continue;
        try {
          await c.setNotifyValue(true);
          _notifySubscriptions.add(c.lastValueStream.listen((_) {}));
          bleScanLog('[BleLamp] notify 已开 ${c.uuid}', toast: true);
        } catch (e) {
          bleScanLog('[BleLamp] notify 失败 ${c.uuid}: $e', toast: false);
        }
      }
    }
  }

  /// `0x7E` → FFE1；`0x56` → FFE9；否则用主写特征（与旧行为兼容）。
  BluetoothCharacteristic? _resolveWriteCharForPacket(List<int> data) {
    if (data.isEmpty) return _primaryWriteChar;
    final head = data[0];
    if (head == 0x7E && _chrFfe1 != null) return _chrFfe1;
    if (head == 0x56 && _chrFfe9 != null) return _chrFfe9;
    return _primaryWriteChar;
  }

  Future<void> _disconnectCurrentDevice({required bool navigate}) async {
    final device = _connectedDevice;
    await _connectionSubscription?.cancel();
    _connectionSubscription = null;
    for (final sub in _notifySubscriptions) {
      await sub.cancel();
    }
    _notifySubscriptions.clear();

    try {
      if (device != null) {
        if (_primaryWriteChar != null) {
          try {
            await _applyLampPowerToDevice(false);
            await Future<void>.delayed(const Duration(milliseconds: 60));
          } catch (e) {
            bleScanLog('[BleController] 断开前关灯失败: $e', toast: true);
          }
        }
        final state = await device.connectionState.first;
        if (state != BluetoothConnectionState.disconnected) {
          await device.disconnect();
        }
      }
    } catch (e) {
      bleScanLog('[BleController] 断开异常: $e', toast: true);
    } finally {
      _clearConnectionState();
      if (navigate) {
        onNavigateToTab?.call(0);
      }
    }
  }

  void _clearConnectionState() {
    _connectedDevice = null;
    _chrFfe1 = null;
    _chrFfe9 = null;
    _chrFallback = null;
    _isConnecting = false;
    _lampPowerOn = false;
    for (final sub in _notifySubscriptions) {
      sub.cancel();
    }
    _notifySubscriptions.clear();
    notifyListeners();
  }

  /// 征极协议：默认同特征优先无响应写；[preferWithResponse] 时在支持时改用带响应写（灯控更可靠）。
  Future<void> _writeProtocolBytes(
    List<int> data, {
    String tag = 'write',
    bool toastLog = false,
    bool preferWithResponse = false,
    BluetoothCharacteristic? overrideChar,
  }) async {
    final characteristic = overrideChar ?? _resolveWriteCharForPacket(data);
    if (_connectedDevice == null || characteristic == null) {
      bleScanLog('[$tag] 跳过：未连接或无匹配写特征', toast: toastLog);
      return;
    }

    final useWithoutResponse = _chooseWriteWithoutResponse(
      characteristic,
      preferWithResponse: preferWithResponse,
    );
    final hex = _hexBytes(data);
    final preview = hex.length > 80 ? '${hex.substring(0, 80)}…' : hex;
    bleScanLog(
      '[$tag] →chr=${characteristic.uuid} len=${data.length} '
      'withoutResp=$useWithoutResponse hex $preview',
      toast: toastLog,
    );

    try {
      await characteristic.write(
        data,
        withoutResponse: useWithoutResponse,
      );
      bleScanLog('[$tag] 写入 OK', toast: toastLog);
    } catch (e, st) {
      bleScanLog('[$tag] 写入失败: $e', toast: true);
      bleScanLog('[$tag] $st', toast: false);
    }
  }
}
