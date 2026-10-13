import '../../../../core/contracts/calculation_strategy.dart';

/// Donatı Çelik Metrajı & Ağırlık Hesabı (TS 708 / TS 500 Standartları)
class RebarWeightStrategy implements CalculationStrategy {
  @override
  String get id => 'rebar_weight';

  @override
  String get title => 'Donatı Metrajı & Çelik Tonajı';

  @override
  String get category => 'Statik & Çelik';

  @override
  String get description =>
      'Donatı çapı (Ø), boy, adet ve şantiye fire oranına göre toplam metraj, birim ağırlık ve sipariş tonaj hesabı.';

  @override
  int get iconCodePoint => 0xe318; // iron / hardware icon

  @override
  List<CalculationParam> get parameters => const [
        CalculationParam(
          key: 'diameter',
          label: 'Donatı Çapı (Ø)',
          unit: 'mm',
          defaultValue: 16.0,
          min: 8.0,
          max: 32.0,
          stepDecimals: 0,
          hint: 'Standart çaplar: 8, 10, 12, 14, 16, 20, 25, 32 mm',
        ),
        CalculationParam(
          key: 'length',
          label: 'Çubuk Tekil Boyu',
          unit: 'm',
          defaultValue: 12.0,
          min: 1.0,
          max: 18.0,
          stepDecimals: 2,
          hint: 'Standart ticari boy: 12.00 metre',
        ),
        CalculationParam(
          key: 'count',
          label: 'Çubuk Adedi',
          unit: 'adet',
          defaultValue: 25.0,
          min: 1.0,
          max: 500.0,
          stepDecimals: 0,
          hint: 'Toplam kullanılacak çubuk sayısı',
        ),
        CalculationParam(
          key: 'waste_percent',
          label: 'Şantiye Fire Oranı',
          unit: '%',
          defaultValue: 4.0,
          min: 0.0,
          max: 15.0,
          stepDecimals: 1,
          hint: 'Kesme/bükme şantiye fire payı (Tipik: %3 - %5)',
        ),
      ];

  @override
  CalculationExecutionResult calculate(Map<String, double> inputs) {
    final d = inputs['diameter'] ?? 16.0;
    final len = inputs['length'] ?? 12.0;
    final count = inputs['count'] ?? 25.0;
    final waste = inputs['waste_percent'] ?? 4.0;

    // TS 708 Birim Ağırlık Formülü: q = d^2 / 162 (kg/m)
    final unitWeight = (d * d) / 162.0;
    final totalLength = len * count;
    final netWeightKg = unitWeight * totalLength;
    final wasteMultiplier = 1.0 + (waste / 100.0);
    final grossWeightKg = netWeightKg * wasteMultiplier;
    final grossTon = grossWeightKg / 1000.0;

    final roundedUnit = double.parse(unitWeight.toStringAsFixed(3));
    final roundedNetKg = double.parse(netWeightKg.toStringAsFixed(1));
    final roundedGrossKg = double.parse(grossWeightKg.toStringAsFixed(1));
    final roundedGrossTon = double.parse(grossTon.toStringAsFixed(3));

    final warnings = <String>[];
    if (d < 12.0) {
      warnings.add('ℹ️ Ø$d genellikle etriye veya hasır çelik olarak kullanılır, ana boyuna donatı için Ø14+ önerilir.');
    }

    return CalculationExecutionResult(
      outputs: {
        'Birim Ağırlık': roundedUnit,
        'Toplam Metraj': totalLength,
        'Net Ağırlık': roundedNetKg,
        'Fire Dahil Ağırlık': roundedGrossKg,
        'Sipariş Tonajı': roundedGrossTon,
      },
      outputUnits: {
        'Birim Ağırlık': 'kg/m',
        'Toplam Metraj': 'm',
        'Net Ağırlık': 'kg',
        'Fire Dahil Ağırlık': 'kg',
        'Sipariş Tonajı': 'ton',
      },
      summary:
          'Toplam $count adet Ø${d.toInt()} donatı: Net $roundedNetKg kg, fire dahil $roundedGrossTon ton çelik gereklidir.',
      isSafe: true,
      warnings: warnings,
    );
  }
}

