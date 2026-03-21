import '../controller/music_list_controller.dart';

class MusicListEvent {
  MusicListEvent(this._controller);

  final MusicListController _controller;

  void toggleSync() => _controller.toggleSync();

  void selectTrack(int index) => _controller.selectTrack(index);
}
