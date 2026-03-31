import '../controller/music_controller.dart';

class MusicEvent {
  MusicEvent(this._controller);

  final MusicController _controller;

  Future<void> togglePlay() => _controller.togglePlay();
  void toggleSync() => _controller.toggleSync();
  void setUseMetronomeBeatSync(bool value) => _controller.setUseMetronomeBeatSync(value);
  void setBpm(double value) => _controller.setBpm(value);
  void setProgress(double value) => _controller.setProgress(value);
  void seekToStart() => _controller.seekToStart();
  void seekToEnd() => _controller.seekToEnd();
}
