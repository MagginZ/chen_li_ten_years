import '../controller/music_controller.dart';

class MusicEvent {
  MusicEvent(this._controller);

  final MusicController _controller;

  Future<void> togglePlay() => _controller.togglePlay();
  void toggleSync() => _controller.toggleSync();
  void setProgress(double value) => _controller.setProgress(value);
  void seekToStart() => _controller.seekToStart();
  void seekToEnd() => _controller.seekToEnd();
}
