import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class LightController extends ChangeNotifier {
  double _brightness = 0.84;
  String _selectedMode = 'Standard';
  int _selectedPreset = 0;

  static const List<Map<String, dynamic>> modes = [
    {'name': 'Standard', 'icon': Icons.radio_button_checked},
    {'name': 'Blink', 'icon': Icons.vibration},
    {'name': 'Flash', 'icon': Icons.flash_on},
    {'name': 'Breath', 'icon': Icons.air},
  ];

  static const List<Color> presets = [
    AppColors.primary,
    AppColors.onSurface,
    AppColors.secondaryFixed,
    AppColors.tertiary,
    AppColors.primaryContainer,
  ];

  double get brightness => _brightness;
  String get selectedMode => _selectedMode;
  int get selectedPreset => _selectedPreset;

  void setBrightness(double value) {
    _brightness = value.clamp(0.0, 1.0);
    notifyListeners();
  }

  void selectMode(String mode) {
    _selectedMode = mode;
    notifyListeners();
  }

  void selectPreset(int index) {
    _selectedPreset = index;
    notifyListeners();
  }
}
