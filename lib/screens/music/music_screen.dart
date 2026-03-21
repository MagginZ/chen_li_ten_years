import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_container.dart';
import '../../ble/ble_controller.dart';
import 'controller/music_controller.dart';
import 'event/music_event.dart';

/// 发光滑块形状：primary 色 20px 外发光
class _GlowThumbShape extends RoundSliderThumbShape {
  const _GlowThumbShape();

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    bool isDiscrete = false,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;

    // 20px 外发光 (Ambient Shadow)
    final glowPaint = Paint()
      ..color = AppColors.musicPrimary.withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(center, 20, glowPaint);

    // 滑块本体
    final fillPaint = Paint()..color = AppColors.musicPrimary;
    canvas.drawCircle(center, enabledThumbRadius, fillPaint);

    // 高光边缘
    final outlinePaint = Paint()
      ..color = AppColors.musicPrimary.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, enabledThumbRadius, outlinePaint);
  }
}

class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen>
    with SingleTickerProviderStateMixin {
  late final MusicController _controller;
  late final MusicEvent _event;
  late final AnimationController _coverAnimController;
  late final Animation<double> _coverScale;

  @override
  void initState() {
    super.initState();
    _controller = MusicController();
    _event = MusicEvent(_controller);
    _controller.init();

    _coverAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _coverScale = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _coverAnimController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _coverAnimController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _updateCoverAnimation() {
    if (_controller.isPlaying) {
      _coverAnimController.repeat(reverse: true);
    } else {
      _coverAnimController.stop();
      _coverAnimController.reset();
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_controller, BleController.instance]),
      builder: (context, _) {
        _updateCoverAnimation();
        return Scaffold(
          backgroundColor: AppColors.musicBackground,
          body: Stack(
            children: [
              // 装饰光晕
              Positioned(
                top: -100,
                left: -100,
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.musicPrimary.withValues(alpha: 0.15),
                        blurRadius: 120,
                        spreadRadius: 50,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: -100,
                right: -100,
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.tertiary.withValues(alpha: 0.08),
                        blurRadius: 120,
                        spreadRadius: 50,
                      ),
                    ],
                  ),
                ),
              ),
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      // 动态封面：播放时缓慢缩放，暂停时停止
                      AnimatedBuilder(
                        animation: _coverScale,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _coverScale.value,
                            child: child,
                          );
                        },
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.black.withValues(alpha: 0.5),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.musicPrimary.withValues(alpha: 0.8),
                                      AppColors.tertiary.withValues(alpha: 0.8),
                                    ],
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.album,
                                    size: 120,
                                    color: AppColors.white.withValues(alpha: 0.3),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      // 歌曲名 (Space Grotesk 风格，无 google_fonts 时用主题字体)
                      Text(
                        _controller.trackTitle,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.01,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // 歌手名 (Manrope 风格)
                      Text(
                        _controller.artist,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: AppColors.secondaryFixed,
                        ),
                      ),
                      const SizedBox(height: 32),
                      // SYNC LIGHT 开关区域
                      GlassContainer(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.musicPrimary.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.fluorescent, color: AppColors.musicPrimary),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'SYNC LIGHT',
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: AppColors.onSurface,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _controller.syncEnabled
                                        ? 'Synchronizing with beat...'
                                        : 'Sync disabled',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _event.toggleSync(),
                              child: Container(
                                width: 56,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: _controller.syncEnabled
                                      ? AppColors.musicPrimary
                                      : AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Align(
                                    alignment: _controller.syncEnabled
                                        ? Alignment.centerRight
                                        : Alignment.centerLeft,
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: AppColors.onPrimary,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.black.withValues(alpha: 0.2),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      // 进度条区域：surface-container-low，禁止边框
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            SliderTheme(
                              data: SliderThemeData(
                                trackHeight: 6,
                                activeTrackColor: AppColors.musicPrimary,
                                inactiveTrackColor: AppColors.surfaceContainerHighest,
                                thumbShape: const _GlowThumbShape(),
                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 0),
                                trackShape: const RoundedRectSliderTrackShape(),
                              ),
                              child: Slider(
                                value: _controller.progress.clamp(0.0, 1.0),
                                onChanged: (v) => _event.setProgress(v),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(_controller.position),
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    fontFamily: 'monospace',
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  _formatDuration(_controller.duration),
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    fontFamily: 'monospace',
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // 玻璃拟态控制栏：surface-variant 60% + BackdropFilter 20px
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  onPressed: () => _event.shuffle(),
                                  icon: Icon(
                                    Icons.shuffle,
                                    color: AppColors.onSurface.withValues(alpha: 0.6),
                                  ),
                                  iconSize: 32,
                                ),
                                const SizedBox(width: 24),
                                IconButton(
                                  onPressed: () => _event.skipPrevious(),
                                  icon: const Icon(Icons.skip_previous),
                                  iconSize: 40,
                                  color: AppColors.onSurface,
                                ),
                                const SizedBox(width: 16),
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.musicPrimary,
                                        AppColors.musicPrimary.withValues(alpha: 0.7),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.musicPrimary.withValues(alpha: 0.5),
                                        blurRadius: 24,
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    onPressed: () => _event.togglePlay(),
                                    icon: Icon(
                                      _controller.isPlaying ? Icons.pause : Icons.play_arrow,
                                      size: 40,
                                      color: AppColors.onPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                IconButton(
                                  onPressed: () => _event.skipNext(),
                                  icon: const Icon(Icons.skip_next),
                                  iconSize: 40,
                                  color: AppColors.onSurface,
                                ),
                                const SizedBox(width: 24),
                                IconButton(
                                  onPressed: () => _event.repeat(),
                                  icon: Icon(
                                    Icons.repeat,
                                    color: AppColors.onSurface.withValues(alpha: 0.6),
                                  ),
                                  iconSize: 32,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      Row(
                        children: [
                          Expanded(
                            child: GlassContainer(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.bluetooth_searching,
                                    color: AppColors.secondaryFixed,
                                    size: 28,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'LS-409 Connected',
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: GlassContainer(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.palette,
                                    color: AppColors.tertiaryFixed,
                                    size: 28,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Aura Mode',
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
