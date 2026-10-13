import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/contracts/calculation_strategy.dart';
import '../../../core/contracts/sync_service.dart';
import '../../calculations/domain/calculation_record.dart';

/// Hem Simüle Edilmiş Cloud Server hem de Gerçek REST API destekleyen Servis
class MockRemoteSyncService extends SyncService {
  SyncConnectionState _state = SyncConnectionState.online;
  String _endpoint = 'https://api.eng401-civilhub.internal/v1';

  // Sunucudaki kayıtları temsil eden bulut veritabanı
  final List<CalculationRecord> _remoteCloudDb = [];

  MockRemoteSyncService() {
    _seedRemoteCloudDb();
  }

  @override
  SyncConnectionState get connectionState => _state;

  @override
  String get serverEndpoint => _endpoint;

  @override
  void updateEndpoint(String newUrl) {
    _endpoint = newUrl.trim();
    notifyListeners();
  }

  void toggleOnlineStatus(bool isOnline) {
    _state = isOnline ? SyncConnectionState.online : SyncConnectionState.offline;
    notifyListeners();
  }

  @override
  Future<bool> pushRecord(CalculationRecord record) async {
    if (_state == SyncConnectionState.offline) return false;

    _state = SyncConnectionState.syncing;
    notifyListeners();

    try {
      // Eğer gerçek bir HTTP adresi girildiyse gerçek istek atar
      if (_endpoint.startsWith('http://') || _endpoint.startsWith('https://')) {
        if (!_endpoint.contains('.internal')) {
          try {
            final response = await http.post(
              Uri.parse('$_endpoint/calculations'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(record.toJson()),
            ).timeout(const Duration(seconds: 4));
            if (response.statusCode >= 200 && response.statusCode < 300) {
              _state = SyncConnectionState.online;
              notifyListeners();
              return true;
            }
          } catch (_) {
            // Gerçek sunucu yoksa veya ulaşılamıyorsa simülasyona devam et
          }
        }
      }

      // Bulut simülasyonu gecikmesi (Sahadaki 4G/5G servis tepkisi)
      await Future.delayed(const Duration(milliseconds: 700));

      _remoteCloudDb.removeWhere((r) => r.id == record.id);
      _remoteCloudDb.insert(0, record);

      _state = SyncConnectionState.online;
      notifyListeners();
      return true;
    } catch (_) {
      _state = SyncConnectionState.online;
      notifyListeners();
      return false;
    }
  }

  @override
  Future<int> batchSync(List<CalculationRecord> localRecords) async {
    if (_state == SyncConnectionState.offline) return 0;

    _state = SyncConnectionState.syncing;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 900));

    int count = 0;
    for (final rec in localRecords) {
      if (!_remoteCloudDb.any((r) => r.id == rec.id)) {
        _remoteCloudDb.add(rec);
        count++;
      }
    }

    _state = SyncConnectionState.online;
    notifyListeners();
    return count;
  }

  @override
  Future<List<CalculationRecord>> fetchRemoteRecords() async {
    if (_state == SyncConnectionState.offline) return [];

    _state = SyncConnectionState.syncing;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 800));

    _state = SyncConnectionState.online;
    notifyListeners();
    return List.unmodifiable(_remoteCloudDb);
  }

  void _seedRemoteCloudDb() {
    _remoteCloudDb.add(
      CalculationRecord(
        id: 'cloud-seed-01',
        formulaId: 'soil_bearing',
        title: 'Zemin Emniyetli Taşıma Gücü',
        category: 'Geoteknik & Zemin',
        projectName: 'Merkez Şantiye - Geoteknik Sondaj Raporu',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        inputs: {
          'cohesion': 25.0,
          'friction_angle': 28.0,
          'unit_weight': 18.5,
          'width_b': 2.5,
          'depth_d': 2.0,
          'safety_factor': 3.0,
        },
        result: const CalculationExecutionResult(
          outputs: {
            'Nihai Taşıma Gücü (qu)': 645.2,
            'Emniyetli Gerilme (qsafe)': 215.1,
            'Emniyetli Gerilme': 2.19,
          },
          outputUnits: {
            'Nihai Taşıma Gücü (qu)': 'kN/m²',
            'Emniyetli Gerilme (qsafe)': 'kN/m²',
            'Emniyetli Gerilme': 'kg/cm²',
          },
          summary: 'Zemin Emniyetli Gerilmesi: 215.1 kN/m² (~2.19 kg/cm²). FS=3.0 uygundur.',
          isSafe: true,
          warnings: [],
        ),
      ),
    );
  }
}

