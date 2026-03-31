import 'package:flutter/material.dart';
import '../ble/ble_controller.dart';
import '../theme/app_colors.dart';

/// 顶部栏：高度 = 状态栏 + 56，避免与系统状态栏重叠（勿在子级再包一层 SafeArea 占满固定高度）。
class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  static const Color _kineticConnected = AppColors.kineticNeon;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return ListenableBuilder(
      listenable: BleController.instance,
      builder: (context, _) {
        final connected = BleController.instance.isConnected;
        final brandColor = connected ? AppColors.primary : AppColors.onSurfaceVariant;
        final iconColor = connected ? AppColors.primary : AppColors.onSurfaceVariant;

        return Container(
          height: top + 56,
          padding: EdgeInsets.only(top: top, left: 24, right: 24),
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.92),
            border: Border(
              bottom: BorderSide(
                color: AppColors.white.withOpacity(0.05),
              ),
            ),
            boxShadow: [
              if (connected)
                BoxShadow(
                  color: _kineticConnected.withOpacity(0.42),
                  blurRadius: 40,
                  spreadRadius: 0,
                  offset: Offset.zero,
                )
              else
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.sensors,
                color: iconColor,
                size: 24,
                shadows: connected
                    ? [
                        Shadow(
                          color: _kineticConnected.withOpacity(0.9),
                          blurRadius: 16,
                        ),
                      ]
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                '果实',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: brandColor,
                      letterSpacing: 1.4,
                    ),
              ),
              const Spacer(),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHighest,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.outlineVariant,
                  ),
                ),
                child: Icon(
                  Icons.person,
                  color: AppColors.onSurfaceVariant,
                  size: 20,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
