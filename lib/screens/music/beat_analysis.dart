import 'package:audio_waveforms/audio_waveforms.dart';

/// 从整段 RMS 包络中挑「疑似节拍」时刻（能量/起音峰值），非专业 onset，仅作近似。
List<int> pickBeatTimesMsFromEnvelope(
  List<double> envelope,
  int durationMs, {
  double minIntervalMs = 280,
  double peakThreshold = 0.42,
}) {
  if (envelope.length < 5 || durationMs <= 0) return [];
  final n = envelope.length;
  var maxV = 0.0;
  for (final v in envelope) {
    if (v > maxV) maxV = v;
  }
  if (maxV < 1e-9) return [];
  final w = envelope.map((e) => e / maxV).toList(growable: false);

  final onset = List<double>.filled(n, 0);
  for (var i = 1; i < n; i++) {
    final d = w[i] - w[i - 1];
    onset[i] = d > 0 ? d : 0;
  }

  final minGap = (minIntervalMs / durationMs * n).ceil().clamp(2, n);
  final beats = <int>[];
  var lastI = -minGap;
  for (var i = 2; i < n - 2; i++) {
    if (i - lastI < minGap) continue;
    final o = onset[i];
    if (o < peakThreshold * 0.35) continue;
    if (o <= onset[i - 1] || o <= onset[i + 1]) continue;
    beats.add(((i * durationMs) / n).round().clamp(0, durationMs));
    lastI = i;
  }
  return beats;
}

/// 解码本地音频文件并提取包络，再 [pickBeatTimesMsFromEnvelope]。
Future<List<int>> extractBeatTimesMsFromFile(
  String filePath,
  int durationMs, {
  int envelopeSamples = 360,
}) async {
  if (durationMs <= 0) return [];
  final extractor = WaveformExtractionController();
  final data = await extractor.extractWaveformData(
    path: filePath,
    noOfSamples: envelopeSamples.clamp(80, 2000),
  );
  return pickBeatTimesMsFromEnvelope(data, durationMs);
}
