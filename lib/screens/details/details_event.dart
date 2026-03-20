import 'details_controller.dart';

class DetailsEvent {
  DetailsEvent(this._controller);

  final DetailsController _controller;

  void toggleAutoSync() {
    _controller.setAutoSync(!_controller.autoSyncEnabled);
  }

  void disconnect() {
    _controller.disconnect();
  }
}
