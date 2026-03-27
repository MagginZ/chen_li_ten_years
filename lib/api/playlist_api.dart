import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// 后端 Python FastAPI 服务地址
/// - 默认使用当前开发机局域网 IP，便于真机调试
/// - 可通过 --dart-define=API_BASE=http://<电脑IP>:8000 覆盖
const String kPlaylistApiBase = String.fromEnvironment(
  'API_BASE',
  defaultValue: 'http://172.20.0.240:8000',
);

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

/// 调用后端 GET /api/playlist，支持搜索与分页
Future<List<PlaylistItemDto>> fetchPlaylist({
  String keyword = '陈粒',
  int limit = 20,
  int offset = 0,
}) async {
  try {
    final uri = Uri.parse('$kPlaylistApiBase/api/playlist').replace(
      queryParameters: {
        'keyword': keyword,
        'limit': limit.toString(),
        'offset': offset.toString(),
      },
    );
    final resp = await http.get(uri).timeout(
      const Duration(seconds: 25),
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
