import 'package:flutter/foundation.dart';
import '../../features/calculations/domain/calculation_record.dart';

enum SyncConnectionState { online, offline, syncing }

/// Sunucu / Bulut Veri Senkronizasyonu Arayüzü (Mansur Hoca'nın istediği servis yapısı)
abstract class SyncService extends ChangeNotifier {
  SyncConnectionState get connectionState;
  String get serverEndpoint;
  void updateEndpoint(String newUrl);

  /// Tek bir hesabı sunucuya yükle (POST)
  Future<bool> pushRecord(CalculationRecord record);

  /// Birden çok hesabı toplu senkronize et
  Future<int> batchSync(List<CalculationRecord> localRecords);

  /// Sunucudan projeleri ve hesap kayıtlarını çek (GET)
  Future<List<CalculationRecord>> fetchRemoteRecords();
}

