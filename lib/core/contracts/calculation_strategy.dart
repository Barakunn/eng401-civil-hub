/// İnşaat parametresi tanımı (Generic, dynamic UI rendering için)
class CalculationParam {
  final String key;
  final String label;
  final String unit;
  final double defaultValue;
  final double min;
  final double max;
  final int stepDecimals;
  final String hint;

  const CalculationParam({
    required this.key,
    required this.label,
    required this.unit,
    required this.defaultValue,
    required this.min,
    required this.max,
    this.stepDecimals = 2,
    this.hint = '',
  });
}

/// Hesaplama stratejisi arayüzü (Strategy Pattern)
/// Yeni formüller eklenirken var olan kodlara dokunulmaz (Open/Closed Principle)
abstract class CalculationStrategy {
  String get id;
  String get title;
  String get category;
  String get description;
  
  /// Parametre listesi (Arayüz bu listeye göre dinamik ve optimize input üretir)
  List<CalculationParam> get parameters;

  /// Pure Dart matematiksel hesaplama
  CalculationExecutionResult calculate(Map<String, double> inputs);
}

class CalculationExecutionResult {
  final Map<String, double> outputs;
  final Map<String, String> outputUnits;
  final String summary;
  final bool isSafe;
  final List<String> warnings;

  const CalculationExecutionResult({
    required this.outputs,
    required this.outputUnits,
    required this.summary,
    required this.isSafe,
    this.warnings = const [],
  });
}

