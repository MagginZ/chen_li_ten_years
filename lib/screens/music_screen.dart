import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_container.dart';

/// Music Screen - Music synchronization page
/// Features album artwork, track info, sync controls, and playback controls
class MusicScreen extends StatelessWidget {
  const MusicScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background ambiance
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
                    color: AppColors.primary.withOpacity(0.2),
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
                    color: AppColors.tertiary.withOpacity(0.1),
                    blurRadius: 120,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),
          // Visualizer gradient overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 200,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    AppColors.primary.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Main content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  // Album Artwork Section
                  AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withOpacity(0.5),
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
                              AppColors.primary.withOpacity(0.8),
                              AppColors.tertiary.withOpacity(0.8),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.album,
                            size: 120,
                            color: AppColors.white.withOpacity(0.3),
                          ),
                        ),
                      ),
                    ),
                  ),
                  ),
                  const SizedBox(height: 40),
                  // Track Metadata
                  Text(
                    'Cyber Symphony',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.01,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ASTRO-V · Neon Dreams',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.secondaryFixed,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Sync Toggle Control
                  GlassContainer(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        // Pulsing icon
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              Icons.fluorescent,
                              color: AppColors.primary,
                            ),
                          ),
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
                                'Synchronizing with beat...',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        // Toggle switch
                        Container(
                          width: 56,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: AppColors.onPrimary,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.black.withOpacity(0.2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Playback Progress
                  Column(
                    children: [
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: FractionallySizedBox(
                          widthFactor: 0.45,
                          alignment: Alignment.centerLeft,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.secondary,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '01:42',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontFamily: 'monospace',
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            '03:54',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontFamily: 'monospace',
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Playback Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: Icon(
                          Icons.shuffle,
                          color: AppColors.onSurface.withOpacity(0.6),
                        ),
                        iconSize: 32,
                      ),
                      const SizedBox(width: 24),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.skip_previous),
                        iconSize: 40,
                        color: AppColors.onSurface,
                      ),
                      const SizedBox(width: 16),
                      // Play/Pause button
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.primaryDim,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.4),
                              blurRadius: 30,
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.pause),
                          iconSize: 40,
                          color: AppColors.onPrimary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.skip_next),
                        iconSize: 40,
                        color: AppColors.onSurface,
                      ),
                      const SizedBox(width: 24),
                      IconButton(
                        onPressed: () {},
                        icon: Icon(
                          Icons.repeat,
                          color: AppColors.onSurface.withOpacity(0.6),
                        ),
                        iconSize: 32,
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  // Secondary Controls
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
  }
}
