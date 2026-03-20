import 'package:flutter/material.dart';

class MusicController extends ChangeNotifier {
  bool _isPlaying = false;
  bool _syncEnabled = true;
  double _progress = 0.45;
  String _trackTitle = 'Cyber Symphony';
  String _artist = 'ASTRO-V · Neon Dreams';

  bool get isPlaying => _isPlaying;
  bool get syncEnabled => _syncEnabled;
  double get progress => _progress;
  String get trackTitle => _trackTitle;
  String get artist => _artist;

  void togglePlay() {
    _isPlaying = !_isPlaying;
    notifyListeners();
  }

  void toggleSync() {
    _syncEnabled = !_syncEnabled;
    notifyListeners();
  }

  void setProgress(double value) {
    _progress = value.clamp(0.0, 1.0);
    notifyListeners();
  }

  void skipPrevious() => notifyListeners();
  void skipNext() => notifyListeners();
  void shuffle() => notifyListeners();
  void repeat() => notifyListeners();
}
