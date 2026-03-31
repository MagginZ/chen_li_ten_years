import 'dart:async';

import 'package:flutter/material.dart';

import '../../../ble/ble_controller.dart';
import '../controller/light_controller.dart';

class LightEvent {
  LightEvent(this._controller);

  final LightController _controller;

  /// 最多约 20 次/秒（50ms）
  static const Duration _debounce = Duration(milliseconds: 50);
  Timer? _debounceTimer;

  void dispose() {
    _debounceTimer?.cancel();
  }

  void setBrightness(double value) {
    _controller.setBrightness(value);
    _scheduleDebouncedLightUpdate();
  }

  void selectMode(String mode) {
    _controller.selectMode(mode);
    if (mode == '闪烁') {
      BleController.instance.sendBlinkMode().catchError((Object e, StackTrace st) {
        debugPrint('[LightEvent] sendBlinkMode failed: $e');
      });
    }
  }

  void selectPreset(int index) {
    _controller.selectPreset(index);
    final rgb = _controller.colorToRgb(LightController.presets[index]);
    _pushScaledRgb(rgb);
  }

  void previewColor(Color color, Offset offset) {
    _controller.setPickerOffset(offset);
    _controller.setColor(color);
    _scheduleDebouncedLightUpdate();
  }

  void commitColor(Color color, Offset offset) {
    _debounceTimer?.cancel();
    _controller.setPickerOffset(offset);
    _controller.setColor(color);
    _pushScaledRgb(_controller.colorToRgb(color));
  }

  void _scheduleDebouncedLightUpdate() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounce, () {
      _pushScaledRgb(_controller.colorToRgb(_controller.selectedColor));
    });
  }

  void _pushScaledRgb(List<int> rgb) {
    if (rgb.length < 3) return;
    final b = _controller.brightness;
    final r = (rgb[0] * b).round().clamp(0, 255);
    final g = (rgb[1] * b).round().clamp(0, 255);
    final bl = (rgb[2] * b).round().clamp(0, 255);
    BleController.instance.updateLightColor(r, g, bl).catchError((Object e, StackTrace st) {
      debugPrint('[LightEvent] updateLightColor failed: $e');
    });
  }
}
