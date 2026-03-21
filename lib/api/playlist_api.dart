import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// 后端 Python FastAPI 服务地址
/// GET $base/api/playlist 拉取陈粒歌单
/// - Web/模拟器: localhost
/// - 真机同网: 替换为电脑 IP，如 http://192.168.1.100:8000
const String kPlaylistApiBase = 'http://localhost:8000';

/// 歌单项（API 响应格式）
class PlaylistItemDto {
  final String id;
  final String title;
  final String artist;
  final String coverUrl;
  final String streamUrl;
  final int durationMs;

  PlaylistItemDto({
    required this.id,
    required this.title,
    required this.artist,
    required this.coverUrl,
    required this.streamUrl,
    required this.durationMs,
  });

  factory PlaylistItemDto.fromJson(Map<String, dynamic> json) {
    return PlaylistItemDto(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      artist: json['artist'] as String? ?? '',
      coverUrl: json['coverUrl'] as String? ?? '',
      streamUrl: json['streamUrl'] as String? ?? '',
      durationMs: json['duration_ms'] as int? ?? 0,
    );
  }
}

/// 调用后端 Python FastAPI GET /api/playlist，拉取陈粒歌单
Future<List<PlaylistItemDto>> fetchPlaylist() async {
  try {
    final uri = Uri.parse('$kPlaylistApiBase/api/playlist');
    final resp = await http.get(uri).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception('请求超时'),
    );
    if (resp.statusCode != 200) {
      throw Exception('API 返回 ${resp.statusCode}');
    }
    final list = json.decode(resp.body) as List<dynamic>;
    return list
        .map((e) => PlaylistItemDto.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (e) {
    debugPrint('[PlaylistAPI] fetchPlaylist failed: $e');
    rethrow;
  }
}
