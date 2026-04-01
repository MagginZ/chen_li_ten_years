import '../api/playlist_api.dart' show kPlaylistApiBase;

/// 网易云 CDN / 图片防盗链：需浏览器式 User-Agent + Referer。
/// 音频流（just_audio）与 [Image.network] 共用同一套头。
/// 若走后端 [代理](/api/proxy/*)，则由 Python 带头发起请求，App 直连局域网 API，无需再带头。
const Map<String, String> kNeteaseBrowserHeaders = {
  'User-Agent':
      'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
  'Referer': 'https://music.163.com/',
};

bool _looksLikeNeteaseUrl(String url) {
  final u = url.toLowerCase();
  return u.contains('126.net') ||
      u.contains('163.com') ||
      u.contains('music.163') ||
      u.contains('music.126');
}

/// 非网易云 URL 返回 null，[Image.network] / 播放器可不带头。
Map<String, String>? neteaseHeadersForUrl(String? url) {
  if (url == null || url.isEmpty) return null;
  return _looksLikeNeteaseUrl(url) ? kNeteaseBrowserHeaders : null;
}

/// 网易云媒体直链常为 http，Android 9+ 默认禁明文；CDN 一般支持 https，优先升级以免依赖 cleartext。
String preferHttpsForNeteaseHttpUrl(String url) {
  final t = url.trim();
  if (t.length < 8) return url;
  if (!t.toLowerCase().startsWith('http://')) return url;
  if (!_looksLikeNeteaseUrl(t)) return url;
  return 'https://${t.substring(7)}';
}

String _apiBaseNoTrailingSlash() {
  var b = kPlaylistApiBase.trim();
  if (b.endsWith('/')) {
    b = b.substring(0, b.length - 1);
  }
  return b;
}

/// 音频：网易 CDN 改为请求本机 FastAPI 代理（由后端带 UA/Referer 拉流再转给手机）。
String urlForPlaybackThroughProxy(String originalUrl) {
  final u = preferHttpsForNeteaseHttpUrl(originalUrl.trim());
  if (!_looksLikeNeteaseUrl(u)) return u;
  final base = _apiBaseNoTrailingSlash();
  return '$base/api/proxy/audio?url=${Uri.encodeQueryComponent(u)}';
}

/// 封面：同上，破解防盗链；非网易 URL 原样返回。
String urlForCoverThroughProxy(String originalUrl) {
  final u = preferHttpsForNeteaseHttpUrl(originalUrl.trim());
  if (!_looksLikeNeteaseUrl(u)) return u;
  final base = _apiBaseNoTrailingSlash();
  return '$base/api/proxy/image?url=${Uri.encodeQueryComponent(u)}';
}

