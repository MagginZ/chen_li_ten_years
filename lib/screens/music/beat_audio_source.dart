import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const int _kMaxDownloadBytes = 35 * 1024 * 1024;

/// 将网络音频拉到临时文件，供波形解码（过大则放弃）。
Future<File?> cacheHttpAudioToTemp(String url) async {
  if (url.isEmpty) return null;
  try {
    final req = http.Request('GET', Uri.parse(url));
    final streamed = await http.Client().send(req).timeout(const Duration(seconds: 45));
    final len = streamed.contentLength;
    if (len != null && len > _kMaxDownloadBytes) {
      debugPrint('[BeatAudio] skip download: too large ($len)');
      return null;
    }
    final bytes = await streamed.stream.toBytes();
    if (bytes.length > _kMaxDownloadBytes) {
      debugPrint('[BeatAudio] skip: body too large');
      return null;
    }
    final dir = await getTemporaryDirectory();
    final ext = p.extension(Uri.parse(url).path);
    final name =
        'beat_${DateTime.now().millisecondsSinceEpoch}${ext.isEmpty ? '.mp3' : ext}';
    final f = File(p.join(dir.path, name));
    await f.writeAsBytes(bytes, flush: true);
    return f;
  } catch (e) {
    debugPrint('[BeatAudio] cacheHttp failed: $e');
    return null;
  }
}

/// 将 asset 写入临时文件。
Future<File?> copyAssetToTemp(String assetPath, String suffix) async {
  try {
    final bd = await rootBundle.load(assetPath);
    final dir = await getTemporaryDirectory();
    final f = File(p.join(dir.path, 'beat_asset_${DateTime.now().millisecondsSinceEpoch}$suffix'));
    await f.writeAsBytes(bd.buffer.asUint8List(), flush: true);
    return f;
  } catch (e) {
    debugPrint('[BeatAudio] copyAsset failed: $e');
    return null;
  }
}
