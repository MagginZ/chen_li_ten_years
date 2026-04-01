import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../debug/ble_scan_ui.dart';
import '../settings/light_rgb_compensation.dart';
import 'zengge_protocol.dart';

String _hexBytes(List<int> data) =>
    data.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ');

/// 应援棒固件对「逻辑 RGB」与线序组合会等效 **交换 R 与 B**（现象：蓝→橙、粉↔紫）。
/// 送入 [buildZenggeSdkRgbCommand0x31] / [buildLednetColorPacket] / [buildZenggeStaticColorPacket] 前做一次 R↔B 补偿。
List<int> _rgbWireCompensateRb(int r, int g, int b) {
  final rr = r.clamp(0, 255);
  final gg = g.clamp(0, 255);
  final bb = b.clamp(0, 255);
  return <int>[bb, gg, rr];
}

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
  /// **LEDnetWF / FFFF/FF01**：与 [ZENGGE Android SDK `write(mac, 0x0b, commandData)`](http://cnwifidevsdk.magichue.net:4000/ble/AndroidSdk.html) 对齐——`0x0B` 即 Transport **cmdId=11**；`commandData` 用 **0x31 RGB+校验**（优先），必要时再发 **0x7E** 内层兼容。
  BluetoothCharacteristic? _chrFf01;
  /// 部分应援棒/双通道固件：服务 **FE00**、写 **FF11**（与 FF01 并存时需「双写」才亮）。
  BluetoothCharacteristic? _chrFf11;
  /// 旧版 LEDnet：`0x7E…` 走 FFE0 下的 FFE1。
  BluetoothCharacteristic? _chrFfe1;
  /// Magic Hue 类：`0x56…` 走 FFE9（与 FF01/7E 设备互斥场景常见）。
  BluetoothCharacteristic? _chrFfe9;
  /// 其它可写特征（仅当上面都缺失时兜底）。
  BluetoothCharacteristic? _chrFallback;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  final List<StreamSubscription<List<int>>> _notifySubscriptions = [];
  bool _autoSyncEnabled = true;
  bool _isConnecting = false;
  /// LEDnetWF Transport v0 的序号（0–255）。
  int _transportSeq = 0;

  bool get _hasLednetWfChannels => _chrFf01 != null || _chrFf11 != null;

  /// 应援棒电源：开时发默认绿色（Kinetic #94D962），关时熄灭
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
      _chrFf01 ?? _chrFf11 ?? _chrFfe1 ?? _chrFfe9 ?? _chrFallback;

  bool get isConnected => _connectedDevice != null && _primaryWriteChar != null;
  bool get isConnecting => _isConnecting;
  bool get autoSyncEnabled => _autoSyncEnabled;

  void setAutoSync(bool value) {
    _autoSyncEnabled = value;
    notifyListeners();
  }

  /// 征极类：FFFF/FF01 走 **SDK 0x31 + Transport**；旧款可能 **FFE1 的 0x7E** + **FFE9 的 0x56** 双发。
  Future<void> setLampPowerOn(bool on) async {
    bleScanLog(
      '[BleLamp] setLampPowerOn($on) isConnected=$isConnected '
      'dev=${_connectedDevice?.remoteId.str ?? "-"} '
      'ff01=${_chrFf01?.uuid ?? "-"} ff11=${_chrFf11?.uuid ?? "-"} '
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
    bleScanLog(
      '[BleLamp] setLampPowerOn($on) 写入流程结束 | hasWF=$_hasLednetWfChannels '
      'FF01=${_chrFf01 != null} FF11=${_chrFf11 != null}',
      toast: true,
    );
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

    one('FFFF/FF01(7E)', _chrFf01);
    one('FE00/FF11(7E镜像)', _chrFf11);
    one('FFE1(7E)', _chrFfe1);
    one('FFE9(56)', _chrFfe9);
    one('fallback', _chrFallback);
  }

  Future<void> _applyLampPowerToDevice(bool on) async {
    final r = on ? _lampOnR : 0;
    final g = on ? _lampOnG : 0;
    final b = on ? _lampOnB : 0;
    bleScanLog('[BleLamp] 调色 RGB=($r,$g,$b) on=$on', toast: true);
    final t = LightRgbCompensation.instance.apply(r, g, b);
    final w = _rgbWireCompensateRb(t[0], t[1], t[2]);
    final wr = w[0];
    final wg = w[1];
    final wb = w[2];
    final inner7e = buildLednetColorPacket(wr, wg, wb);
    if (_hasLednetWfChannels) {
      final p31 = buildZenggeSdkRgbCommand0x31(wr, wg, wb);
      final pwr = buildZenggeSdkLegacyPower0x71(on);
      // 1) 电源 + Transport（部分固件必须先 0x71）
      await _writeFf01ZenggeTransport(
        pwr,
        tag: 'SDK 0x71 power+Transport',
        toastLog: true,
        preferWithResponse: true,
      );
      await Future<void>.delayed(const Duration(milliseconds: 55));
      // 2) 0x31 / 7E + Transport；优先「带响应写」（无响应写常被固件丢弃）
      await _writeFf01ZenggeTransport(
        p31,
        tag: 'ZENGGE SDK 0x31+Transport',
        toastLog: true,
        preferWithResponse: true,
      );
      await Future<void>.delayed(const Duration(milliseconds: 45));
      await _writeFf01ZenggeTransport(
        inner7e,
        tag: 'LEDNET 7E+Transport',
        toastLog: true,
        preferWithResponse: true,
      );
      await Future<void>.delayed(const Duration(milliseconds: 45));
      // 3) 裸写备选：部分固件不套外层 Transport，直接收内层
      await _writeFf01RawCommandData(
        p31,
        tag: 'FF01 裸写 0x31',
        toastLog: true,
      );
      await Future<void>.delayed(const Duration(milliseconds: 35));
      await _writeFf01RawCommandData(
        inner7e,
        tag: 'FF01 裸写 7E',
        toastLog: true,
      );
      bleScanLog('[BleLamp] FF01: 0x71/0x31/7E（Transport+裸写）已发', toast: true);
      return;
    }
    await _writeProtocolBytes(
      inner7e,
      tag: 'lamp/LEDNET(7E)',
      toastLog: true,
      preferWithResponse: true,
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final zRgb = buildZenggeStaticColorPacket(wr, wg, wb, order: ZenggeRgbWireOrder.rgb);
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
    final zGrb = buildZenggeStaticColorPacket(wr, wg, wb, order: ZenggeRgbWireOrder.grb);
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
        throw Exception('未找到可写特征（需 FFFF/FF01 或 FFE0/FFE1 或 FFE9 等）');
      }

      await _subscribeZenggeNotifications(services);

      _connectedDevice = device;
      _isConnecting = false;
      _lampPowerOn = true;
      notifyListeners();

      bleScanLog(
        '[BleController] 已连接 FF01=${_chrFf01?.uuid} FF11=${_chrFf11?.uuid} '
        'FFE1=${_chrFfe1?.uuid} FFE9=${_chrFfe9?.uuid}',
        toast: true,
      );
      _logWriteTarget('connect后开灯');
      // 连接后默认开灯（LEDnetWF 仅 7E；旧款可能再发 56）
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

  /// 征极 LEDnet 调色：FF01 用 **SDK 0x31**；其它用 **0x7E GRB**。
  /// [r,g,b] 为界面逻辑 RGB；先 [LightRgbCompensation.apply]，再 [_rgbWireCompensateRb]。
  Future<void> updateLightColor(int r, int g, int b) async {
    final t = LightRgbCompensation.instance.apply(r, g, b);
    final w = _rgbWireCompensateRb(t[0], t[1], t[2]);
    final wr = w[0];
    final wg = w[1];
    final wb = w[2];
    if (_hasLednetWfChannels) {
      final p31 = buildZenggeSdkRgbCommand0x31(wr, wg, wb);
      await _writeFf01ZenggeTransport(
        p31,
        tag: 'color ZENGGE 0x31+Transport',
        preferWithResponse: true,
      );
      return;
    }
    await _writeProtocolBytes(buildLednetColorPacket(wr, wg, wb));
  }

  /// 闪烁预设模式
  Future<void> sendBlinkMode() async {
    final inner = buildLednetBlinkPacket();
    if (_hasLednetWfChannels) {
      await _writeFf01ZenggeTransport(
        inner,
        tag: 'blink LEDNET 7E+Transport',
        preferWithResponse: true,
      );
      return;
    }
    await _writeProtocolBytes(inner);
  }

  int _nextTransportSeq() {
    final s = _transportSeq;
    _transportSeq = (_transportSeq + 1) & 0xFF;
    return s;
  }

  /// 与 SDK `write(mac, 0x0b, commandData)` 一致：内层 + **Transport v0**（cmdId=11）。
  /// **FF11 与 FF01 各写一份**（不少应援棒只接 FE00/FF11）。
  Future<void> _writeFf01ZenggeTransport(
    List<int> commandData, {
    required String tag,
    bool toastLog = false,
    bool preferWithResponse = true,
  }) async {
    if (!_hasLednetWfChannels) return;
    final wrapped = encodeLednetWfTransportV0(
      commandData,
      seq: _nextTransportSeq(),
      expectResponse: false,
    );
    await _writeFf01AndFf11Same(
      wrapped,
      tag: tag,
      toastLog: toastLog,
      preferWithResponse: preferWithResponse,
    );
  }

  /// 同一帧依次写入 **FF11**（若存在）与 **FF01**（若存在）。
  Future<void> _writeFf01AndFf11Same(
    List<int> data, {
    required String tag,
    bool toastLog = false,
    bool preferWithResponse = true,
  }) async {
    final ff11 = _chrFf11;
    final ff01 = _chrFf01;
    if (ff11 != null) {
      await _writeProtocolBytes(
        data,
        tag: '$tag→FF11',
        toastLog: toastLog,
        preferWithResponse: preferWithResponse,
        overrideChar: ff11,
      );
    }
    if (ff01 != null) {
      await _writeProtocolBytes(
        data,
        tag: '$tag→FF01',
        toastLog: toastLog,
        preferWithResponse: preferWithResponse,
        overrideChar: ff01,
      );
    }
  }

  /// 不套 Transport，直接把 `commandData` 写到 FF11/FF01。
  Future<void> _writeFf01RawCommandData(
    List<int> commandData, {
    required String tag,
    bool toastLog = false,
  }) async {
    if (!_hasLednetWfChannels) return;
    await _writeFf01AndFf11Same(
      commandData,
      tag: tag,
      toastLog: toastLog,
      preferWithResponse: true,
    );
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

  /// 标准 16 位 UUID：`0000XXXX-0000-1000-8000-00805f9b34fb`
  static bool _uuidHas16Bit(String uuidLower, String short4Hex) {
    final h = short4Hex.toLowerCase();
    return uuidLower.contains('0000$h');
  }

  /// 兼容部分机型 UUID 字符串格式差异（仍避免误匹配 `ffe1`）。
  static bool _uuidLikelyShort(String uuidLower, String short4Hex) {
    final h = short4Hex.toLowerCase();
    if (_uuidHas16Bit(uuidLower, h)) return true;
    if (uuidLower.contains('ffe1')) return false;
    return uuidLower.contains(h);
  }

  /// FFFF/FF01、FE00/FF11（部分应援棒）、FFE0/FFE1、FFE9 等。
  void _assignWriteCharacteristics(List<BluetoothService> services) {
    _chrFf01 = null;
    _chrFf11 = null;
    _chrFfe1 = null;
    _chrFfe9 = null;
    _chrFallback = null;

    bool canWrite(BluetoothCharacteristic c) =>
        c.properties.write || c.properties.writeWithoutResponse;

    for (final service in services) {
      final su = service.uuid.toString().toLowerCase();
      final isFfff = su.contains('ffff');
      final isFe00 = su.contains('fe00');
      final isFfe0 = su.contains('ffe0');
      for (final c in service.characteristics) {
        if (!canWrite(c)) continue;
        final u = c.uuid.toString().toLowerCase();
        if (isFfff && _uuidLikelyShort(u, 'ff01')) {
          _chrFf01 = c;
        }
        if (isFe00 && _uuidLikelyShort(u, 'ff11')) {
          _chrFf11 = c;
        }
        if (isFfe0 && _uuidHas16Bit(u, 'ffe1')) {
          _chrFfe1 = c;
        }
        if (_uuidHas16Bit(u, 'ffe9')) {
          _chrFfe9 = c;
        }
        _chrFallback ??= c;
      }
    }
    if (_chrFf01 == null) {
      for (final service in services) {
        for (final c in service.characteristics) {
          if (!canWrite(c)) continue;
          final u = c.uuid.toString().toLowerCase();
          if (_uuidLikelyShort(u, 'ff01')) {
            _chrFf01 = c;
            break;
          }
        }
        if (_chrFf01 != null) break;
      }
    }
    if (_chrFf11 == null) {
      for (final service in services) {
        for (final c in service.characteristics) {
          if (!canWrite(c)) continue;
          final u = c.uuid.toString().toLowerCase();
          if (_uuidLikelyShort(u, 'ff11')) {
            _chrFf11 = c;
            break;
          }
        }
        if (_chrFf11 != null) break;
      }
    }
    // 少数固件 FFE1 不在 FFE0 服务下
    if (_chrFfe1 == null) {
      for (final service in services) {
        for (final c in service.characteristics) {
          if (!canWrite(c)) continue;
          final u = c.uuid.toString().toLowerCase();
          if (_uuidHas16Bit(u, 'ffe1')) {
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

  /// LEDnetWF：**FFFF** 下 **FF02** notify；旧款：FFE0 下 FFE1/FFE2。
  Future<void> _subscribeZenggeNotifications(List<BluetoothService> services) async {
    for (final sub in _notifySubscriptions) {
      await sub.cancel();
    }
    _notifySubscriptions.clear();

    Future<void> trySub(BluetoothCharacteristic c) async {
      try {
        await c.setNotifyValue(true);
        _notifySubscriptions.add(c.lastValueStream.listen((_) {}));
        bleScanLog('[BleLamp] notify 已开 ${c.uuid}', toast: true);
      } catch (e) {
        bleScanLog('[BleLamp] notify 失败 ${c.uuid}: $e', toast: false);
      }
    }

    for (final service in services) {
      final su = service.uuid.toString().toLowerCase();
      if (su.contains('ffff')) {
        for (final c in service.characteristics) {
          if (!c.properties.notify && !c.properties.indicate) continue;
          final u = c.uuid.toString().toLowerCase();
          if (_uuidHas16Bit(u, 'ff02')) {
            await trySub(c);
          }
        }
      }
    }
    for (final service in services) {
      final su = service.uuid.toString().toLowerCase();
      if (!su.contains('ffe0')) continue;
      for (final c in service.characteristics) {
        if (!c.properties.notify && !c.properties.indicate) continue;
        final u = c.uuid.toString().toLowerCase();
        if (!_uuidHas16Bit(u, 'ffe1') && !_uuidHas16Bit(u, 'ffe2')) continue;
        await trySub(c);
      }
    }
  }

  /// `0x7E` → FF01 优先，其次 FF11（仅当无 FF01），再 FFE1；`0x56` → FFE9。
  BluetoothCharacteristic? _resolveWriteCharForPacket(List<int> data) {
    if (data.isEmpty) return _primaryWriteChar;
    final head = data[0];
    if (head == 0x7E && _chrFf01 != null) return _chrFf01;
    if (head == 0x7E && _chrFf11 != null) return _chrFf11;
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
    _chrFf01 = null;
    _chrFf11 = null;
    _chrFfe1 = null;
    _chrFfe9 = null;
    _chrFallback = null;
    _isConnecting = false;
    _lampPowerOn = false;
    _transportSeq = 0;
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
      final altWwr = !useWithoutResponse;
      try {
        if (altWwr && characteristic.properties.writeWithoutResponse) {
          await characteristic.write(data, withoutResponse: true);
          bleScanLog('[$tag] 写入 OK(已改无响应重试)', toast: toastLog);
          return;
        }
        if (!altWwr && characteristic.properties.write) {
          await characteristic.write(data, withoutResponse: false);
          bleScanLog('[$tag] 写入 OK(已改带响应重试)', toast: toastLog);
          return;
        }
      } catch (_) {}
      bleScanLog('[$tag] 写入失败: $e', toast: true);
      bleScanLog('[$tag] $st', toast: false);
    }
  }
}
