import 'package:flutter/material.dart';
import '../../ble/ble_controller.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_container.dart';
import 'controller/scan_controller.dart';
import 'event/scan_event.dart' show ScanEvent, formatBleMacForDisplay;

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  late final ScanController _controller;
  late final ScanEvent _event;

  @override
  void initState() {
    super.initState();
    _controller = ScanController();
    _event = ScanEvent(_controller);
    _event.rescan();
  }

  @override
  void dispose() {
    _event.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_controller, BleController.instance]),
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              RepaintBoundary(
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.surface,
                            AppColors.surfaceContainerLowest,
                            AppColors.surface,
                          ],
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            _buildRadarRing(300),
                            _buildRadarRing(500),
                            _buildRadarRing(700),
                            _buildRadarRing(900),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: MediaQuery.of(context).size.height * 0.3,
                      left: MediaQuery.of(context).size.width * 0.5 - 100,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.05),
                              blurRadius: 100,
                              spreadRadius: 50,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: CustomScrollView(
                    slivers: [
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),
                    SliverToBoxAdapter(
                      child: Text(
                        _controller.isScanning ? '扫描中…' : '已发现设备',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.02,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
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
                              _controller.isScanning
                                ? '正在搜索附近的设备'
                                : '共 ${_controller.devices.length} 台设备可用',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 48)),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final d = _controller.devices[index];
                          final connectedId =
                              BleController.instance.connectedDevice?.remoteId.str;
                          final isConnectedToThis = BleController.instance.isConnected &&
                              connectedId != null &&
                              connectedId == d.id;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildDeviceCard(
                              context,
                              d.name,
                              formatBleMacForDisplay(d.id),
                              d.signal,
                              d.signalColor,
                              d.isPrimary,
                              d.isLednet,
                              isConnectedToThis,
                              isConnectedToThis
                                  ? () => BleController.instance.disconnect()
                                  : () => _event.connectDevice(index),
                            ),
                          );
                        },
                        childCount: _controller.devices.length,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.outlineVariant.withOpacity(0.2),
                              style: BorderStyle.solid,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.info_outline, color: AppColors.onSurfaceVariant),
                              const SizedBox(height: 8),
                              Text(
                                '找不到设备？请确认设备已进入配对模式；含 LEDnet 的设备会置顶显示',
                                style: Theme.of(context).textTheme.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                '匿名广播将显示为 MAC 地址',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 32),
                        child: IgnorePointer(
                          ignoring: _controller.isScanning,
                          child: Opacity(
                            opacity: _controller.isScanning ? 0.5 : 1,
                            child: GlowButton(
                              onPressed: () => _event.rescan(),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.sync,
                                    color: AppColors.onPrimaryFixed,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '重新扫描设备',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      color: AppColors.onPrimaryFixed,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
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

  Widget _buildRadarRing(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
    );
  }

  Widget _buildDeviceCard(
    BuildContext context,
    String name,
    String idFormatted,
    String signal,
    Color signalColor,
    bool isPrimary,
    bool isLednet,
    bool isConnectedToThis,
    VoidCallback? onConnect,
  ) {
    final displayId =
        idFormatted.length > 20 ? '${idFormatted.substring(0, 17)}...' : idFormatted;
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHighest,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white.withOpacity(0.05)),
                ),
                child: Icon(
                  Icons.fluorescent,
                  color: isPrimary ? AppColors.primary : AppColors.onSurfaceVariant,
                  size: 28,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isPrimary ? AppColors.secondaryContainer : AppColors.surfaceVariant,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 2),
                  ),
                  child: Icon(
                    Icons.bluetooth_searching,
                    color: isPrimary ? AppColors.secondary : AppColors.onSurfaceVariant,
                    size: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (isLednet)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.kineticNeon.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.kineticNeon.withOpacity(0.6)),
                          ),
                          child: Text(
                            'LEDnet',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppColors.kineticNeon,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.signal_cellular_alt, color: signalColor, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      signal.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: signalColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '标识：$displayId',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onConnect,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isConnectedToThis
                    ? AppColors.kineticNeon.withOpacity(0.2)
                    : (isPrimary ? AppColors.primary : AppColors.surfaceVariant),
                borderRadius: BorderRadius.circular(20),
                border: isConnectedToThis
                    ? Border.all(color: AppColors.kineticNeon.withOpacity(0.5))
                    : null,
                boxShadow: !isConnectedToThis && isPrimary
                    ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20)]
                    : null,
              ),
              child: Text(
                isConnectedToThis ? '断开' : '连接',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isConnectedToThis
                      ? AppColors.kineticNeon
                      : (isPrimary ? AppColors.onPrimaryFixed : AppColors.onSurfaceVariant),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
