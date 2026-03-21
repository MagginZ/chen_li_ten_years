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
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription? _positionSub;
  final Set<int> _triggeredSeconds = {};

  bool _isPlaying = false;
  double _progress = 0.0;
  Duration _position = Duration.zero;
  Duration _duration = const Duration(seconds: 60);

  String get trackTitle => initialTrack?.title ?? 'Stitch Colors';
  String get artist => initialTrack?.artist ?? 'Chen Li';

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

  /// 是否为可直接播放的音频 URL（排除 YouTube）
  bool _isDirectAudioUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    final lower = url.toLowerCase();
    if (lower.contains('youtube') || lower.contains('youtu.be')) return false;
    return lower.contains('.mp3') ||
        lower.contains('.m4a') ||
        lower.contains('.aac') ||
        lower.contains('.ogg') ||
        lower.contains('.wav');
  }

  Future<void> init() async {
    final streamUrl = initialTrack?.streamUrl;
    if (streamUrl != null && _isDirectAudioUrl(streamUrl)) {
      try {
        await _player.setSource(UrlSource(streamUrl));
        debugPrint('[MusicController] Playing from API: $streamUrl');
        return;
      } catch (e) {
        debugPrint('[MusicController] UrlSource failed, fallback to asset: $e');
      }
    }
    try {
      await _player.setSource(AssetSource('assets/audio/mock_music.mp3'));
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

  void skipPrevious() => _player.seek(Duration.zero);
  void skipNext() => _player.seek(_duration);
  void shuffle() => notifyListeners();
  void repeat() => notifyListeners();

  @override
  void dispose() {
    _positionSub?.cancel();
    _player.dispose();
    super.dispose();
  }
}
