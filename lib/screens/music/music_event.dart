import 'music_controller.dart';

class MusicEvent {
  MusicEvent(this._controller);

  final MusicController _controller;

  void togglePlay() => _controller.togglePlay();
  void toggleSync() => _controller.toggleSync();
  void setProgress(double value) => _controller.setProgress(value);
  void skipPrevious() => _controller.skipPrevious();
  void skipNext() => _controller.skipNext();
  void shuffle() => _controller.shuffle();
  void repeat() => _controller.repeat();
}
