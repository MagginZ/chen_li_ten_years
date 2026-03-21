import 'package:flutter/material.dart';
import '../../../api/playlist_api.dart';
import '../../../ble/ble_controller.dart';

/// 歌单中的单曲
class MusicTrack {
  final String id;
  final String title;
  final String artist;
  final String? coverUrl;
  final String? streamUrl;
  final int durationMs;
  final bool isNowPlaying;

  const MusicTrack({
    required this.id,
    required this.title,
    required this.artist,
    this.coverUrl,
    this.streamUrl,
    this.durationMs = 0,
    this.isNowPlaying = false,
  });

  factory MusicTrack.fromDto(PlaylistItemDto dto) {
    return MusicTrack(
      id: dto.id,
      title: dto.title,
      artist: dto.artist,
      coverUrl: dto.coverUrl.isNotEmpty ? dto.coverUrl : null,
      streamUrl: dto.streamUrl.isNotEmpty ? dto.streamUrl : null,
      durationMs: dto.durationMs,
    );
  }
}

class MusicListController extends ChangeNotifier {
  static const String playlistName = '陈粒 · Starlight World Tour';

  List<MusicTrack> _tracks = [];
  bool _isLoading = false;
  String? _error;

  /// API 失败时的兜底歌单（不再使用 mock）
  static List<MusicTrack> get _fallbackTracks => const [
    MusicTrack(id: '1', title: 'Stitch Colors', artist: 'Chen Li'),
    MusicTrack(id: '2', title: '小半', artist: '陈粒'),
    MusicTrack(id: '3', title: '奇妙能力歌', artist: '陈粒'),
    MusicTrack(id: '4', title: '易燃易爆炸', artist: '陈粒'),
    MusicTrack(id: '5', title: '走马', artist: '陈粒'),
  ];

  List<MusicTrack> get displayTracks => _tracks;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int _nowPlayingIndex = 0;
  int get nowPlayingIndex => _nowPlayingIndex;
  bool get syncEnabled => BleController.instance.autoSyncEnabled;

  /// 从 API 拉取歌单
  Future<void> loadPlaylist() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final dtos = await fetchPlaylist();
      _tracks = dtos.map((d) => MusicTrack.fromDto(d)).toList();
      _nowPlayingIndex = _tracks.isNotEmpty ? 0 : 0;
    } catch (e) {
      _error = e.toString();
      _tracks = List<MusicTrack>.from(_fallbackTracks);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setNowPlayingIndex(int index) {
    _nowPlayingIndex = index;
    notifyListeners();
  }

  void toggleSync() {
    BleController.instance.setAutoSync(!BleController.instance.autoSyncEnabled);
    notifyListeners();
  }

  void selectTrack(int index) {
    _nowPlayingIndex = index;
    notifyListeners();
  }

  void retry() => loadPlaylist();
}
