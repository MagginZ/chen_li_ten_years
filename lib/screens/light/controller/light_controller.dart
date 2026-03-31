import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class LightController extends ChangeNotifier {
  double _brightness = 0.84;
  String _selectedMode = '标准';
  int _selectedPreset = 0;
  Color _selectedColor = AppColors.primary;
  late Offset _pickerOffset = pickerOffsetForColor(AppColors.primary);

  /// 与 [LightScreen] 色环尺寸一致，用于初始/预设时拾色器落在正确色相位置。
  static const double wheelSize = 320;
  static const double wheelOuterRadius = wheelSize / 2;
  static const double wheelInnerRadius = 60;
  static const double pickerSize = 40;
  static double get pickerTrackRadius =>
      (wheelInnerRadius + wheelOuterRadius - pickerSize) / 2;

  static Offset pickerOffsetForHue(double hueDeg) {
    const c = wheelSize / 2;
    final rad = hueDeg * math.pi / 180;
    return Offset(
      c + math.cos(rad) * pickerTrackRadius,
      c + math.sin(rad) * pickerTrackRadius,
    );
  }

  static Offset pickerOffsetForColor(Color color) {
    return pickerOffsetForHue(HSVColor.fromColor(color).hue);
  }

  static const List<Map<String, dynamic>> modes = [
    {'name': '标准', 'icon': Icons.radio_button_checked},
    {'name': '闪烁', 'icon': Icons.vibration},
    {'name': '爆闪', 'icon': Icons.flash_on},
    {'name': '呼吸', 'icon': Icons.air},
  ];

  /// Fandom Presets: 绿、白、蓝、紫
  static const List<Color> presets = [
    Color(0xFF94D962), // 绿
    Color(0xFFF8F5FD), // 白
    Color(0xFF26E6FF), // 蓝/青
    Color(0xFFAC89FF), // 紫
  ];

  double get brightness => _brightness;
  String get selectedMode => _selectedMode;
  int get selectedPreset => _selectedPreset;
  Color get selectedColor => _selectedColor;
  Offset get pickerOffset => _pickerOffset;

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
    _pickerOffset = pickerOffsetForColor(presets[index]);
    notifyListeners();
  }

  void setColor(Color color) {
    _selectedColor = color;
    notifyListeners();
  }

  void setPickerOffset(Offset offset) {
    _pickerOffset = offset;
    notifyListeners();
  }

  /// 将 Color 转为 RGB 数组 [R, G, B]（逻辑 RGB，下发时由协议层做 GRB 等线序）
  List<int> colorToRgb(Color color) {
    return [
      (color.r * 255.0).round().clamp(0, 255),
      (color.g * 255.0).round().clamp(0, 255),
      (color.b * 255.0).round().clamp(0, 255),
    ];
  }
}
