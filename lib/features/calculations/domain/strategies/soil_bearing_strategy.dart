import 'dart:math' as math;
import '../../../../core/contracts/calculation_strategy.dart';

/// Zemin Emniyetli Taşıma Gücü Hesabı (Terzaghi Taşıma Gücü Yaklaşımı)
class SoilBearingStrategy implements CalculationStrategy {
  @override
  String get id => 'soil_bearing';

  @override
  String get title => 'Zemin Emniyetli Taşıma Gücü';

  @override
  String get category => 'Geoteknik & Zemin';

  @override
  String get description =>
      'Terzaghi teorisi ile kohezyon, içsel sürtünme açısı ve temel boyutlarına göre nihai (qu) ve emniyetli (qsafe) taşıma gücü hesabı.';

  @override
  List<CalculationParam> get parameters => const [
        CalculationParam(
          key: 'cohesion',
          label: 'Kohezyon (c)',
          unit: 'kN/m²',
          defaultValue: 20.0,
          min: 0.0,
          max: 150.0,
          stepDecimals: 1,
          hint: 'Killi zeminlerde kohezyon etkisi (Kumlarda 0 alınır)',
        ),
        CalculationParam(
          key: 'friction_angle',
          label: 'İçsel Sürtünme Açısı (φ)',
          unit: 'derece',
          defaultValue: 26.0,
          min: 0.0,
          max: 42.0,
          stepDecimals: 0,
          hint: 'Kum ve çakıllarda tipik 25° - 38°',
        ),
        CalculationParam(
          key: 'unit_weight',
          label: 'Zemin Birim Hacim Ağırlığı (γ)',
          unit: 'kN/m³',
          defaultValue: 18.0,
          min: 14.0,
          max: 22.0,
          stepDecimals: 1,
          hint: 'Doğal birim ağırlık (Tipik: 17 - 19 kN/m³)',
        ),
        CalculationParam(
          key: 'width_b',
          label: 'Temel Genişliği (B)',
          unit: 'm',
          defaultValue: 2.0,
          min: 0.5,
          max: 8.0,
          stepDecimals: 2,
          hint: 'Sürekli veya tekil temel genişliği',
        ),
        CalculationParam(
          key: 'depth_d',
          label: 'Temel Gömülme Derinliği (D)',
          unit: 'm',
          defaultValue: 1.5,
          min: 0.5,
          max: 5.0,
          stepDecimals: 2,
          hint: 'Doğal zemin seviyesinden temel tabanına derinlik',
        ),
        CalculationParam(
          key: 'safety_factor',
          label: 'Güvenlik Katsayısı (FS)',
          unit: '',
          defaultValue: 3.0,
          min: 2.0,
          max: 4.0,
          stepDecimals: 1,
          hint: 'Mühendislik standardı FS = 3.0',
        ),
      ];

  @override
  CalculationExecutionResult calculate(Map<String, double> inputs) {
    final c = inputs['cohesion'] ?? 20.0;
    final phiDeg = inputs['friction_angle'] ?? 26.0;
    final gamma = inputs['unit_weight'] ?? 18.0;
    final b = inputs['width_b'] ?? 2.0;
    final d = inputs['depth_d'] ?? 1.5;
    final fs = inputs['safety_factor'] ?? 3.0;

    final phiRad = (phiDeg * math.pi) / 180.0;

    // Terzaghi katsayıları approx:
    // Nq = e^(pi * tan(phi)) * (tan(45 + phi/2))^2
    // Nc = (Nq - 1) / tan(phi) (phi > 0 için)
    // N_gamma = 2 * (Nq + 1) * tan(phi)
    double nq;
    double nc;
    double nGamma;

    if (phiDeg <= 0.1) {
      nq = 1.0;
      nc = 5.7;
      nGamma = 0.0;
    } else {
      final tanPhi = math.tan(phiRad);
      final tan45Plus = math.tan((math.pi / 4.0) + (phiRad / 2.0));
      nq = math.exp(math.pi * tanPhi) * (tan45Plus * tan45Plus);
      nc = (nq - 1.0) / tanPhi;
      nGamma = 2.0 * (nq + 1.0) * tanPhi;
    }

    // Şerit temel için Terzaghi nihai taşıma gücü:
    // qu = c * Nc + gamma * D * Nq + 0.5 * gamma * B * Ngamma
    final term1 = c * nc;
    final term2 = gamma * d * nq;
    final term3 = 0.5 * gamma * b * nGamma;
    final qu = term1 + term2 + term3; // kN/m2

    // Emniyetli taşıma gücü:
    final qSafe = qu / fs; // kN/m2
    final qSafeKgCm2 = qSafe / 98.07; // Yaklaşık kg/cm2 (100 kPa ≈ 1 kg/cm2)

    final roundedQu = double.parse(qu.toStringAsFixed(1));
    final roundedQsafe = double.parse(qSafe.toStringAsFixed(1));
    final roundedQsafeKg = double.parse(qSafeKgCm2.toStringAsFixed(2));

    final bool isSafe = roundedQsafe >= 120.0; // 1.2 kg/cm2 altı gevşek/zayıf zemin
    final warnings = <String>[];
    if (!isSafe) {
      warnings.add('⚠️ Düşük Taşıma Gücü: Emniyetli gerilme 120 kN/m² ($roundedQsafeKg kg/cm²) altında. Zemin iyileştirme veya radye temel gerekebilir.');
    }
    if (d < 1.0) {
      warnings.add('ℹ️ Don derinliği kuralı: Temel derinliği D < 1.0 m ise don tesirine dikkat edilmelidir.');
    }

    return CalculationExecutionResult(
      outputs: {
        'Nihai Taşıma Gücü (qu)': roundedQu,
        'Emniyetli Gerilme (qsafe)': roundedQsafe,
        'Emniyetli Gerilme': roundedQsafeKg,
      },
      outputUnits: {
        'Nihai Taşıma Gücü (qu)': 'kN/m²',
        'Emniyetli Gerilme (qsafe)': 'kN/m²',
        'Emniyetli Gerilme': 'kg/cm²',
      },
      summary:
          'Zemin Emniyetli Gerilmesi: $roundedQsafe kN/m² (~$roundedQsafeKg kg/cm²). Güvenlik katsayısı FS=$fs ile hesaplanmıştır.',
      isSafe: isSafe,
      warnings: warnings,
    );
  }
}

