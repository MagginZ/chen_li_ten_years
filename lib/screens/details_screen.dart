import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_container.dart';

/// Details Screen - Connection details and device info
/// Shows battery, signal strength, firmware version, and active theme
class DetailsScreen extends StatelessWidget {
  const DetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Ambient glow behind hero
          Positioned(
            top: 120,
            left: MediaQuery.of(context).size.width * 0.5 - 150,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.1),
                    blurRadius: 100,
                    spreadRadius: 50,
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
                children: [
                  const SizedBox(height: 24),
                  // Hero Section - Lightstick Visual
                  SizedBox(
                    height: 280,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Pulse ring
                        Container(
                          width: 260,
                          height: 260,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                        ),
                        // Icon container
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.2),
                                blurRadius: 30,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.fluorescent,
                            size: 120,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Connected badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.secondary.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.secondary.withOpacity(0.5),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'CONNECTED',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Device name
                  Text(
                    'PULSE STICK V2',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.01,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID: NP-LIGHT-8842-X',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Metrics Grid
                  Row(
                    children: [
                      // Battery Metric
                      Expanded(
                        child: GlassContainer(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              SizedBox(
                                width: 96,
                                height: 96,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    CircularProgressIndicator(
                                      value: 0.85,
                                      strokeWidth: 6,
                                      backgroundColor: AppColors.surfaceContainerHighest,
                                      valueColor: const AlwaysStoppedAnimation(AppColors.secondary),
                                    ),
                                    Text(
                                      '85%',
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'BATTERY LIFE',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Signal & Firmware
                      Expanded(
                        child: Column(
                          children: [
                            GlassContainer(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.signal_cellular_alt,
                                    color: AppColors.secondary,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Signal Strength',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ),
                                  Text(
                                    'Excellent',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.secondary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            GlassContainer(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.update,
                                    color: AppColors.tertiary,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Firmware',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ),
                                  Text(
                                    'v3.2.0',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Secondary Info Cards
                  GlassContainer(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.palette,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Active Theme',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Cyberpunk Neon Pink',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  GlassContainer(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.tertiary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.bluetooth_searching,
                            color: AppColors.tertiary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Auto-Sync',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Enabled during concert events',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        // Toggle switch
                        Container(
                          width: 40,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.tertiary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: AppColors.onTertiary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Actions
                  Container(
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: AppColors.errorGradient,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.errorDim.withOpacity(0.3),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.link_off,
                            color: AppColors.onBackground,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'DISCONNECT',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.onBackground,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.outlineVariant,
                      ),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.settings,
                            color: AppColors.onSurfaceVariant,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Advanced Connection Settings',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
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
