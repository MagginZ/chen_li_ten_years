import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../settings/light_rgb_compensation.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_container.dart';
import 'controller/light_controller.dart';
import 'event/light_event.dart';

class LightScreen extends StatefulWidget {
  const LightScreen({super.key});

  @override
  State<LightScreen> createState() => _LightScreenState();
}

class _LightScreenState extends State<LightScreen> {
  static const double _wheelSize = LightController.wheelSize;
  static const double _pickerSize = LightController.pickerSize;
  static double get _pickerTrackRadius => LightController.pickerTrackRadius;

  late final LightController _controller;
  late final LightEvent _event;

  @override
  void initState() {
    super.initState();
    _controller = LightController();
    _event = LightEvent(_controller);
  }

  @override
  void dispose() {
    _event.dispose();
    super.dispose();
  }

  /// 与 Flutter [SweepGradient] 一致：0° 在 3 点钟方向（红），逆时针色相增加。
  double _hueDegreesFromPosition(Offset localPos, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final delta = localPos - center;
    var deg = math.atan2(delta.dy, delta.dx) * 180 / math.pi;
    if (deg < 0) deg += 360;
    return deg;
  }

  Color _colorFromHue(double hueDeg) {
    return HSVColor.fromAHSV(1.0, hueDeg, 1.0, 1.0).toColor();
  }

  Offset _offsetFromHue(double hueDeg, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rad = hueDeg * math.pi / 180;
    return Offset(
      center.dx + math.cos(rad) * _pickerTrackRadius,
      center.dy + math.sin(rad) * _pickerTrackRadius,
    );
  }

  List<Color> get _hueRingColors => List<Color>.generate(
        7,
        (i) => HSVColor.fromAHSV(1.0, (i * 60.0) % 360, 1.0, 1.0).toColor(),
      );

