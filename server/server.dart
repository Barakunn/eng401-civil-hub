// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

const int port = 3000;

Map<String, dynamic> executeAlgorithm(Map<String, dynamic> inputs) {
  final x1 = (inputs['x1'] as num?)?.toDouble() ?? 0.0;
  final x2 = (inputs['x2'] as num?)?.toDouble() ?? 0.0;
  final x3 = (inputs['x3'] as num?)?.toDouble() ?? 0.0;
  final x4 = (inputs['x4'] as num?)?.toDouble() ?? 0.0;
  final x5 = (inputs['x5'] as num?)?.toDouble() ?? 0.0;
  final x6 = (inputs['x6'] as num?)?.toDouble() ?? 0.0;
  final x7 = (inputs['x7'] as num?)?.toDouble() ?? 0.0;

  final sumGroup = x1 + x2 + x3 + x4;
  final subGroup = x5 + x6 + x7;
  final finalOutput = sumGroup - subGroup;

  return {
    'output': double.parse(finalOutput.toStringAsFixed(2)),
    'formula': '($x1 + $x2 + $x3 + $x4) - ($x5 + $x6 + $x7)',
    'details': 'Toplanan: ${sumGroup.toStringAsFixed(2)}, Çıkarılan: ${subGroup.toStringAsFixed(2)}',
    'isSafe': finalOutput >= 0,
    'timestamp': DateTime.now().toIso8601String(),
  };
}

void main() async {
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  print('=======================================================');
  print('🚀 ENG401 Dart Web Servisi Başlatıldı!');
  print('📡 Dinlenen Adres: http://localhost:$port');
  print('📌 Hesaplama URL : http://localhost:$port/api/calculate');
  print('💡 7 input alıp 1 output dönen servis aktif.');
  print('=======================================================');

  await for (HttpRequest request in server) {
    // CORS
    request.response.headers
      ..set('Access-Control-Allow-Origin', '*')
      ..set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
      ..set('Access-Control-Allow-Headers', 'Content-Type, Authorization')
      ..set('Content-Type', 'application/json; charset=utf-8');

    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.noContent;
      await request.response.close();
      continue;
    }

    if (request.method == 'GET' && (request.uri.path == '/' || request.uri.path == '/api/health')) {
      request.response.statusCode = HttpStatus.ok;
      request.response.write(jsonEncode({
        'status': 'online',
        'service': 'ENG401 Dart Calculation Web Service',
        'endpoint': '/api/calculate',
      }));
      await request.response.close();
      continue;
    }

    if (request.method == 'POST' && request.uri.path == '/api/calculate') {
      try {
        final content = await utf8.decoder.bind(request).join();
        final Map<String, dynamic> payload = jsonDecode(content.isEmpty ? '{}' : content);
        final Map<String, dynamic> inputs = payload['inputs'] is Map<String, dynamic>
            ? payload['inputs'] as Map<String, dynamic>
            : payload;

        print('[${DateTime.now().toIso8601String()}] 7 Girdi Alındı: $inputs');
        final result = executeAlgorithm(inputs);
        print('[${DateTime.now().toIso8601String()}] Hesaplanan Çıktı: ${result['output']}');

        request.response.statusCode = HttpStatus.ok;
        request.response.write(jsonEncode({
          'status': 'success',
          'output': result['output'],
          'formula': result['formula'],
          'details': result['details'],
          'isSafe': result['isSafe'],
          'receivedInputs': inputs,
          'timestamp': result['timestamp'],
        }));
      } catch (e) {
        request.response.statusCode = HttpStatus.badRequest;
        request.response.write(jsonEncode({
          'status': 'error',
          'message': 'Geçersiz veri: $e',
        }));
      }
      await request.response.close();
      continue;
    }

    request.response.statusCode = HttpStatus.notFound;
    request.response.write(jsonEncode({'status': 'error', 'message': 'Bulunamadı'}));
    await request.response.close();
  }
}

