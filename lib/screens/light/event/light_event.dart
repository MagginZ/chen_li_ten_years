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
    _safeWriteRgb(rgb);
  }

  void previewColor(Color color, Offset offset) {
    _controller.setPickerOffset(offset);
    _controller.setColor(color);
  }

  void commitColor(Color color, Offset offset) {
    _controller.setPickerOffset(offset);
    _controller.setColor(color);
    final rgb = _controller.colorToRgb(color);
    _safeWriteRgb(rgb);
  }

  void _safeWriteRgb(List<int> rgb) {
    BleController.instance.writeRgb(rgb).catchError((error, stackTrace) {
      debugPrint('[LightEvent] writeRgb failed: $error');
    });
  }
}
