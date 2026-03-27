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
  static const int pageSize = 20;

  MusicListController() {
    BleController.instance.addListener(_onBleChanged);
  }

  void _onBleChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    BleController.instance.removeListener(_onBleChanged);
    super.dispose();
  }

  List<MusicTrack> _tracks = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  String _searchKeyword = '陈粒';
  int _currentOffset = 0;
  bool _hasMore = true;

  List<MusicTrack> get displayTracks => _tracks;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  String get searchKeyword => _searchKeyword;
  bool get hasMore => _hasMore;
  int _nowPlayingIndex = 0;
  int get nowPlayingIndex => _nowPlayingIndex;
  bool get syncEnabled => BleController.instance.autoSyncEnabled;

  /// 搜索并加载第一页
  Future<void> search(String keyword) async {
    if (keyword.trim().isEmpty) return;
    _searchKeyword = keyword.trim();
    _currentOffset = 0;
    _hasMore = true;
    await _loadPage(append: false);
  }

  /// 加载第一页（默认关键词 陈粒）
  Future<void> loadPlaylist() async {
    _searchKeyword = '陈粒';
    _currentOffset = 0;
    _hasMore = true;
    await _loadPage(append: false);
  }

  /// 加载更多（分页）
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    await _loadPage(append: true);
  }

  Future<void> _loadPage({required bool append}) async {
    if (append) {
      _isLoadingMore = true;
    } else {
      _isLoading = true;
      _error = null;
    }
    notifyListeners();

    try {
      final dtos = await fetchPlaylist(
        keyword: _searchKeyword,
        limit: pageSize,
        offset: append ? _currentOffset : 0,
      );
      final newTracks = dtos.map((d) => MusicTrack.fromDto(d)).toList();
      _hasMore = newTracks.length >= pageSize;

      if (append) {
        _tracks = [..._tracks, ...newTracks];
        _currentOffset = _tracks.length;
      } else {
        _tracks = newTracks;
        _currentOffset = newTracks.length;
        _nowPlayingIndex = _tracks.isNotEmpty ? 0 : 0;
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
      if (!append) {
        _tracks = [];
      }
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
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

  void retry() {
    _currentOffset = 0;
    _hasMore = true;
    _loadPage(append: false);
  }
}
