import 'package:flutter/material.dart';
import 'controller/music_controller.dart';
import 'controller/music_list_controller.dart';
import 'event/music_event.dart';
import 'music_list_screen.dart';
import 'music_screen.dart';

/// 音乐 Tab：列表与播放详情共用 [MusicListController] + [MusicController]，
/// 使用 [IndexedStack] 同时挂载，避免切换时列表卸载；切歌时同步 `nowPlayingIndex`。
class MusicTabScreen extends StatefulWidget {
  const MusicTabScreen({super.key});

  @override
  State<MusicTabScreen> createState() => _MusicTabScreenState();
}

class _MusicTabScreenState extends State<MusicTabScreen> {
  final MusicListController _listController = MusicListController();
  late final MusicController _playback;
  late final MusicEvent _musicEvent;
  bool _showPlayer = false;

  @override
  void initState() {
    super.initState();
    _playback = MusicController();
    _musicEvent = MusicEvent(_playback);
  }

  bool _sameLoadedTrack(MusicTrack track) =>
      _playback.currentTrack?.id == track.id;

  /// 左侧封面：当前行正在播 → 暂停/继续；其他行 → 切歌并播放。
  Future<void> _onCoverTap(MusicTrack track, int index) async {
    _listController.selectTrack(index);
    if (_sameLoadedTrack(track)) {
      await _musicEvent.togglePlay();
      return;
    }
    await _playback.switchTrack(track);
    if (mounted) setState(() => _showPlayer = true);
  }

  /// 标题/右侧区域：同一首已加载则只打开详情（不重新 setUrl）；否则切歌并打开。
  Future<void> _onRowOpenDetail(MusicTrack track, int index) async {
    _listController.selectTrack(index);
    if (_sameLoadedTrack(track)) {
      if (mounted) setState(() => _showPlayer = true);
      return;
    }
    await _playback.switchTrack(track);
    if (mounted) setState(() => _showPlayer = true);
  }

  @override
  void dispose() {
    _playback.dispose();
    _listController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: _showPlayer ? 1 : 0,
      sizing: StackFit.expand,
      children: [
        MusicListScreen(
          controller: _listController,
          playback: _playback,
          onCoverTap: _onCoverTap,
          onRowOpenDetail: _onRowOpenDetail,
        ),
        MusicScreen(
          listController: _listController,
          playback: _playback,
          event: _musicEvent,
          onBack: () => setState(() => _showPlayer = false),
        ),
      ],
    );
  }
}
