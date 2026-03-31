import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 荧光棒与屏幕色差：按通道 **增益**（0.5～1.5，1.0 为默认）微调下发 RGB。
/// 在 [BleController.updateLightColor] 中、线序 [R↔B] 补偿之前应用。
class LightRgbCompensation extends ChangeNotifier {
  LightRgbCompensation._();
  static final LightRgbCompensation instance = LightRgbCompensation._();

  static const String _kR = 'light_rgb_gain_r';
  static const String _kG = 'light_rgb_gain_g';
  static const String _kB = 'light_rgb_gain_b';

  static const double minGain = 0.5;
  static const double maxGain = 1.5;

  double _rGain = 1.0;
  double _gGain = 1.0;
  double _bGain = 1.0;

  double get rGain => _rGain;
  double get gGain => _gGain;
  double get bGain => _bGain;

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      _rGain = (p.getDouble(_kR) ?? 1.0).clamp(minGain, maxGain);
      _gGain = (p.getDouble(_kG) ?? 1.0).clamp(minGain, maxGain);
      _bGain = (p.getDouble(_kB) ?? 1.0).clamp(minGain, maxGain);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _persist() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setDouble(_kR, _rGain);
      await p.setDouble(_kG, _gGain);
      await p.setDouble(_kB, _bGain);
    } catch (_) {}
  }

  void setRGain(double v) {
    _rGain = v.clamp(minGain, maxGain);
    notifyListeners();
    _persist();
  }

  void setGGain(double v) {
    _gGain = v.clamp(minGain, maxGain);
    notifyListeners();
    _persist();
  }

  void setBGain(double v) {
    _bGain = v.clamp(minGain, maxGain);
    notifyListeners();
    _persist();
  }

  Future<void> reset() async {
    _rGain = 1.0;
    _gGain = 1.0;
    _bGain = 1.0;
    notifyListeners();
    await _persist();
  }

  /// 对逻辑 [R,G,B]（0～255）做通道增益。
  List<int> apply(int r, int g, int b) {
    final rr = r.clamp(0, 255);
    final gg = g.clamp(0, 255);
    final bb = b.clamp(0, 255);
    return <int>[
      (rr * _rGain).round().clamp(0, 255),
      (gg * _gGain).round().clamp(0, 255),
      (bb * _bGain).round().clamp(0, 255),
    ];
  }
}
