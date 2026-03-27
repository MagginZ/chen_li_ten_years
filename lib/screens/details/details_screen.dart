import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_container.dart';
import '../../ble/ble_controller.dart';
import 'controller/details_controller.dart';
import 'event/details_event.dart';

class DetailsScreen extends StatefulWidget {
  const DetailsScreen({super.key});

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  late final DetailsController _controller;
  late final DetailsEvent _event;

  @override
  void initState() {
    super.initState();
    _controller = DetailsController();
    _event = DetailsEvent(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ble = BleController.instance;

    return ListenableBuilder(
      listenable: Listenable.merge([_controller, ble]),
      builder: (context, _) {
        final controller = _controller;
        final event = _event;
        final connectedDevice = ble.connectedDevice;
        final deviceName = connectedDevice?.platformName.isNotEmpty == true
            ? connectedDevice!.platformName
            : '荧光棒';
        final deviceId = connectedDevice?.remoteId.str ?? '无设备';
        final connectionLabel = ble.isConnected ? '已连接' : '未连接';
        final connectionColor = ble.isConnected ? AppColors.secondary : AppColors.error;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              Positioned(
                top: 120,
                left: MediaQuery.of(context).size.width * 0.5 - 150,
                child: RepaintBoundary(
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
              ),
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 280,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: connectionColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: connectionColor.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: connectionColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: connectionColor.withOpacity(0.5),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              connectionLabel,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: connectionColor,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        deviceName.toUpperCase(),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.01,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '标识：$deviceId',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
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
                                          value: controller.batteryLevel,
                                          strokeWidth: 6,
                                          backgroundColor: AppColors.surfaceContainerHighest,
                                          valueColor: const AlwaysStoppedAnimation(AppColors.secondary),
                                        ),
                                        Text(
                                          '${(controller.batteryLevel * 100).toInt()}%',
                                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    '电量',
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
                          Expanded(
                            child: Column(
                              children: [
                                GlassContainer(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Icon(Icons.signal_cellular_alt, color: AppColors.secondary),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          '信号强度',
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                      ),
                                      Text(
                                        controller.signalStrength,
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
                                      Icon(Icons.update, color: AppColors.tertiary),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          '固件版本',
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                      ),
                                      Text(
                                        controller.firmwareVersion,
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
                              child: Icon(Icons.palette, color: AppColors.primary),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '当前主题',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    controller.activeTheme,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant),
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
                              child: Icon(Icons.bluetooth_searching, color: AppColors.tertiary),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '自动同步',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    ble.autoSyncEnabled
                                        ? '演唱会期间启用'
                                        : '已关闭',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => event.toggleAutoSync(),
                              child: Container(
                                width: 40,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: ble.autoSyncEnabled
                                      ? AppColors.tertiary
                                      : AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Align(
                                    alignment: ble.autoSyncEnabled
                                        ? Alignment.centerRight
                                        : Alignment.centerLeft,
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
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      GestureDetector(
                        onTap: () => event.disconnect(),
                        child: Container(
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
                                Icon(Icons.link_off, color: AppColors.onBackground),
                                const SizedBox(width: 8),
                                Text(
                                  '断开连接',
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
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 56,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.outlineVariant),
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
                                '高级连接设置',
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
      },
    );
  }
}
