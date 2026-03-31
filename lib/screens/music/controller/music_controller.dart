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

  /// 防止连续切歌时，先发出的 `setUrl` 后完成、覆盖后选曲目。
  int _loadGeneration = 0;

  bool _isPlaying = false;
  double _progress = 0.0;
  Duration _position = Duration.zero;
  Duration _duration = const Duration(seconds: 60);

  /// 上一帧播放位置（毫秒），用于判断「跨过」某一节拍时刻。
  int _prevPosMs = -1;

  int _beatHueSeed = 0;

  /// 节拍器模式：按 BPM 做等间隔「虚拟节拍」。
  double _bpm = 120;

  /// `false`：沿用 [syncScript] 固定秒数变色；`true`：按 BPM 相位变色。
  bool _useMetronomeBeatSync = false;

  /// 时间轴模式：同一秒内只触发一次 [BleController.triggerSyncAt]。
  final Set<int> _triggeredScriptSeconds = {};

  MusicTrack? get currentTrack => _currentTrack ?? initialTrack;
  String get trackTitle => currentTrack?.title ?? '果实音乐';
  String get artist => currentTrack?.artist ?? '陈粒';

  bool get isPlaying => _isPlaying;
  bool get syncEnabled => BleController.instance.autoSyncEnabled;
  double get progress => _progress;
  Duration get position => _position;
  Duration get duration => _duration;

  double get bpm => _bpm;
  bool get useMetronomeBeatSync => _useMetronomeBeatSync;

  /// 灯光同步区域副文案。
  String get beatSyncHint {
    if (!_useMetronomeBeatSync) {
      final keys = syncScript.keys.toList()..sort();
      return '按时间进度：${keys.join('、')}s 触发预设色';
    }
    return '按 BPM ${_bpm.round()} 节拍驱动变色（可调）';
  }

  void setBpm(double value) {
    _bpm = value.clamp(60.0, 200.0);
    notifyListeners();
  }

  void setUseMetronomeBeatSync(bool value) {
    _useMetronomeBeatSync = value;
    notifyListeners();
  }

  bool _isPlayableUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    final lower = url.toLowerCase();
    if (lower.contains('youtube') || lower.contains('youtu.be')) return false;
    return lower.startsWith('http://') || lower.startsWith('https://');
  }

  void _fireBeatHue() {
    _beatHueSeed++;
    final hue = (_beatHueSeed * 43) % 360;
    final c = HSVColor.fromAHSV(1, hue.toDouble(), 1, 1).toColor();
    BleController.instance.updateLightColor(
      (c.r * 255.0).round().clamp(0, 255),
      (c.g * 255.0).round().clamp(0, 255),
      (c.b * 255.0).round().clamp(0, 255),
    );
  }

  void _onPositionChanged(Duration pos) {
    final cur = pos.inMilliseconds;
    final prev = _prevPosMs;

    if (cur + 800 < prev) {
      _prevPosMs = cur;
    }

    _position = pos;
    _progress = _duration.inMilliseconds > 0
        ? pos.inMilliseconds / _duration.inMilliseconds
        : 0.0;

    if (BleController.instance.autoSyncEnabled) {
      if (!_useMetronomeBeatSync) {
        if (pos.inSeconds < 2) {
          _triggeredScriptSeconds.clear();
        }
        final sec = pos.inSeconds;
        if (syncScript.containsKey(sec) && !_triggeredScriptSeconds.contains(sec)) {
          _triggeredScriptSeconds.add(sec);
          BleController.instance.triggerSyncAt(sec);
        }
      } else {
        final period = (60000 / _bpm).round();
        if (period > 0) {
          final prevBeat = prev >= 0 ? prev ~/ period : -1;
          final curBeat = cur ~/ period;
          if (curBeat > prevBeat) {
            _fireBeatHue();
          }
        }
      }
    }

    _prevPosMs = cur;
    notifyListeners();
  }

  Future<void> init() async {
    _currentTrack = initialTrack;
    await _loadTrack(_currentTrack);
  }

  Future<void> switchTrack(MusicTrack track) async {
    if (_currentTrack?.id == track.id) {
      _currentTrack = track;
      notifyListeners();
      return;
    }
    _currentTrack = track;
    await _loadTrack(track);
  }

  bool _isStaleLoad(int gen) => gen != _loadGeneration;

  static const String _kSoundHelixUrl =
      'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';

  Future<void> _loadTrack(MusicTrack? track) async {
    final gen = ++_loadGeneration;
    _beatHueSeed = 0;
    _prevPosMs = -1;
    _triggeredScriptSeconds.clear();

    try {
      await _player.stop();
    } catch (_) {}

    if (_isStaleLoad(gen)) return;

    final streamUrl = track?.streamUrl;
    if (_isPlayableUrl(streamUrl)) {
      try {
        await _player.setUrl(streamUrl!);
        if (_isStaleLoad(gen)) return;
        debugPrint('[MusicController] Playing from URL: $streamUrl');
        await _player.play();
        if (_isStaleLoad(gen)) return;
        _isPlaying = true;
        _duration = _player.duration ?? _duration;
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
      _duration = _player.duration ?? _duration;
      notifyListeners();
    } catch (e) {
      debugPrint('[MusicController] Asset failed, using SoundHelix: $e');
      if (_isStaleLoad(gen)) return;
      try {
        await _player.setUrl(_kSoundHelixUrl);
        if (_isStaleLoad(gen)) return;
        await _player.play();
        if (_isStaleLoad(gen)) return;
        _isPlaying = true;
        _duration = _player.duration ?? _duration;
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
    _prevPosMs = ms > 0 ? ms - 1 : -1;
    notifyListeners();
  }

  void seekToStart() {
    _player.seek(Duration.zero);
    _prevPosMs = -1;
  }

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
