import 'package:flutter/material.dart';

/// 供无 USB 时在界面用 SnackBar 提示（悬浮，不打断操作）。
/// 需与 [MaterialApp.navigatorKey] 一致。
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// 控制台 + 可选底部 SnackBar（重要信息才 [toast]）。
void bleScanLog(String message, {bool toast = false}) {
  debugPrint(message);
  if (!toast) return;
  final ctx = rootNavigatorKey.currentContext;
  if (ctx == null) {
    // 首帧前 navigator 未就绪：下一帧再试，避免静默丢提示
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showBleSnackBar(message);
    });
    return;
  }
  _showBleSnackBar(message);
}

void _showBleSnackBar(String message) {
  final ctx = rootNavigatorKey.currentContext;
  if (ctx == null) return;
  final messenger = ScaffoldMessenger.maybeOf(ctx);
  if (messenger == null) return;

  final text = message.length > 200 ? '${message.substring(0, 200)}…' : message;
  // 勿 clearSnackBars：否则连续 bleScanLog(toast:true) 只剩最后一条，易误判「只有写入结束」
  messenger.showSnackBar(
    SnackBar(
      content: Text(text, style: const TextStyle(fontSize: 13)),
      duration: const Duration(seconds: 4),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 96),
    ),
  );
}
