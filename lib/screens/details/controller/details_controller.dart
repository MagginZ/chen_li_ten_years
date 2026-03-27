import 'package:flutter/material.dart';

class DetailsController extends ChangeNotifier {
  double _batteryLevel = 0.85;
  String _signalStrength = '极佳';
  String _firmwareVersion = 'v3.2.0';
  String _activeTheme = '赛博霓虹粉';

  double get batteryLevel => _batteryLevel;
  String get signalStrength => _signalStrength;
  String get firmwareVersion => _firmwareVersion;
  String get activeTheme => _activeTheme;

  void setBatteryLevel(double value) {
    _batteryLevel = value;
    notifyListeners();
  }

  void disconnect() {
    notifyListeners();
  }
}
