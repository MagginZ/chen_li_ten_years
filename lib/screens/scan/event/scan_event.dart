import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../../theme/app_colors.dart';
import '../controller/scan_controller.dart';

class ScanEvent {
  ScanEvent(this._controller);

  final ScanController _controller;
  StreamSubscription<List<ScanResult>>? _scanSubscription;

  void rescan() {
    _controller.clearDevices();
    _controller.setScanning(true);
    _startScan();
  }

  Future<void> _startScan() async {
    await _scanSubscription?.cancel();

    try {
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (final r in results) {
          final name = r.device.platformName.isNotEmpty
              ? r.device.platformName
              : 'Lightstick ${r.device.remoteId.str.length >= 8 ? r.device.remoteId.str.substring(0, 8) : r.device.remoteId.str}';
          final id = r.device.remoteId.str;
          final rssi = r.rssi;
          final signal = rssi > -60 ? 'Excellent' : (rssi > -75 ? 'Good' : 'Fair');
          final signalColor = rssi > -60
              ? AppColors.secondary
              : (rssi > -75 ? AppColors.tertiary : AppColors.error);

          _controller.addDevice(ScanDevice(
            device: r.device,
            name: name,
            id: id,
            signal: signal,
            signalColor: signalColor,
            isPrimary: rssi > -60,
          ));
        }
      });

      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
    } catch (e) {
      debugPrint('[ScanEvent] Bluetooth scan error: $e');
    } finally {
      await FlutterBluePlus.stopScan();
      await _scanSubscription?.cancel();
      _scanSubscription = null;
      _controller.setScanning(false);
    }
  }

  Future<void> connectDevice(int index) async {
    await _controller.connectDevice(index);
  }

  void dispose() {
    _scanSubscription?.cancel();
  }
}
