import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../ble/ble_controller.dart' show BleController, syncScript;
import 'music_list_controller.dart';

class MusicController extends ChangeNotifier {
  MusicController({this.initialTrack}) {
    _player.onDurationChanged.listen((d) {
      _duration = d;
      notifyListeners();
    });
    _player.onPositionChanged.listen(_onPositionChanged);
  }

  final MusicTrack? initialTrack;
  MusicTrack? _currentTrack;
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription? _positionSub;
  final Set<int> _triggeredSeconds = {};

  bool _isPlaying = false;
  double _progress = 0.0;
  Duration _position = Duration.zero;
  Duration _duration = const Duration(seconds: 60);

  MusicTrack? get currentTrack => _currentTrack ?? initialTrack;
  String get trackTitle => currentTrack?.title ?? 'Stitch Colors';
  String get artist => currentTrack?.artist ?? 'Chen Li';

  bool get isPlaying => _isPlaying;
  bool get syncEnabled => BleController.instance.autoSyncEnabled;
  double get progress => _progress;
  Duration get position => _position;
  Duration get duration => _duration;

  void _onPositionChanged(Duration pos) {
    _position = pos;
    _progress = _duration.inMilliseconds > 0
        ? pos.inMilliseconds / _duration.inMilliseconds
        : 0.0;

    if (pos.inSeconds < 2) {
      _triggeredSeconds.clear();
    }

    if (BleController.instance.autoSyncEnabled) {
      final sec = pos.inSeconds;
      if (syncScript.containsKey(sec) && !_triggeredSeconds.contains(sec)) {
        _triggeredSeconds.add(sec);
        BleController.instance.triggerSyncAt(sec);
      }
    }
    notifyListeners();
  }

  /// 是否为可播放的音频 URL（直接链接，如网易云返回的 mp3/m4a）
  bool _isPlayableUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    final lower = url.toLowerCase();
    if (lower.contains('youtube') || lower.contains('youtu.be')) return false;
    return lower.startsWith('http://') || lower.startsWith('https://');
  }

  Future<void> init() async {
    _currentTrack = initialTrack;
    await _loadTrack(_currentTrack);
  }

  /// 切换到指定曲目（上一首/下一首）
  Future<void> switchTrack(MusicTrack track) async {
    _currentTrack = track;
    await _loadTrack(track);
  }

  Future<void> _loadTrack(MusicTrack? track) async {
    final streamUrl = track?.streamUrl;
    if (_isPlayableUrl(streamUrl)) {
      try {
        await _player.setSource(UrlSource(streamUrl!));
        debugPrint('[MusicController] Playing from NCM: $streamUrl');
        await _player.resume();
        _isPlaying = true;
        notifyListeners();
        return;
      } catch (e) {
        debugPrint('[MusicController] UrlSource failed, fallback: $e');
      }
    }
    try {
      await _player.setSource(AssetSource('assets/audio/mock_music.mp3'));
      debugPrint('[MusicController] Using fallback asset');
    } catch (e) {
      debugPrint('[MusicController] Asset failed, using SoundHelix: $e');
      try {
        await _player.setSource(UrlSource(
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
        ));
      } catch (e2) {
        debugPrint('[MusicController] UrlSource failed: $e2');
      }
    }
  }

  Future<void> togglePlay() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.resume();
    }
    _isPlaying = !_isPlaying;
    notifyListeners();
  }

  void toggleSync() {
    BleController.instance.setAutoSync(!BleController.instance.autoSyncEnabled);
    notifyListeners();
  }

  void setProgress(double value) {
    _progress = value.clamp(0.0, 1.0);
    final ms = (_duration.inMilliseconds * _progress).round();
    _player.seek(Duration(milliseconds: ms));
    notifyListeners();
  }

  void seekToStart() => _player.seek(Duration.zero);
  void seekToEnd() => _player.seek(_duration);
  void shuffle() => notifyListeners();
  void repeat() => notifyListeners();

  @override
  void dispose() {
    _positionSub?.cancel();
    _player.dispose();
    super.dispose();
  }
}
