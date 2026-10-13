import 'core/contracts/calculation_strategy.dart';
import 'core/contracts/history_repository.dart';
import 'core/contracts/sync_service.dart';
import 'features/calculations/domain/strategies/concrete_strength_strategy.dart';
import 'features/calculations/domain/strategies/rebar_weight_strategy.dart';
import 'features/calculations/domain/strategies/soil_bearing_strategy.dart';
import 'features/history/data/in_memory_history_repository.dart';
import 'features/sync/data/mock_remote_sync_service.dart';

/// 🎯 COMPOSITION ROOT
/// Uygulamadaki tüm bağımlılıkların (Dependencies) oluşturulduğu ve
/// birbirine bağlandığı tek mimari merkez.
/// UI sınıfları bu sınıfları doğrudan oluşturmaz veya single-ton yapmaz.
class AppContainer {
  final List<CalculationStrategy> calculationStrategies;
  final HistoryRepository historyRepository;
  final SyncService syncService;

  const AppContainer({
    required this.calculationStrategies,
    required this.historyRepository,
    required this.syncService,
  });

  /// ID'ye göre formül stratejisini bulma yardımcısı
  CalculationStrategy? findStrategy(String id) {
    try {
      return calculationStrategies.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Uygulama ayağa kalkarken bağımlılıkları tek seferde inşa eder
  static Future<AppContainer> initialize() async {
    // 1. Hesaplama Motoru Stratejilerini Kaydet (Yeni formüller buraya eklenir)
    final strategies = <CalculationStrategy>[
      ConcreteStrengthStrategy(),
      RebarWeightStrategy(),
      SoilBearingStrategy(),
    ];

    // 2. Depo ve Servis Katmanlarını Kur
    final historyRepo = InMemoryHistoryRepository();
    final sync = MockRemoteSyncService();

    return AppContainer(
      calculationStrategies: List.unmodifiable(strategies),
      historyRepository: historyRepo,
      syncService: sync,
    );
  }
}

