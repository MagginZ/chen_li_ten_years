import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class LightController extends ChangeNotifier {
  double _brightness = 0.84;
  String _selectedMode = 'Standard';
  int _selectedPreset = 0;
  Color _selectedColor = AppColors.primary;

  static const List<Map<String, dynamic>> modes = [
    {'name': 'Standard', 'icon': Icons.radio_button_checked},
    {'name': 'Blink', 'icon': Icons.vibration},
    {'name': 'Flash', 'icon': Icons.flash_on},
    {'name': 'Breath', 'icon': Icons.air},
  ];

  /// Fandom Presets: 粉、白、蓝、紫
  static const List<Color> presets = [
    Color(0xFFFF89AB), // 粉
    Color(0xFFF8F5FD), // 白
    Color(0xFF26E6FF), // 蓝/青
    Color(0xFFAC89FF), // 紫
  ];

  double get brightness => _brightness;
  String get selectedMode => _selectedMode;
  int get selectedPreset => _selectedPreset;
  Color get selectedColor => _selectedColor;

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
    _selectedColor = presets[index];
    notifyListeners();
  }

  void setColor(Color color) {
    _selectedColor = color;
    notifyListeners();
  }

  /// 将 Color 转为 RGB 数组 [R, G, B]
  List<int> colorToRgb(Color color) {
    return [color.red, color.green, color.blue];
  }
}
