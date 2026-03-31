import 'package:flutter/material.dart';

class DetailsController extends ChangeNotifier {
  double _batteryLevel = 0.85;
  String _signalStrength = '极佳';
  String _firmwareVersion = 'v3.2.0';

  double get batteryLevel => _batteryLevel;
  String get signalStrength => _signalStrength;
  String get firmwareVersion => _firmwareVersion;

  void setBatteryLevel(double value) {
    _batteryLevel = value;
    notifyListeners();
  }

  void disconnect() {
    notifyListeners();
  }
}
