import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../theme/app_colors.dart';
import 'controller/scan_controller.dart';

/// 网页预览无 BLE：填充 10 条假数据便于测布局与交互（连接仍会失败，属预期）。
void fillWebMockScanDevices(ScanController controller) {
  const rows = <(
    String name,
    String mac,
    int rssi,
    bool isLednet,
  )>[
    ('LEDnet-Web-Mock', 'A0:B1:C2:D3:E4:01', -52, true),
    ('果实应援棒 A', 'A0:B1:C2:D3:E4:02', -58, false),
    ('Fruit-Test-03', 'A0:B1:C2:D3:E4:03', -65, false),
    ('匿名广播', 'A0:B1:C2:D3:E4:04', -72, false),
    ('K-POP 棒', 'A0:B1:C2:D3:E4:05', -55, false),
    ('NeonPulse-06', 'A0:B1:C2:D3:E4:06', -80, false),
    ('测试设备 7', 'A0:B1:C2:D3:E4:07', -68, false),
    ('Mock-08', 'A0:B1:C2:D3:E4:08', -61, false),
    ('Mock-09', 'A0:B1:C2:D3:E4:09', -77, false),
    ('Mock-10', 'A0:B1:C2:D3:E4:0A', -59, false),
  ];

  for (final r in rows) {
    final signal = r.$3 > -60 ? '极佳' : (r.$3 > -75 ? '良好' : '一般');
    final signalColor = r.$3 > -60
        ? AppColors.secondary
        : (r.$3 > -75 ? AppColors.tertiary : AppColors.error);
    controller.addDevice(
      ScanDevice(
        device: BluetoothDevice.fromId(r.$2),
        name: r.$1,
        id: r.$2,
        signal: signal,
        signalColor: signalColor,
        isPrimary: r.$3 > -60,
        isLednet: r.$4,
      ),
    );
  }
}
