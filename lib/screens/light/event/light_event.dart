import 'package:flutter/material.dart';
import '../../../ble/ble_controller.dart';
import '../controller/light_controller.dart';

class LightEvent {
  LightEvent(this._controller);

  final LightController _controller;

  void setBrightness(double value) => _controller.setBrightness(value);

  void selectMode(String mode) => _controller.selectMode(mode);

  void selectPreset(int index) {
    _controller.selectPreset(index);
    final rgb = _controller.colorToRgb(LightController.presets[index]);
    BleController.instance.writeRgb(rgb);
  }

  /// 色盘选择颜色时调用，实时发送 RGB 指令
  void selectColor(Color color) {
    _controller.setColor(color);
    final rgb = _controller.colorToRgb(color);
    BleController.instance.writeRgb(rgb);
  }
}
