import 'dart:math' as math;
import '../../../../core/contracts/calculation_strategy.dart';

/// Beton Basınç Dayanımı & Sınıfı Hesabı (TS EN 206 / TBDY 2018 Uygunluk)
class ConcreteStrengthStrategy implements CalculationStrategy {
  @override
  String get id => 'concrete_strength';

  @override
  String get title => 'Beton Basınç Dayanımı & Sınıflandırma';

  @override
  String get category => 'Malzeme & Beton';

  @override
  String get description =>
      'Su/Çimento oranı ve dozaja göre 28 günlük silindir karakteristik basınç dayanımı (fck) ve TS EN 206 sınıf hesabı.';

  @override
  List<CalculationParam> get parameters => const [
        CalculationParam(
          key: 'wc_ratio',
          label: 'Su / Çimento Oranı (w/c)',
          unit: '',
          defaultValue: 0.48,
          min: 0.35,
          max: 0.70,
          stepDecimals: 2,
          hint: 'Düşük oran daha yüksek dayanım sağlar (Tipik: 0.40 - 0.55)',
        ),
        CalculationParam(
          key: 'cement',
          label: 'Çimento Dozajı',
          unit: 'kg/m³',
          defaultValue: 350.0,
          min: 250.0,
          max: 500.0,
          stepDecimals: 0,
          hint: '1 m³ betondaki çimento ağırlığı (Tipik: 300 - 400 kg/m³)',
        ),
        CalculationParam(
          key: 'air_content',
          label: 'Hava Boşluk Oranı',
          unit: '%',
          defaultValue: 2.0,
          min: 1.0,
          max: 6.0,
          stepDecimals: 1,
          hint: 'Taze betondaki hapsolmuş hava oranı',
        ),
      ];

  @override
  CalculationExecutionResult calculate(Map<String, double> inputs) {
    final wc = inputs['wc_ratio'] ?? 0.48;
    final cement = inputs['cement'] ?? 350.0;
    final air = inputs['air_content'] ?? 2.0;

    // Feret / Abrams amprik yaklaşımı:
    // fcm = 98 / (3.6 ^ wc) * (cement / 350)^0.75 * (1 - air * 0.05)
    final baseStrength = 98.0 / math.pow(3.6, wc);
    final doseFactor = math.pow(cement / 350.0, 0.75);
    final airFactor = 1.0 - (air * 0.05);

    final fcm = baseStrength * doseFactor * airFactor; // Ortalama silindir dayanımı (MPa)
    final fck = fcm - 8.0; // Karakteristik silindir dayanımı (MPa)
    final fckCube = fck * 1.22; // Eşdeğer küp dayanımı (MPa)

    final roundedFck = double.parse(fck.toStringAsFixed(1));
    final roundedCube = double.parse(fckCube.toStringAsFixed(1));

    String className;
    if (roundedFck >= 40) {
      className = 'C40/50';
    } else if (roundedFck >= 35) {
      className = 'C35/45';
    } else if (roundedFck >= 30) {
      className = 'C30/37';
    } else if (roundedFck >= 25) {
      className = 'C25/30';
    } else if (roundedFck >= 20) {
      className = 'C20/25';
    } else {
      className = 'C16/20 (Yetersiz)';
    }

    // TBDY 2018 Madde 5.2.1: Taşıyıcı elemanlarda C25/30 altı beton kullanılamaz.
    final bool isSafe = roundedFck >= 25.0;
    final List<String> warnings = [];

    if (!isSafe) {
      warnings.add('⚠️ TBDY 2018 Uyarısı: Taşıyıcı sistemlerde minimum C25/30 beton zorunludur! Hesaplanan fck = $roundedFck MPa yetersizdir.');
    }
    if (wc > 0.55) {
      warnings.add('ℹ️ Su/Çimento oranı 0.55 üzerinde; rötre ve çatlak riski artar.');
    }

    return CalculationExecutionResult(
      outputs: {
        'Karakteristik Silindir (fck)': roundedFck,
        'Karakteristik Küp (fck,cube)': roundedCube,
        'Ortalama Dayanım (fcm)': double.parse(fcm.toStringAsFixed(1)),
      },
      outputUnits: {
        'Karakteristik Silindir (fck)': 'MPa (N/mm²)',
        'Karakteristik Küp (fck,cube)': 'MPa (N/mm²)',
        'Ortalama Dayanım (fcm)': 'MPa (N/mm²)',
      },
      summary: 'Beton Sınıfı: $className (fck = $roundedFck MPa). ${isSafe ? "TBDY 2018 taşıyıcı sistem gereksinimlerini karşılar." : "Deprem yönetmeliği sınırının altındadır!"}',
      isSafe: isSafe,
      warnings: warnings,
    );
  }
}

