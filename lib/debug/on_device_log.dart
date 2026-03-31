import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 是否在界面显示日志按钮与面板。
/// - Debug/Profile：默认开启
/// - Release：默认关闭；打包时加 `--dart-define=SHOW_DEVICE_LOG=true` 可开启
bool get kAppLogOverlayEnabled {
  if (const bool.fromEnvironment('SHOW_DEVICE_LOG', defaultValue: false)) {
    return true;
  }
  return !kReleaseMode;
}

/// 收集 [debugPrint] 输出，供无 USB 时在手机上看日志。
class OnDeviceLog extends ChangeNotifier {
  OnDeviceLog._();
  static final OnDeviceLog instance = OnDeviceLog._();

  static const int maxLines = 400;
  final List<String> _lines = [];

  List<String> get lines => List.unmodifiable(_lines);

  void add(String message) {
    final now = DateTime.now();
    final ts =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    for (final line in message.split('\n')) {
      if (line.isEmpty) continue;
      _lines.add('[$ts] $line');
    }
    while (_lines.length > maxLines) {
      _lines.removeAt(0);
    }
    notifyListeners();
  }

  void clear() {
    _lines.clear();
    notifyListeners();
  }

  /// 链式接管 [debugPrint]，仍保留原有控制台输出。
  static void install() {
    final DebugPrintCallback previous = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      previous(message, wrapWidth: wrapWidth);
      if (message != null && message.isNotEmpty) {
        instance.add(message);
      }
    };
  }
}

/// 悬浮入口 + 底部可拖拽日志面板
class OnDeviceLogOverlay extends StatelessWidget {
  const OnDeviceLogOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!kAppLogOverlayEnabled) return child;

    return Stack(
      alignment: Alignment.center,
      children: [
        child,
        Positioned(
          right: 8,
          bottom: 100,
          child: Material(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: () => _openPanel(context),
              borderRadius: BorderRadius.circular(20),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text(
                  'LOG',
                  style: TextStyle(
                    color: Colors.limeAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _openPanel(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.25,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A1A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                    child: Row(
                      children: [
                        const Text(
                          'Debug 日志 (debugPrint)',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            OnDeviceLog.instance.clear();
                          },
                          child: const Text('清空'),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Colors.white24),
                  Expanded(
                    child: ListenableBuilder(
                      listenable: OnDeviceLog.instance,
                      builder: (context, _) {
                        final lines = OnDeviceLog.instance.lines;
                        if (lines.isEmpty) {
                          return const Center(
                            child: Text(
                              '暂无日志',
                              style: TextStyle(color: Colors.white38),
                            ),
                          );
                        }
                        return ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.all(8),
                          itemCount: lines.length,
                          itemBuilder: (context, i) {
                            return SelectableText(
                              lines[i],
                              style: const TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 11,
                                height: 1.25,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
