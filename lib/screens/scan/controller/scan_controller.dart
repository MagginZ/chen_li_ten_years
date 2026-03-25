import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../../ble/ble_controller.dart';

class ScanDevice {
  final BluetoothDevice device;
  final String name;
  final String id;
  final String signal;
  final Color signalColor;
  final bool isPrimary;

  const ScanDevice({
    required this.device,
    required this.name,
    required this.id,
    required this.signal,
    required this.signalColor,
    required this.isPrimary,
  });
}

class ScanController extends ChangeNotifier {
  bool _isScanning = false;
  final List<ScanDevice> _devices = [];
  final Set<String> _seenIds = {};

  bool get isScanning => _isScanning;
  List<ScanDevice> get devices => List.unmodifiable(_devices);

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

  Future<void> connectDevice(int index) async {
    if (index < 0 || index >= _devices.length) return;
    final device = _devices[index];
    await BleController.instance.connect(device.device);
    notifyListeners();
  }
}
