import 'package:flutter/material.dart';
import 'scan_controller.dart';

class ScanEvent {
  ScanEvent(this._controller);

  final ScanController _controller;

  void rescan() {
    _controller.setScanning(true);
    // Simulate scan completion
    Future.delayed(const Duration(seconds: 2), () {
      _controller.setScanning(false);
    });
  }

  void connectDevice(int index) {
    _controller.connectDevice(index);
  }
}
