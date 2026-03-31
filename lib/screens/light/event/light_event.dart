import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../ble/ble_controller.dart';
import '../controller/light_controller.dart';

class LightEvent {
  LightEvent(this._controller);

  final LightController _controller;

  /// 最多约 20 次/秒（50ms）
  static const Duration _debounce = Duration(milliseconds: 50);
  Timer? _debounceTimer;
  Timer? _breathTimer;
  double _breathMul = 1.0;
  double _breathPhase = 0;

  void dispose() {
    _debounceTimer?.cancel();
    _breathTimer?.cancel();
  }

  void _stopBreathing() {
    _breathTimer?.cancel();
    _breathTimer = null;
    _breathMul = 1.0;
  }

  void _startBreathing() {
    _breathTimer?.cancel();
    _breathPhase = 0;
    void tick() {
      if (_controller.selectedMode != '呼吸') {
        _breathTimer?.cancel();
        _breathTimer = null;
        _breathMul = 1.0;
        return;
      }
      _breathPhase += 0.08;
      _breathMul = 0.35 + 0.65 * (0.5 + 0.5 * math.sin(_breathPhase));
      _pushScaledRgb(_controller.colorToRgb(_controller.selectedColor));
    }

    tick();
    _breathTimer = Timer.periodic(const Duration(milliseconds: 50), (_) => tick());
  }

  Future<void> _burstBlink() async {
    for (var i = 0; i < 4; i++) {
      await BleController.instance.sendBlinkMode();
      if (i < 3) await Future<void>.delayed(const Duration(milliseconds: 90));
    }
  }

  void setBrightness(double value) {
    _controller.setBrightness(value);
    _scheduleDebouncedLightUpdate();
  }

  void selectMode(String mode) {
    _stopBreathing();
    _controller.selectMode(mode);
    switch (mode) {
      case '闪烁':
        BleController.instance.sendBlinkMode().catchError((Object e, StackTrace st) {
          debugPrint('[LightEvent] sendBlinkMode failed: $e');
        });
        break;
      case '爆闪':
        _burstBlink().catchError((Object e, StackTrace st) {
          debugPrint('[LightEvent] burst blink failed: $e');
        });
        break;
      case '呼吸':
        _startBreathing();
        break;
      case '标准':
      default:
        _pushScaledRgb(_controller.colorToRgb(_controller.selectedColor));
        break;
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
    final b = _controller.brightness * _breathMul;
    final r = (rgb[0] * b).round().clamp(0, 255);
    final g = (rgb[1] * b).round().clamp(0, 255);
    final bl = (rgb[2] * b).round().clamp(0, 255);
    BleController.instance.updateLightColor(r, g, bl).catchError((Object e, StackTrace st) {
      debugPrint('[LightEvent] updateLightColor failed: $e');
    });
  }
}
