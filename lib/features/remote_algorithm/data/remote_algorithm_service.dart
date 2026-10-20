import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../domain/remote_calculation_result.dart';

class RemoteAlgorithmService extends ChangeNotifier {
  // Varsayılan servis adresi (Web/Windows için localhost, Android emülatör için 10.0.2.2)
  String _serverUrl = 'http://localhost:3000/api/calculate';
  bool _isOnline = false;
  bool _isChecking = false;

  String get serverUrl => _serverUrl;
  bool get isOnline => _isOnline;
  bool get isChecking => _isChecking;

  void updateServerUrl(String newUrl) {
    _serverUrl = newUrl.trim();
    notifyListeners();
  }

  /// Sunucu sağlık kontrolü (GET /api/health)
  Future<bool> checkServerHealth() async {
    _isChecking = true;
    notifyListeners();

    try {
      final baseUri = Uri.parse(_serverUrl);
      final healthUri = Uri(
        scheme: baseUri.scheme,
        host: baseUri.host,
        port: baseUri.port,
        path: '/api/health',
      );

      final response = await http.get(healthUri).timeout(const Duration(seconds: 2));
      _isOnline = (response.statusCode >= 200 && response.statusCode < 300);
    } catch (_) {
      _isOnline = false;
    } finally {
      _isChecking = false;
      notifyListeners();
    }
    return _isOnline;
  }

  /// 7 Girdiyi Web Servise gönderip hesaplatır (HTTP POST)
  Future<RemoteCalculationResult> calculate({
    required Map<String, double> inputs,
    bool allowSimulationFallback = true,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      final uri = Uri.parse(_serverUrl);
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'inputs': inputs}),
      ).timeout(const Duration(seconds: 4));

      stopwatch.stop();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _isOnline = true;
        notifyListeners();

        final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        return RemoteCalculationResult.fromJson(
          data,
          originalInputs: inputs,
          responseTimeMs: stopwatch.elapsedMilliseconds,
          isMock: false,
        );
      } else {
        throw Exception('Sunucu HTTP ${response.statusCode} hatası döndürdü');
      }
    } catch (e) {
      stopwatch.stop();
      _isOnline = false;
      notifyListeners();

      if (allowSimulationFallback) {
        // Sunucu henüz başlatılmadıysa sunumu kurtaran yerel simülasyon:
        await Future.delayed(const Duration(milliseconds: 300));
        return _simulateCalculation(inputs, stopwatch.elapsedMilliseconds);
      }
      rethrow;
    }
  }

  /// Sunucu kapalıyken Mansur Hoca'nın algoritmasını yerel taklit eden yedek
  RemoteCalculationResult _simulateCalculation(Map<String, double> inputs, int elapsedMs) {
    final x1 = inputs['x1'] ?? 0.0;
    final x2 = inputs['x2'] ?? 0.0;
    final x3 = inputs['x3'] ?? 0.0;
    final x4 = inputs['x4'] ?? 0.0;
    final x5 = inputs['x5'] ?? 0.0;
    final x6 = inputs['x6'] ?? 0.0;
    final x7 = inputs['x7'] ?? 0.0;

    final sum = x1 + x2 + x3 + x4;
    final sub = x5 + x6 + x7;
    final out = double.parse((sum - sub).toStringAsFixed(2));

    return RemoteCalculationResult(
      output: out,
      formula: '($x1 + $x2 + $x3 + $x4) - ($x5 + $x6 + $x7)',
      details: 'Toplanan: ${sum.toStringAsFixed(2)}, Çıkarılan: ${sub.toStringAsFixed(2)} (Simülasyon)',
      isSafe: out >= 0,
      inputs: inputs,
      timestamp: DateTime.now(),
      responseTimeMs: elapsedMs > 0 ? elapsedMs : 45,
      isMock: true,
    );
  }
}

