/// Web Servisinden dönen tekil hesaplama sonucu modeli
class RemoteCalculationResult {
  final double output;
  final String formula;
  final String details;
  final bool isSafe;
  final Map<String, double> inputs;
  final DateTime timestamp;
  final int responseTimeMs;
  final bool isMock;

  const RemoteCalculationResult({
    required this.output,
    required this.formula,
    required this.details,
    required this.isSafe,
    required this.inputs,
    required this.timestamp,
    required this.responseTimeMs,
    this.isMock = false,
  });

  factory RemoteCalculationResult.fromJson(
    Map<String, dynamic> json, {
    required Map<String, double> originalInputs,
    required int responseTimeMs,
    bool isMock = false,
  }) {
    return RemoteCalculationResult(
      output: (json['output'] as num?)?.toDouble() ?? 0.0,
      formula: json['formula'] as String? ?? 'f(x1..x7)',
      details: json['details'] as String? ?? '',
      isSafe: json['isSafe'] as bool? ?? true,
      inputs: originalInputs,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp']) ?? DateTime.now()
          : DateTime.now(),
      responseTimeMs: responseTimeMs,
      isMock: isMock,
    );
  }
}