  Widget _trimChannelRow(
    BuildContext context, {
    required String label,
    required Color accent,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 8,
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 12,
                  elevation: 2,
                ),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
              ),
              child: Slider(
                value: value,
                min: LightRgbCompensation.minGain,
                max: LightRgbCompensation.maxGain,
                divisions: 40,
                label: '${(value * 100).round()}%',
                onChanged: onChanged,
                activeColor: accent,
                inactiveColor: AppColors.surfaceContainerLowest,
              ),
            ),
          ),
          SizedBox(
            width: 42,
            child: Text(
              '${(value * 100).round()}%',
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_controller, LightRgbCompensation.instance]),
      builder: (context, _) {
        final trim = LightRgbCompensation.instance;
        final pickerOffset = _controller.pickerOffset;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              Positioned(
                top: -50,
                right: -50,
                child: RepaintBoundary(
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.05),
                          blurRadius: 64,
                          spreadRadius: 28,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -50,
                left: -50,
                child: RepaintBoundary(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.secondary.withOpacity(0.05),
                          blurRadius: 56,
                          spreadRadius: 28,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: CustomScrollView(
                    slivers: [
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    SliverToBoxAdapter(
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '灯光 ',
                              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.02,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '与现场舞台灯效同步',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 40)),
                    SliverToBoxAdapter(
                      child: RepaintBoundary(
                        child: Center(
                          child: SizedBox(
                          width: _wheelSize,
                          height: _wheelSize,
                          child: GestureDetector(
                            onTapDown: (d) {
                              const sz = Size(_wheelSize, _wheelSize);
                              final h = _hueDegreesFromPosition(d.localPosition, sz);
                              _event.commitColor(_colorFromHue(h), _offsetFromHue(h, sz));
                            },
                            onPanStart: (d) {
                              const sz = Size(_wheelSize, _wheelSize);
                              final h = _hueDegreesFromPosition(d.localPosition, sz);
                              _event.previewColor(_colorFromHue(h), _offsetFromHue(h, sz));
                            },
                            onPanUpdate: (d) {
                              const sz = Size(_wheelSize, _wheelSize);
                              final h = _hueDegreesFromPosition(d.localPosition, sz);
                              _event.previewColor(_colorFromHue(h), _offsetFromHue(h, sz));
                            },
                            onPanEnd: (_) {
                              _event.commitColor(_controller.selectedColor, _controller.pickerOffset);
                            },
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: _wheelSize,
                                  height: _wheelSize,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withOpacity(0.1),
                                        blurRadius: 48,
                                        spreadRadius: 24,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: _wheelSize,
                                  height: _wheelSize,
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceContainerHigh,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.black.withOpacity(0.5),
                                        blurRadius: 30,
                                      ),
                                    ],
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: SweepGradient(
                                        colors: _hueRingColors,
                                        stops: const [
                                          0,
                                          1 / 6,
                                          2 / 6,
                                          3 / 6,
                                          4 / 6,
                                          5 / 6,
                                          1,
                                        ],
                                      ),
                                    ),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Positioned(
                                          left: pickerOffset.dx - (_pickerSize / 2),
                                          top: pickerOffset.dy - (_pickerSize / 2),
                                          child: Container(
                                            width: _pickerSize,
                                            height: _pickerSize,
                                            decoration: BoxDecoration(
                                              color: _controller.selectedColor,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: AppColors.surface,
                                                width: 4,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: AppColors.black.withOpacity(0.3),
                                                  blurRadius: 10,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: 120,
                                          height: 120,
                                          decoration: const BoxDecoration(
                                            color: AppColors.surface,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.palette,
                                                color: AppColors.primary,
                                                size: 40,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '色相拾取',
                                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                  color: AppColors.onSurface.withOpacity(0.4),
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 1,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 40)),
                    SliverToBoxAdapter(
                      child: GlassContainer(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '亮度',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                Text(
                                  '${(_controller.brightness * 100).toInt()}%',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Icon(
                                  Icons.light_mode,
                                  color: AppColors.onSurfaceVariant,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      trackHeight: 12,
                                      thumbShape: const RoundSliderThumbShape(
                                        enabledThumbRadius: 16,
                                        elevation: 4,
                                      ),
                                      overlayShape: const RoundSliderOverlayShape(
                                        overlayRadius: 24,
                                      ),
                                    ),
                                    child: Slider(
                                      value: _controller.brightness,
                                      onChanged: (v) => _event.setBrightness(v),
                                      activeColor: _controller.selectedColor,
                                      inactiveColor: AppColors.surfaceContainerLowest,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Icon(
                                  Icons.light_mode,
                                  color: AppColors.secondary,
                                  size: 24,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    SliverToBoxAdapter(
                      child: GlassContainer(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'RGB 补偿',
                                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                              color: AppColors.onSurfaceVariant,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.5,
                                            ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '实际偏红/偏蓝时降低对应通道，与界面选色对齐后固定使用',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: AppColors.onSurfaceVariant.withOpacity(0.85),
                                              height: 1.35,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    await trim.reset();
                                    _event.scheduleTrimRepush();
                                  },
                                  child: const Text('恢复默认'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _trimChannelRow(
                              context,
                              label: 'R',
                              accent: const Color(0xFFFF5252),
                              value: trim.rGain,
                              onChanged: (v) {
                                trim.setRGain(v);
                                _event.scheduleTrimRepush();
                              },
                            ),
                            _trimChannelRow(
                              context,
                              label: 'G',
                              accent: const Color(0xFF69F0AE),
                              value: trim.gGain,
                              onChanged: (v) {
                                trim.setGGain(v);
                                _event.scheduleTrimRepush();
                              },
                            ),
                            _trimChannelRow(
                              context,
                              label: 'B',
                              accent: const Color(0xFF448AFF),
                              value: trim.bGain,
                              onChanged: (v) {
                                trim.setBGain(v);
                                _event.scheduleTrimRepush();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 32)),
                    SliverToBoxAdapter(
                      child: Text(
                        '氛围模式',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),
                    SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 3,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final mode = LightController.modes[index];
                          final isSelected = _controller.selectedMode == mode['name'];
                          return GestureDetector(
                            onTap: () => _event.selectMode(mode['name'] as String),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primaryDim
                                    : AppColors.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(28),
                                border: isSelected
                                    ? null
                                    : Border.all(
                                        color: AppColors.outlineVariant.withOpacity(0.2),
                                      ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    mode['name'] as String,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: isSelected
                                          ? AppColors.onPrimary
                                          : AppColors.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Icon(
                                    mode['icon'] as IconData,
                                    color: isSelected
                                        ? AppColors.onPrimary
                                        : AppColors.onSurfaceVariant,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        childCount: LightController.modes.length,
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 32)),
                    SliverToBoxAdapter(
                      child: Text(
                        '应援色预设',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 56,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: LightController.presets.length + 1,
                          itemBuilder: (context, index) {
                            if (index == LightController.presets.length) {
                              return Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.outlineVariant,
                                    style: BorderStyle.solid,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.add,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              );
                            }
                            final isSelected = _controller.selectedPreset == index;
                            return Padding(
                              padding: const EdgeInsets.only(right: 16),
                              child: GestureDetector(
                                onTap: () => _event.selectPreset(index),
                                child: Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: LightController.presets[index],
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: LightController.presets[index].withOpacity(0.4),
                                        blurRadius: 12,
                                      ),
                                    ],
                                    border: isSelected
                                        ? Border.all(
                                            color: AppColors.onSurface,
                                            width: 3,
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 120)),
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
