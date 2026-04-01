import 'package:flutter/material.dart';

/// 供无 USB 时在界面用 SnackBar 提示（悬浮，不打断操作）。
/// 需与 [MaterialApp.navigatorKey] 一致。
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// 控制台 + 可选底部 SnackBar（重要信息才 [toast]）。
///
/// [replaceToast] 为 true（默认）时，先移除当前 SnackBar 再显示新的，避免连续写入时
/// 多条 SnackBar 排队 4s×N，造成界面堆积与「操作滞后」观感（BLE 本身仍异步，不阻塞 GATT）。
/// 完整日志仍以 [debugPrint] 为准。
///
/// SnackBar 必须在本帧 build 结束后再显示；若在 initState / ListenableBuilder 重建链路里
/// 同步调用 [showSnackBar] 会触发 “called during build”（Web 预览尤易复现）。
void bleScanLog(
  String message, {
  bool toast = false,
  bool replaceToast = true,
}) {
  debugPrint(message);
  if (!toast) return;
  // 始终延后到帧末，避免与 build / layout 重叠（与 context 是否为空无关）
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _showBleSnackBar(message, replace: replaceToast);
  });
}

void _showBleSnackBar(String message, {required bool replace}) {
  final ctx = rootNavigatorKey.currentContext;
  if (ctx == null) return;
  final messenger = ScaffoldMessenger.maybeOf(ctx);
  if (messenger == null) return;

  final text = message.length > 200 ? '${message.substring(0, 200)}…' : message;
  if (replace) {
    messenger.removeCurrentSnackBar();
  }
  messenger.showSnackBar(
    SnackBar(
      content: Text(text, style: const TextStyle(fontSize: 13)),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 96),
    ),
  );
}
