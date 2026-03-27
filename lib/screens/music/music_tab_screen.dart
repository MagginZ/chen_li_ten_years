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

  /// 列表项已调用 [MusicListController.selectTrack]，此处只加载音频并展开播放层。
  Future<void> _onTrackTap(MusicTrack track) async {
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
          onTrackTap: _onTrackTap,
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
