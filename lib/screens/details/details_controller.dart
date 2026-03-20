import 'package:flutter/material.dart';

class DetailsController extends ChangeNotifier {
  double _batteryLevel = 0.85;
  String _signalStrength = 'Excellent';
  String _firmwareVersion = 'v3.2.0';
  String _activeTheme = 'Cyberpunk Neon Pink';
  bool _autoSyncEnabled = true;

  double get batteryLevel => _batteryLevel;
  String get signalStrength => _signalStrength;
  String get firmwareVersion => _firmwareVersion;
  String get activeTheme => _activeTheme;
  bool get autoSyncEnabled => _autoSyncEnabled;

  void setBatteryLevel(double value) {
    _batteryLevel = value;
    notifyListeners();
  }

  void setAutoSync(bool value) {
    _autoSyncEnabled = value;
    notifyListeners();
  }

  void disconnect() {
    notifyListeners();
  }
}
