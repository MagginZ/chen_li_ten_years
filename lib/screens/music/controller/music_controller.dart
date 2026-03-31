import 'dart:async';
import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../../ble/ble_controller.dart' show BleController, syncScript;
import '../beat_analysis.dart';
import '../beat_audio_source.dart';
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

  /// 波形分析得到的节拍时刻（毫秒）。为空则退回 [bpm] 相位同步。
  List<int> _beatTimesMs = [];
  bool _beatAnalyzing = false;
  int _beatHueSeed = 0;

  /// 未检测到波形或分析失败时，按 BPM 做等间隔「虚拟节拍」。
  double _bpm = 120;

  /// `false`：沿用 [syncScript] 固定秒数变色；`true`：波形/节拍器 + BPM。
  bool _useMetronomeBeatSync = false;

  /// 供开启节拍器后补做波形分析（与当前曲目来源一致）。
  String? _lastHttpSource;
  bool _lastUseAsset = false;
  String? _lastFallbackHttp;

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
  bool get beatAnalyzing => _beatAnalyzing;
  bool get hasWaveformBeats => _beatTimesMs.isNotEmpty;
  bool get useMetronomeBeatSync => _useMetronomeBeatSync;

  /// 灯光同步区域副文案。
  String get beatSyncHint {
    if (!_useMetronomeBeatSync) {
      final keys = syncScript.keys.toList()..sort();
      return '按时间进度：${keys.join('、')}s 触发预设色';
    }
    if (_beatAnalyzing) return '正在分析节拍（波形）…';
    if (_beatTimesMs.isNotEmpty) {
      return '波形能量≈${_beatTimesMs.length} 个拍点';
    }
    return '按 BPM ${_bpm.round()} 同步（可调）';
  }

  void setBpm(double value) {
    _bpm = value.clamp(60.0, 200.0);
    notifyListeners();
  }

  void setUseMetronomeBeatSync(bool value) {
    _useMetronomeBeatSync = value;
    if (value) {
      unawaited(_maybeScheduleBeatAnalysis(gen: _loadGeneration));
    }
    notifyListeners();
  }

  void _rememberAnalysisSources({
    String? httpSource,
    bool useAsset = false,
    String? fallbackHttpUrl,
  }) {
    _lastHttpSource = httpSource;
    _lastUseAsset = useAsset;
    _lastFallbackHttp = fallbackHttpUrl;
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
      } else if (_beatTimesMs.isNotEmpty) {
        for (final t in _beatTimesMs) {
          if (prev < t && cur >= t) {
            _fireBeatHue();
          }
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

  Future<void> _maybeScheduleBeatAnalysis({required int gen}) async {
    if (!_useMetronomeBeatSync) return;
    await _scheduleBeatAnalysis(
      gen: gen,
      httpSource: _lastHttpSource,
      useAsset: _lastUseAsset,
      fallbackHttpUrl: _lastFallbackHttp,
    );
  }

  /// [httpSource] 优先：网络音频 URL；否则 [useAsset] 用内置 mock；再否则分析 [fallbackHttpUrl]（如 SoundHelix）。
  Future<void> _scheduleBeatAnalysis({
    required int gen,
    String? httpSource,
    bool useAsset = false,
    String? fallbackHttpUrl,
  }) async {
    _beatAnalyzing = true;
    _beatTimesMs = [];
    _beatHueSeed = 0;
    notifyListeners();

    try {
      var dm = _duration.inMilliseconds;
      if (dm <= 0) {
        await Future<void>.delayed(const Duration(milliseconds: 400));
        if (_isStaleLoad(gen)) return;
        dm = _player.duration?.inMilliseconds ?? 0;
      }
      if (dm <= 0) return;

      File? temp;
      if (httpSource != null && _isPlayableUrl(httpSource)) {
        temp = await cacheHttpAudioToTemp(httpSource);
      } else if (useAsset) {
        temp = await copyAssetToTemp('assets/audio/mock_music.mp3', '.mp3');
      } else if (fallbackHttpUrl != null && _isPlayableUrl(fallbackHttpUrl)) {
        temp = await cacheHttpAudioToTemp(fallbackHttpUrl);
      }
      if (temp == null || !await temp.exists()) return;
      if (_isStaleLoad(gen)) return;

      final beats = await extractBeatTimesMsFromFile(temp.path, dm);
      if (_isStaleLoad(gen)) return;
      if (beats.isNotEmpty) {
        _beatTimesMs = beats;
      }
    } catch (e) {
      debugPrint('[MusicController] beat analysis failed: $e');
    } finally {
      if (!_isStaleLoad(gen)) {
        _beatAnalyzing = false;
        notifyListeners();
      }
    }
  }

  Future<void> _loadTrack(MusicTrack? track) async {
    final gen = ++_loadGeneration;
    _beatTimesMs = [];
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
        _rememberAnalysisSources(httpSource: streamUrl);
        unawaited(_maybeScheduleBeatAnalysis(gen: gen));
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
      _rememberAnalysisSources(useAsset: true);
      unawaited(_maybeScheduleBeatAnalysis(gen: gen));
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
        _rememberAnalysisSources(fallbackHttpUrl: _kSoundHelixUrl);
        unawaited(_maybeScheduleBeatAnalysis(gen: gen));
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
