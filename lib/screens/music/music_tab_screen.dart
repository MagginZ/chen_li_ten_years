import 'package:flutter/material.dart';
import 'controller/music_list_controller.dart';
import 'music_list_screen.dart';
import 'music_screen.dart';

/// Music Tab 包装器：默认显示歌单列表，点击歌曲后显示播放页
class MusicTabScreen extends StatefulWidget {
  const MusicTabScreen({super.key});

  @override
  State<MusicTabScreen> createState() => _MusicTabScreenState();
}

class _MusicTabScreenState extends State<MusicTabScreen> {
  bool _showPlayer = false;
  MusicTrack? _selectedTrack;

  void _onTrackTap(MusicTrack track) {
    setState(() {
      _selectedTrack = track;
      _showPlayer = true;
    });
  }

  void _onBack() {
    setState(() {
      _showPlayer = false;
      _selectedTrack = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showPlayer) {
      return MusicScreen(
        track: _selectedTrack,
        onBack: _onBack,
      );
    }
    return MusicListScreen(onTrackTap: _onTrackTap);
  }
}
