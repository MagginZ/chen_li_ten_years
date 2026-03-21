import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../ble/ble_controller.dart' show BleController, syncScript;

class MusicController extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription? _positionSub;
  final Set<int> _triggeredSeconds = {};

  bool _isPlaying = false;
  double _progress = 0.0;
  Duration _position = Duration.zero;
  Duration _duration = const Duration(seconds: 60);

  String get trackTitle => 'Stitch Colors';
  String get artist => 'Chen Li';

  bool get isPlaying => _isPlaying;
  bool get syncEnabled => BleController.instance.autoSyncEnabled;
  double get progress => _progress;
  Duration get position => _position;
  Duration get duration => _duration;

  MusicController() {
    _player.onDurationChanged.listen((d) {
      _duration = d;
      notifyListeners();
    });
    _player.onPositionChanged.listen(_onPositionChanged);
  }

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

  Future<void> init() async {
    try {
      await _player.setSource(AssetSource('assets/audio/mock_music.mp3'));
    } catch (e) {
      debugPrint('[MusicController] Asset load failed, using UrlSource: $e');
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
