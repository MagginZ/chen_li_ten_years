import '../../../ble/ble_controller.dart';
import '../controller/details_controller.dart';

class DetailsEvent {
  DetailsEvent(this._controller);

  final DetailsController _controller;

  void toggleAutoSync() {
    final ble = BleController.instance;
    ble.setAutoSync(!ble.autoSyncEnabled);
  }

  void disconnect() {
    BleController.instance.disconnect();
    _controller.disconnect();
  }
}
