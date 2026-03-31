/// 协议层 RGB 通道顺序（与 WS2812 等灯珠物理顺序不同）。征极/ZENGGE 常见静态色见 [buildZenggeStaticColorPacket]。
enum ZenggeRgbWireOrder {
  /// 文档标准：`56 R G B 00 F0 AA`
  rgb,

  /// 灯珠为 GRB：`56 G R B 00 F0 AA`（与「排序类型 GRB」一致时常用）
  grb,
}

/// 静态颜色 7 字节包：`56 + 三色 + 00 F0 AA`（Magic Hue / 征极文档：三色为 **R G B** 顺序）。
/// 实际 BLE 写入应落在 **FFE9**；`0x7E` LEDnet 包写在 **FFE1**（见 [BleController] 路由）。
List<int> buildZenggeStaticColorPacket(
  int r,
  int g,
  int b, {
  ZenggeRgbWireOrder order = ZenggeRgbWireOrder.grb,
}) {
  final rr = r.clamp(0, 255);
  final gg = g.clamp(0, 255);
  final bb = b.clamp(0, 255);
  late final int c1, c2, c3;
  switch (order) {
    case ZenggeRgbWireOrder.rgb:
      c1 = rr;
      c2 = gg;
      c3 = bb;
      break;
    case ZenggeRgbWireOrder.grb:
      c1 = gg;
      c2 = rr;
      c3 = bb;
      break;
  }
  return [0x56, c1, c2, c3, 0x00, 0xF0, 0xAA];
}

// --- LEDnet / 征极 FFE0+FFE1 方案（包头 0x7E，包尾 0xEF，调色字节为 GRB） ---

/// **LEDnetWF（FFFF/FF01）**：裸 `0x7E…` 无效，必须先套 **Transport v0** 再写入 FF01。
/// 参考：lednetwf_ble 仓库 protocol_docs/04_connection_transport.md。
List<int> encodeLednetWfTransportV0(
  List<int> payload, {
  int seq = 0,
  bool expectResponse = false,
}) {
  final n = payload.length;
  final cmdId = expectResponse ? 10 : 11;
  return <int>[
    0x00,
    seq & 0xFF,
    0x80,
    0x00,
    (n >> 8) & 0xFF,
    n & 0xFF,
    (n + 1) & 0xFF,
    cmdId,
    ...payload,
  ];
}

/// **征极 SDK / lednetwf** 的 RGB 命令：`0x31` + R,G,B + WW,CW + mode + persist + **checksum**。
/// 与 [Android SDK `write(..., 0x0b, commandData)`](http://cnwifidevsdk.magichue.net:4000/ble/AndroidSdk.html) 中 `commandData` 常见形态一致（再由固件加 Transport）。
/// 参考：lednetwf_ble `protocol_docs/05_basic_commands.md`（checksum = sum(前 8 字节) & 0xFF）。
List<int> buildZenggeSdkRgbCommand0x31(
  int r,
  int g,
  int b, {
  bool persistToFlash = false,
}) {
  final rr = r.clamp(0, 255);
  final gg = g.clamp(0, 255);
  final bb = b.clamp(0, 255);
  const int ww = 0;
  const int cw = 0;
  const mode = 0xF0;
  final persist = persistToFlash ? 0xF0 : 0x0F;
  final body = <int>[0x31, rr, gg, bb, ww, cw, mode, persist];
  final chk = body.fold<int>(0, (a, e) => a + e) & 0xFF;
  return [...body, chk];
}

/// 旧版电源（部分固件需先开关再调色）：`0x71` + 0x23 开 / 0x24 关 + persist + checksum。
List<int> buildZenggeSdkLegacyPower0x71(bool on, {bool persistToFlash = false}) {
  final open = on ? 0x23 : 0x24;
  final persist = persistToFlash ? 0xF0 : 0x0F;
  final body = <int>[0x71, open, persist];
  final chk = body.fold<int>(0, (a, e) => a + e) & 0xFF;
  return [...body, chk];
}

/// 调色指令：`7E 05 03 G R B 00 EF`
List<int> buildLednetColorPacket(int r, int g, int b) {
  final rr = r.clamp(0, 255);
  final gg = g.clamp(0, 255);
  final bb = b.clamp(0, 255);
  return [0x7E, 0x05, 0x03, gg, rr, bb, 0x00, 0xEF];
}

/// Blink（闪烁）预设示例（可按固件微调）
List<int> buildLednetBlinkPacket() {
  return [0x7E, 0x04, 0x01, 0x00, 0xFF, 0xFF, 0x00, 0xEF];
}
