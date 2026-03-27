import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../../ble/ble_controller.dart' show BleController, syncScript;
import 'music_list_controller.dart';

class MusicController extends ChangeNotifier {
  MusicController({this.initialTrack}) {
    _durationSub = _player.durationStream.listen((d) {
      if (d != null) {
        _duration = d;
        notifyListeners();
      }
    });
    _positionSub = _player.positionStream.listen(_onPositionChanged);
    _stateSub = _player.playerStateStream.listen((s) {
      _isPlaying = s.playing;
      notifyListeners();
    });
  }

  final MusicTrack? initialTrack;
  MusicTrack? _currentTrack;
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription? _durationSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _stateSub;
  final Set<int> _triggeredSeconds = {};

  /// 防止连续切歌时，先发出的 `setUrl` 后完成、覆盖后选曲目。
  int _loadGeneration = 0;

  bool _isPlaying = false;
  double _progress = 0.0;
  Duration _position = Duration.zero;
  Duration _duration = const Duration(seconds: 60);

  MusicTrack? get currentTrack => _currentTrack ?? initialTrack;
  String get trackTitle => currentTrack?.title ?? '果实音乐';
  String get artist => currentTrack?.artist ?? '陈粒';

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

  Future<void> switchTrack(MusicTrack track) async {
    _currentTrack = track;
    await _loadTrack(track);
  }

  bool _isStaleLoad(int gen) => gen != _loadGeneration;

  Future<void> _loadTrack(MusicTrack? track) async {
    final gen = ++_loadGeneration;

    try {
      await _player.stop();
    } catch (_) {}

    if (_isStaleLoad(gen)) return;

    final streamUrl = track?.streamUrl;
    if (_isPlayableUrl(streamUrl)) {
      try {
        await _player.setUrl(streamUrl!);
        if (_isStaleLoad(gen)) return;
        debugPrint('[MusicController] Playing from NCM: $streamUrl');
        await _player.play();
        if (_isStaleLoad(gen)) return;
        _isPlaying = true;
        notifyListeners();
        return;
      } catch (e) {
        debugPrint('[MusicController] setUrl failed, fallback: $e');
        if (_isStaleLoad(gen)) return;
      }
    }
    try {
      await _player.setAsset('assets/audio/mock_music.mp3');
      if (_isStaleLoad(gen)) return;
      debugPrint('[MusicController] Using fallback asset');
      await _player.play();
      if (_isStaleLoad(gen)) return;
      _isPlaying = true;
      notifyListeners();
    } catch (e) {
      debugPrint('[MusicController] Asset failed, using SoundHelix: $e');
      if (_isStaleLoad(gen)) return;
      try {
        await _player.setUrl(
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
        );
        if (_isStaleLoad(gen)) return;
        await _player.play();
        if (_isStaleLoad(gen)) return;
        _isPlaying = true;
        notifyListeners();
      } catch (e2) {
        debugPrint('[MusicController] setUrl failed: $e2');
      }
    }
  }

  Future<void> togglePlay() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.play();
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

  @override
  void dispose() {
    _durationSub?.cancel();
    _positionSub?.cancel();
    _stateSub?.cancel();
    _player.dispose();
    super.dispose();
  }
}
