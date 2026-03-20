import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../ble/ble_controller.dart';

class ScanDevice {
  final String name;
  final String id;
  final String signal;
  final Color signalColor;
  final bool isPrimary;
  final bool isMock;

  const ScanDevice({
    required this.name,
    required this.id,
    required this.signal,
    required this.signalColor,
    required this.isPrimary,
    this.isMock = false,
  });
}

class ScanController extends ChangeNotifier {
  bool _isScanning = false;
  final List<ScanDevice> _devices = [];
  final Set<String> _seenIds = {};

  static const ScanDevice mockDevice = ScanDevice(
    name: 'Official Lightstick V2',
    id: 'LP-8842-X',
    signal: 'Excellent',
    signalColor: AppColors.secondary,
    isPrimary: true,
    isMock: true,
  );

  bool get isScanning => _isScanning;
  List<ScanDevice> get devices {
    final list = <ScanDevice>[mockDevice];
    list.addAll(_devices);
    return list;
  }

  void setScanning(bool value) {
    _isScanning = value;
    notifyListeners();
  }

  void clearDevices() {
    _devices.clear();
    _seenIds.clear();
    notifyListeners();
  }

  void addDevice(ScanDevice device) {
    if (_seenIds.contains(device.id)) return;
    _seenIds.add(device.id);
    _devices.add(device);
    notifyListeners();
  }

  void connectDevice(int index) {
    final list = devices;
    if (index < 0 || index >= list.length) return;
    final d = list[index];
    if (d.isMock) {
      BleController.instance.mockConnect();
    } else {
      // TODO: 真实设备连接
      notifyListeners();
    }
  }
}
