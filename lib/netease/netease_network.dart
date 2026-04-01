/// 网易云 CDN / 图片防盗链：需浏览器式 User-Agent + Referer。
/// 音频流（just_audio）与 [Image.network] 共用同一套头。
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
