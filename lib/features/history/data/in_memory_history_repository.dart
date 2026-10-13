import 'dart:collection';
import '../../../core/contracts/calculation_strategy.dart';
import '../../../core/contracts/history_repository.dart';
import '../../calculations/domain/calculation_record.dart';

/// Hızlı, hafif ve optimize yerel depo (In-Memory + genişletilebilir)
class InMemoryHistoryRepository extends HistoryRepository {
  final List<CalculationRecord> _records = [];

  InMemoryHistoryRepository() {
    _seedInitialData();
  }

  @override
  UnmodifiableListView<CalculationRecord> get records =>
      UnmodifiableListView(_records);

  @override
  Future<void> saveRecord(CalculationRecord record) async {
    // En yeni kayıt en başa
    _records.removeWhere((r) => r.id == record.id);
    _records.insert(0, record);
    notifyListeners();
  }

  @override
  Future<void> deleteRecord(String id) async {
    _records.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  @override
  Future<void> clearAll() async {
    _records.clear();
    notifyListeners();
  }

  void _seedInitialData() {
    // Mansur Hoca ilk açtığında boş görmesin diye 2 adet gerçekçi örnek şantiye kaydı:
    _records.addAll([
      CalculationRecord(
        id: 'seed-01',
        formulaId: 'concrete_strength',
        title: 'Beton Basınç Dayanımı & Sınıflandırma',
        category: 'Malzeme & Beton',
        projectName: 'İzmir Şantiye - A Blok Kolonları',
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        inputs: {'wc_ratio': 0.45, 'cement': 375.0, 'air_content': 2.0},
        result: const CalculationExecutionResult(
          outputs: {
            'Karakteristik Silindir (fck)': 33.8,
            'Karakteristik Küp (fck,cube)': 41.2,
            'Ortalama Dayanım (fcm)': 41.8,
          },
          outputUnits: {
            'Karakteristik Silindir (fck)': 'MPa',
            'Karakteristik Küp (fck,cube)': 'MPa',
            'Ortalama Dayanım (fcm)': 'MPa',
          },
          summary: 'Beton Sınıfı: C30/37 (fck = 33.8 MPa). TBDY 2018 uygundur.',
          isSafe: true,
          warnings: [],
        ),
      ),
      CalculationRecord(
        id: 'seed-02',
        formulaId: 'rebar_weight',
        title: 'Donatı Metrajı & Çelik Tonajı',
        category: 'Statik & Çelik',
        projectName: 'Bornova Metro - Temel Donatıları',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        inputs: {'diameter': 20.0, 'length': 12.0, 'count': 80.0, 'waste_percent': 5.0},
        result: const CalculationExecutionResult(
          outputs: {
            'Birim Ağırlık': 2.469,
            'Toplam Metraj': 960.0,
            'Net Ağırlık': 2370.4,
            'Fire Dahil Ağırlık': 2488.9,
            'Sipariş Tonajı': 2.489,
          },
          outputUnits: {
            'Birim Ağırlık': 'kg/m',
            'Toplam Metraj': 'm',
            'Net Ağırlık': 'kg',
            'Fire Dahil Ağırlık': 'kg',
            'Sipariş Tonajı': 'ton',
          },
          summary: 'Toplam 80 adet Ø20 donatı: Net 2370.4 kg, fire dahil 2.49 ton çelik gereklidir.',
          isSafe: true,
          warnings: [],
        ),
      ),
    ]);
  }
}

