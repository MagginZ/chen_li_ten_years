import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'debug/ble_scan_ui.dart';
import 'theme/app_theme.dart';
import 'widgets/app_header.dart';
import 'widgets/bottom_nav_bar.dart';
import 'ble/ble_controller.dart';
import 'settings/light_rgb_compensation.dart';
import 'screens/scan/scan_screen.dart';
import 'screens/details/details_screen.dart';
import 'screens/music/music_tab_screen.dart';
import 'screens/light/light_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Web 平台不支持蓝牙权限，跳过
  if (!kIsWeb) {
    await Permission.bluetooth.request();
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
    final locStatus = await Permission.locationWhenInUse.status;
    if (locStatus.isDenied) {
      await Permission.locationWhenInUse.request();
    }
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
    overlays: [SystemUiOverlay.top],
  );

  await LightRgbCompensation.instance.load();

  runApp(const NeonPulseApp());
}

class NeonPulseApp extends StatelessWidget {
  const NeonPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      title: '果实',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    BleController.instance.onNavigateToTab = (index) {
      setState(() => _currentIndex = index);
    };
  }

  final List<Widget> _screens = [
    const ScanScreen(),
    const DetailsScreen(),
    const MusicTabScreen(),
    const LightScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return Scaffold(
      extendBodyBehindAppBar: false,
      extendBody: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(topInset + 56),
        child: const AppHeader(),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NeonBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
      ),
    );
  }
}
