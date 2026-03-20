import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_container.dart';

/// Light/Colors Screen - Light control page
/// Features color wheel, brightness slider, lighting modes, and presets
class LightScreen extends StatefulWidget {
  const LightScreen({super.key});

  @override
  State<LightScreen> createState() => _LightScreenState();
}

class _LightScreenState extends State<LightScreen> {
  double _brightness = 0.84;
  String _selectedMode = 'Standard';
  int _selectedPreset = 0;

  final List<Map<String, dynamic>> _modes = [
    {'name': 'Standard', 'icon': Icons.radio_button_checked},
    {'name': 'Blink', 'icon': Icons.vibration},
    {'name': 'Flash', 'icon': Icons.flash_on},
    {'name': 'Breath', 'icon': Icons.air},
  ];

  final List<Color> _presets = [
    const Color(0xFFFF89AB), // Primary pink
    const Color(0xFFF8F5FD), // White
    const Color(0xFF26E6FF), // Cyan
    const Color(0xFFAC89FF), // Purple
    const Color(0xFFFF709E), // Pink container
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background decorations
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.05),
                    blurRadius: 120,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary.withOpacity(0.05),
                    blurRadius: 100,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ),
          ),
          // Main content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  // Main Kinetic Title
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Light ',
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.02,
                          ),
                        ),
                        TextSpan(
                          text: 'Aura',
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.02,
                            color: AppColors.primary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'SYNCED TO LIVE STAGE EFFECTS',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Color Wheel Bento Section
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Ambient glow behind wheel
                        Container(
                          width: 320,
                          height: 320,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.1),
                                blurRadius: 80,
                                spreadRadius: 40,
                              ),
                            ],
                          ),
                        ),
                        // The Wheel Shell
                        Container(
                          width: 320,
                          height: 320,
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
                          // Color wheel gradient
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: SweepGradient(
                                colors: [
                                  Colors.red,
                                  Colors.purple,
                                  Colors.blue,
                                  Colors.cyan,
                                  Colors.green,
                                  Colors.yellow,
                                  Colors.red,
                                ],
                              ),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Selector handle
                                Positioned(
                                  top: 80,
                                  left: 80,
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: AppColors.onSurface,
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
                                // Central Inner Shield
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
                                        'Hue Control',
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
                  const SizedBox(height: 40),
                  // Brightness Slider
                  GlassContainer(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'INTENSITY',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                            Text(
                              '${(_brightness * 100).toInt()}%',
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
                                  value: _brightness,
                                  onChanged: (value) {
                                    setState(() {
                                      _brightness = value;
                                    });
                                  },
                                  activeColor: AppColors.primary,
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
                  const SizedBox(height: 32),
                  // Lighting Modes Grid
                  Text(
                    'ATMOSPHERE MODES',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 3,
                    ),
                    itemCount: _modes.length,
                    itemBuilder: (context, index) {
                      final mode = _modes[index];
                      final isSelected = _selectedMode == mode['name'];
                      
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedMode = mode['name'];
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : AppColors.surfaceContainerHigh,
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
                                mode['name'],
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: isSelected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Icon(
                                mode['icon'],
                                color: isSelected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  // Presets
                  Text(
                    'FANDOM PRESETS',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ...List.generate(_presets.length, (index) {
                          final isSelected = _selectedPreset == index;
                          return Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedPreset = index;
                                });
                              },
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: _presets[index],
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: _presets[index].withOpacity(0.4),
                                      blurRadius: 20,
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
                        }),
                        // Add button
                        Container(
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
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
