import 'light_controller.dart';

class LightEvent {
  LightEvent(this._controller);

  final LightController _controller;

  void setBrightness(double value) => _controller.setBrightness(value);
  void selectMode(String mode) => _controller.selectMode(mode);
  void selectPreset(int index) => _controller.selectPreset(index);
}
