import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_container.dart';
import '../../ble/ble_controller.dart';
import 'controller/music_controller.dart';
import 'controller/music_list_controller.dart';
import 'event/music_event.dart';

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

    final glowPaint = Paint()
      ..color = AppColors.musicPrimary.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(center, 16, glowPaint);

    final fillPaint = Paint()..color = AppColors.musicPrimary;
    canvas.drawCircle(center, enabledThumbRadius, fillPaint);

    final outlinePaint = Paint()
      ..color = AppColors.musicPrimary.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, enabledThumbRadius, outlinePaint);
  }
}

class _CoverImage extends StatelessWidget {
  const _CoverImage({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return Container(
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
      );
    }
    return Image.network(
      url!,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.low,
      errorBuilder: (_, __, ___) => Container(
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
          child: Icon(Icons.album, size: 120, color: AppColors.white.withValues(alpha: 0.3)),
        ),
      ),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: AppColors.surfaceContainerHigh,
          child: Center(
            child: CircularProgressIndicator(
              color: AppColors.musicPrimary,
              value: progress.expectedTotalBytes != null
                  ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
    );
  }
}

class MusicScreen extends StatefulWidget {
  const MusicScreen({
    super.key,
    this.track,
    this.allTracks = const [],
    this.initialIndex = 0,
    this.onBack,
  });

  final MusicTrack? track;
  final List<MusicTrack> allTracks;
  final int initialIndex;
  final VoidCallback? onBack;

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen>
    with SingleTickerProviderStateMixin {
  late final MusicController _controller;
  late final MusicEvent _event;
  late final AnimationController _coverAnimController;
  late final Animation<double> _coverScale;
  late int _currentIndex;
  bool _coverAnimPlaying = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = MusicController(initialTrack: widget.track);
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
    if (_coverAnimPlaying == _controller.isPlaying) return;
    _coverAnimPlaying = _controller.isPlaying;

    if (_controller.isPlaying) {
      _coverAnimController.repeat(reverse: true);
    } else {
      _coverAnimController.stop();
      _coverAnimController.reset();
    }
  }

  void _onPrev() {
    final tracks = widget.allTracks;
    if (tracks.isNotEmpty && _currentIndex > 0) {
      setState(() => _currentIndex--);
      _controller.switchTrack(tracks[_currentIndex]);
    } else {
      _event.seekToStart();
    }
  }

  void _onNext() {
    final tracks = widget.allTracks;
    if (tracks.isNotEmpty && _currentIndex < tracks.length - 1) {
      setState(() => _currentIndex++);
      _controller.switchTrack(tracks[_currentIndex]);
    } else {
      _event.seekToEnd();
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
              Positioned(
                top: -60,
                left: -60,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.musicPrimary.withValues(alpha: 0.08),
                        blurRadius: 48,
                        spreadRadius: 12,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: -60,
                right: -60,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.tertiary.withValues(alpha: 0.05),
                        blurRadius: 44,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                ),
              ),
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.onBack != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: IconButton(
                            onPressed: widget.onBack,
                            icon: const Icon(Icons.arrow_back_ios),
                            color: AppColors.onSurface,
                            iconSize: 24,
                          ),
                        ),
                      const SizedBox(height: 16),
                      RepaintBoundary(
                        child: AnimatedBuilder(
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
                                    color: AppColors.black.withValues(alpha: 0.28),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: _CoverImage(url: _controller.currentTrack?.coverUrl),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        _controller.trackTitle,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.01,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _controller.artist,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: AppColors.secondaryFixed,
                        ),
                      ),
                      const SizedBox(height: 24),
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
                                    '灯光同步',
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: AppColors.onSurface,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _controller.syncEnabled
                                        ? '随节拍同步中…'
                                        : '已关闭同步',
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
                                            color: AppColors.black.withValues(alpha: 0.14),
                                            blurRadius: 3,
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
                      const SizedBox(height: 24),
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
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.black.withValues(alpha: 0.12),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: _onPrev,
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
                                    AppColors.musicPrimary.withValues(alpha: 0.8),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.musicPrimary.withValues(alpha: 0.24),
                                    blurRadius: 12,
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
                              onPressed: _onNext,
                              icon: const Icon(Icons.skip_next),
                              iconSize: 40,
                              color: AppColors.onSurface,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
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
                                    '设备已连接',
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
                                    '氛围模式',
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
