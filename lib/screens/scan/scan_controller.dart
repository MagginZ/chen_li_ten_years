import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class ScanDevice {
  final String name;
  final String id;
  final String signal;
  final Color signalColor;
  final bool isPrimary;

  const ScanDevice({
    required this.name,
    required this.id,
    required this.signal,
    required this.signalColor,
    required this.isPrimary,
  });
}

class ScanController extends ChangeNotifier {
  bool _isScanning = true;
  final List<ScanDevice> _devices = [
    const ScanDevice(
      name: 'Official Lightstick V2',
      id: 'LP-8842-X',
      signal: 'Excellent',
      signalColor: AppColors.secondary,
      isPrimary: true,
    ),
    const ScanDevice(
      name: 'Fan Stick 01',
      id: 'FS-1102-K',
      signal: 'Fair',
      signalColor: AppColors.tertiary,
      isPrimary: false,
    ),
    const ScanDevice(
      name: 'Pulse Core Beta',
      id: 'PC-9900-M',
      signal: 'Excellent',
      signalColor: AppColors.secondary,
      isPrimary: true,
    ),
  ];

  bool get isScanning => _isScanning;
  List<ScanDevice> get devices => List.unmodifiable(_devices);

  void setScanning(bool value) {
    _isScanning = value;
    notifyListeners();
  }

  void connectDevice(int index) {
    notifyListeners();
  }

  void updateDevices(List<ScanDevice> newDevices) {
    _devices.clear();
    _devices.addAll(newDevices);
    notifyListeners();
  }
}
